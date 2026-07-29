import 'dart:async';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../app/theme.dart';
import '../../../app/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../data/models/practice_session.dart';
import '../data/models/practice_topic.dart';
import '../data/personalize_repository.dart';
import 'correction_card.dart';
import 'personalize_styles.dart';
import 'session_summary_screen.dart';

/// What the mic control is doing right now.
enum _RecorderState { idle, recording, processing }

/// Design `1c` — the live 1-1 speaking session with inline corrections.
///
/// The microphone is real: the learner's answer is captured to a temp file and
/// the amplitude drives the waveform. The *conversation* is still scripted —
/// stopping a recording reveals the next scripted turn instead of uploading.
class PracticeSessionScreen extends StatefulWidget {
  const PracticeSessionScreen({super.key, required this.topic});

  final PracticeTopic topic;

  @override
  State<PracticeSessionScreen> createState() => _PracticeSessionScreenState();
}

class _PracticeSessionScreenState extends State<PracticeSessionScreen>
    with TickerProviderStateMixin {
  final _repository = PersonalizeRepository();
  final _recorder = AudioRecorder();
  final _scrollController = ScrollController();

  // Both only run while the mic is live — an idle session should not keep a
  // 60 fps ticker alive.
  late final AnimationController _wave =
      AnimationController(vsync: this, duration: const Duration(seconds: 2));
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  StreamSubscription<Amplitude>? _amplitudeSub;
  Timer? _clock;

  bool _loading = true;
  String? _error;
  PracticeSession? _session;

  /// Turns revealed so far. Grows as the learner records.
  final List<PracticeTurn> _visible = [];

  /// Index into `_session.turns` of the next turn to reveal.
  int _cursor = 0;

  _RecorderState _recorderState = _RecorderState.idle;

  /// Normalised 0..1 mic level driving the waveform.
  double _level = 0.35;

  /// Seconds since the session opened.
  int _elapsed = 0;

  /// Path of the most recent recording, handed to the summary screen.
  String? _lastRecordingPath;

  bool get _isComplete =>
      _session != null && _cursor >= _session!.turns.length;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _amplitudeSub?.cancel();
    _clock?.cancel();
    _wave.dispose();
    _pulse.dispose();
    _scrollController.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final session = await _repository.startSession(widget.topic);
      if (!mounted) return;
      setState(() {
        _session = session;
        _visible
          ..clear()
          ..addAll(_leadingAiTurns(session));
        _cursor = _visible.length;
      });
      _startClock();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// The AI turns that open the conversation, shown before the first recording.
  List<PracticeTurn> _leadingAiTurns(PracticeSession session) {
    final leading = <PracticeTurn>[];
    for (final turn in session.turns) {
      if (turn.speaker != Speaker.ai) break;
      leading.add(turn);
    }
    return leading;
  }

  void _startClock() {
    _clock?.cancel();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsed++);
    });
  }

  // ── Recording ─────────────────────────────────────────────────────────────

  Future<void> _toggleRecording() async {
    switch (_recorderState) {
      case _RecorderState.recording:
        await _stopRecording();
      case _RecorderState.idle:
        await _startRecording();
      case _RecorderState.processing:
        break;
    }
  }

  Future<void> _startRecording() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      if (!await _recorder.hasPermission()) {
        if (mounted) _toast(l10n.pzSessionMicDenied);
        return;
      }
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/vox_practice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );

      _amplitudeSub?.cancel();
      _amplitudeSub = _recorder
          .onAmplitudeChanged(const Duration(milliseconds: 120))
          .listen((amplitude) {
        if (!mounted) return;
        setState(() => _level = _normalise(amplitude.current));
      });

      if (!mounted) return;
      _wave.repeat();
      _pulse.repeat(reverse: true);
      setState(() {
        _recorderState = _RecorderState.recording;
        _lastRecordingPath = path;
      });
    } catch (e) {
      if (!mounted) return;
      _toast('${l10n.pzSessionRecordError}\n$e');
      setState(() => _recorderState = _RecorderState.idle);
    }
  }

  Future<void> _stopRecording() async {
    _wave.stop();
    _pulse
      ..stop()
      ..value = 0;
    setState(() => _recorderState = _RecorderState.processing);
    await _amplitudeSub?.cancel();
    _amplitudeSub = null;
    try {
      final path = await _recorder.stop();
      if (path != null) _lastRecordingPath = path;
    } catch (_) {
      // A failed stop should not block the scripted flow.
    }
    if (!mounted) return;
    setState(() => _level = 0.35);
    await _revealNextTurns();
  }

  /// dBFS (roughly -45..0) → 0..1.
  double _normalise(double dbfs) {
    const floor = 45.0;
    return ((dbfs + floor) / floor).clamp(0.05, 1.0);
  }

  /// Reveals the learner's scripted turn, then the AI's follow-up.
  Future<void> _revealNextTurns() async {
    final session = _session;
    if (session == null || _cursor >= session.turns.length) {
      if (mounted) setState(() => _recorderState = _RecorderState.idle);
      return;
    }

    // Grading pause so the "listening" state is visible.
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() {
      _visible.add(session.turns[_cursor]);
      _cursor++;
      _recorderState = _RecorderState.idle;
    });
    _scrollToEnd();

    // Follow-up prompt from the AI, if the script has one.
    if (_cursor < session.turns.length &&
        session.turns[_cursor].speaker == Speaker.ai) {
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      setState(() {
        _visible.add(session.turns[_cursor]);
        _cursor++;
      });
      _scrollToEnd();
    }
  }

  /// Drops the last learner turn so it can be recorded again.
  void _sayAgain() {
    final index = _visible.lastIndexWhere((t) => t.speaker == Speaker.student);
    if (index == -1) return;
    setState(() {
      // Remove the learner turn and everything the AI said after it, then
      // rewind the cursor by the same amount.
      final removed = _visible.length - index;
      _visible.removeRange(index, _visible.length);
      _cursor -= removed;
    });
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOut,
      );
    });
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  Future<void> _finish() async {
    final session = _session;
    if (session == null) return;
    _clock?.cancel();
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => SessionSummaryScreen(
          sessionId: session.id,
          recordingPath: _lastRecordingPath,
        ),
      ),
    );
  }

  Future<bool> _confirmExit() async {
    if (_visible.every((t) => t.speaker == Speaker.ai)) return true;
    final l10n = AppLocalizations.of(context)!;
    final leave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.pzSessionExitTitle),
        content: Text(l10n.pzSessionExitBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.pzSessionExitStay),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.pzSessionExitLeave),
          ),
        ],
      ),
    );
    return leave ?? false;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await _confirmExit();
        if (!context.mounted || !leave) return;
        Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFCFCFD),
        body: SafeArea(
          child: Column(
            children: [
              _SessionHeader(
                title: widget.topic.title,
                elapsed: _elapsed,
                focusTags: _session?.focusTags ?? widget.topic.focusTags,
                onClose: () async {
                  final leave = await _confirmExit();
                  if (!context.mounted || !leave) return;
                  Navigator.of(context).pop();
                },
              ),
              Expanded(child: _buildBody(l10n)),
              if (!_loading && _error == null) _buildComposer(l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${l10n.pzLoadError}\n$_error',
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 13, color: AppColors.textFaint),
              ),
              const SizedBox(height: 12),
              TextButton(onPressed: _load, child: Text(l10n.pzRetry)),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      itemCount: _visible.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, index) {
        final turn = _visible[index];
        if (turn.speaker == Speaker.ai) return _AiBubble(text: turn.text);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StudentBubble(turn: turn),
            if (turn.corrections.isNotEmpty) ...[
              const SizedBox(height: 12),
              CorrectionCard(
                turn: turn,
                onHearCorrect: () => _toast(l10n.pzSessionNoSampleAudio),
                onSayAgain: _sayAgain,
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildComposer(AppLocalizations l10n) {
    if (_isComplete) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
        child: GradientButton(
          label: l10n.pzSessionFinish,
          icon: Icons.arrow_forward,
          onTap: _finish,
        ),
      );
    }

    final recording = _recorderState == _RecorderState.recording;
    final processing = _recorderState == _RecorderState.processing;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.fieldBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.more_horiz,
                size: 21, color: Color(0xFF555555)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F8),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (recording)
                    SizedBox(
                      height: 24,
                      child: AnimatedBuilder(
                        animation: _wave,
                        builder: (_, _) => CustomPaint(
                          size: const Size(double.infinity, 24),
                          painter: WaveformPainter(
                            _wave.value,
                            level: _level,
                            bars: 16,
                            colors: const [AppColors.danger, Color(0xFFFCA5A5)],
                          ),
                        ),
                      ),
                    )
                  else if (processing)
                    const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  const SizedBox(height: 5),
                  Text(
                    recording
                        ? l10n.pzSessionRecording
                        : processing
                            ? l10n.pzSessionThinking
                            : l10n.pzSessionTapToSpeak,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                      color: recording ? AppColors.danger : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),
          _MicButton(
            pulse: _pulse,
            recording: recording,
            enabled: !processing,
            onTap: _toggleRecording,
          ),
        ],
      ),
    );
  }
}

class _SessionHeader extends StatelessWidget {
  const _SessionHeader({
    required this.title,
    required this.elapsed,
    required this.focusTags,
    required this.onClose,
  });

  final String title;
  final int elapsed;
  final List<String> focusTags;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.indigo, AppColors.secondary],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome, size: 19, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  l10n.pzSessionLive(formatClock(elapsed)),
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
          if (focusTags.isNotEmpty) ...[
            const SizedBox(width: 8),
            Flexible(child: TagChip.orange(focusTags.first)),
          ],
          const SizedBox(width: 4),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close, size: 22, color: Color(0xFF999999)),
          ),
        ],
      ),
    );
  }
}

class _AiBubble extends StatelessWidget {
  const _AiBubble({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.indigo, AppColors.secondary],
            ),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.graphic_eq, size: 14, color: Colors.white),
        ),
        const SizedBox(width: 9),
        Flexible(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.7,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.borderSoft,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.5,
                color: AppColors.ink,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StudentBubble extends StatelessWidget {
  const _StudentBubble({required this.turn});
  final PracticeTurn turn;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: const BoxDecoration(
          color: AppColors.chipBlueBg,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(4),
          ),
        ),
        child: TranscriptText(
          text: turn.text,
          spans: turn.spans,
          baseStyle: const TextStyle(
            fontSize: 13.5,
            height: 1.55,
            color: Color(0xFF312E81),
          ),
        ),
      ),
    );
  }
}

class _MicButton extends StatelessWidget {
  const _MicButton({
    required this.pulse,
    required this.recording,
    required this.enabled,
    required this.onTap,
  });

  final Animation<double> pulse;
  final bool recording;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedBuilder(
        animation: pulse,
        builder: (_, child) {
          final t = recording ? pulse.value : 0.0;
          return Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: enabled ? AppColors.danger : AppColors.textGhost,
              boxShadow: [
                BoxShadow(
                  color: AppColors.danger.withValues(alpha: 0.35 * (1 - t)),
                  blurRadius: 8,
                  spreadRadius: 12 * t,
                ),
              ],
            ),
            child: child,
          );
        },
        child: Icon(
          recording ? Icons.stop : Icons.mic,
          size: 26,
          color: Colors.white,
        ),
      ),
    );
  }
}
