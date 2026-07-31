import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:record/record.dart';

import '../../../app/theme.dart';
import '../../../app/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../data/models/practice_session.dart';
import '../data/models/practice_topic.dart';
import '../data/personalize_repository.dart';
import '../data/practice_realtime_client.dart';
import 'correction_card.dart';
import 'personalize_styles.dart';
import 'session_summary_screen.dart';

/// What the mic control is doing right now.
enum _RecorderState { idle, recording, processing }

/// Silence-timeout tuning mirrors WPF's SpeechTurnCoordinator.CaptureAsync
/// (DesktopApp/VoxOralExam/.../Services/ExamFlow/Turn/SpeechTurnCoordinator.cs) --
/// initial timeout before any speech at all (chốt 8s, mục 2.8), then a grace period after
/// vad_speech_end that tolerates a natural mid-answer pause before really ending the turn.
const _kInitialSilenceTimeout = Duration(seconds: 8);
const _kSpeechEndGracePeriod = Duration(seconds: 3);

/// Design `1c` — the live 1-1 speaking session with inline corrections.
///
/// Real realtime backend (gói 11): continuous PCM16 mic streaming over
/// `PracticeRealtimeClient`, server-driven turn/question flow. Click-to-continue —
/// the mic button only mutes/unmutes; advancing to the next prompt (follow-up or a new
/// MAIN question alike) always waits for the student to tap "Tiếp tục" on the correction
/// card. UI/widgets below are unchanged from the original mock on purpose; only the
/// state/data layer is real now.
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
  final _realtimeClient = PracticeRealtimeClient();
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
  StreamSubscription<Uint8List>? _audioStreamSub;
  StreamSubscription<Map<String, dynamic>>? _eventsSub;
  Timer? _clock;
  Timer? _turnTimer;

  bool _loading = true;
  String? _error;
  PracticeSession? _session;

  /// Turns revealed so far — grows as real WS events arrive, no scripted list anymore.
  final List<PracticeTurn> _visible = [];
  int _nextTurnOrder = 1;

  _RecorderState _recorderState = _RecorderState.idle;

  /// Mic mute toggle — independent of `_recorderState` (continuous-listen model, see
  /// module docstring): muted just streams silence instead of stopping the connection,
  /// mirrors WPF's ToggleMuteCommand/TurnAudioRecorder.IsMuted.
  bool _muted = false;

  /// True once speech has been detected for the CURRENT turn (silence-timeout bookkeeping).
  bool _speakingNow = false;
  bool _hasSpokenThisTurn = false;

  /// Buffered from final_transcript events for the turn currently being answered.
  final StringBuffer _liveTranscript = StringBuffer();

  /// Buffered next prompt, ready for when "Tiếp tục" is tapped -- either the follow-up
  /// prompt (from `decision.next_prompt_text`, arrives fast) or a brand-new MAIN question's
  /// text (from `next_question`, arrives async once Java/LLM resolves it). Null means
  /// "not ready yet" -- CorrectionCard's continue action shows a loading state then.
  String? _pendingPromptText;

  bool _sessionEnded = false;
  bool _endingSession = false;

  /// Normalised 0..1 mic level driving the waveform.
  double _level = 0.35;

  /// Seconds since the session opened.
  int _elapsed = 0;

  bool get _isComplete => _sessionEnded;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _amplitudeSub?.cancel();
    _audioStreamSub?.cancel();
    _eventsSub?.cancel();
    _clock?.cancel();
    _turnTimer?.cancel();
    _wave.dispose();
    _pulse.dispose();
    _scrollController.dispose();
    _recorder.dispose();
    _realtimeClient.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final started = await _repository.startSession(widget.topic);
      if (!mounted) return;
      setState(() {
        _session = started.session;
        _visible.clear();
        _nextTurnOrder = 1;
      });
      _eventsSub = _realtimeClient.events.listen(_handleRealtimeEvent);
      await _realtimeClient.connect(started.session.id);
      _realtimeClient.send({
        'type': 'question_start',
        'question_id': started.firstQuestion['questionId'],
        'paper_item_id': started.firstQuestion['slot']?.toString(),
        'question': {
          'question_text': started.firstQuestion['questionText'],
          'max_response_seconds': started.firstQuestion['maxResponseSeconds'],
        },
        'language': 'en-US',
      });
      // First prompt of the session has nothing to "continue" from -- present it right
      // away instead of waiting for a tap (mirrors the mock's _leadingAiTurns behaviour).
      _realtimeClient.send({
        'type': 'present_question',
        'prompt_text': started.firstQuestion['questionText'],
      });
      await _startAudioStream();
      _startClock();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _startAudioStream() async {
    final l10n = AppLocalizations.of(context)!;
    if (!await _recorder.hasPermission()) {
      if (mounted) _toast(l10n.pzSessionMicDenied);
      return;
    }
    final stream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      ),
    );
    _audioStreamSub = stream.listen(_handleAudioChunk);

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
    setState(() => _recorderState = _RecorderState.recording);
    _armInitialSilenceTimer();
  }

  void _handleAudioChunk(Uint8List chunk) {
    _realtimeClient.sendAudioFrame(_muted ? Uint8List(chunk.length) : chunk);
  }

  void _startClock() {
    _clock?.cancel();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsed++);
    });
  }

  // ── Realtime protocol ────────────────────────────────────────────────────

  void _handleRealtimeEvent(Map<String, dynamic> event) {
    switch (event['type']) {
      case 'speak':
        _appendAiTurn((event['text'] as String?) ?? '');
      case 'vad_speech_start':
        _handleSpeechStart();
      case 'vad_speech_end':
        _handleSpeechEnd();
      case 'final_transcript':
        final text = event['text'] as String?;
        if (text != null && text.trim().isNotEmpty) {
          if (_liveTranscript.isNotEmpty) _liveTranscript.write(' ');
          _liveTranscript.write(text.trim());
        }
      case 'decision':
        _handleDecision(event['decision'] as Map<String, dynamic>? ?? const {});
      case 'correction':
        _handleCorrection(event);
      case 'next_question':
        setState(() {
          _pendingPromptText =
              (event['question'] as Map<String, dynamic>?)?['questionText'] as String?;
        });
      case 'practice_session_ended':
        _handleSessionEndedByServer();
      case 'error':
      case 'connection_closed':
        // Surfaced via _toast rather than _error so a mid-session drop doesn't blow away
        // the conversation already rendered.
        if (mounted) {
          _toast('${event['text'] ?? event['type']}');
        }
    }
  }

  void _appendAiTurn(String text) {
    if (text.trim().isEmpty) return;
    if (!mounted) return;
    setState(() {
      _visible.add(PracticeTurn(
        id: 'ai-${_visible.length}',
        turnOrder: _nextTurnOrder,
        speaker: Speaker.ai,
        text: text,
      ));
    });
    _scrollToEnd();
  }

  void _handleSpeechStart() {
    _turnTimer?.cancel();
    _speakingNow = true;
    _hasSpokenThisTurn = true;
  }

  void _handleSpeechEnd() {
    _speakingNow = false;
    _armGracePeriodTimer();
  }

  void _armInitialSilenceTimer() {
    _turnTimer?.cancel();
    _turnTimer = Timer(_kInitialSilenceTimeout, () {
      if (!_hasSpokenThisTurn) _sendTurnEnd();
    });
  }

  void _armGracePeriodTimer() {
    _turnTimer?.cancel();
    _turnTimer = Timer(_kSpeechEndGracePeriod, () {
      if (!_speakingNow) _sendTurnEnd();
    });
  }

  void _sendTurnEnd() {
    if (_recorderState != _RecorderState.recording) return;
    _turnTimer?.cancel();
    final transcript = _liveTranscript.toString();
    _liveTranscript.clear();

    if (!mounted) return;
    setState(() {
      _recorderState = _RecorderState.processing;
      _visible.add(PracticeTurn(
        id: 'student-$_nextTurnOrder',
        turnOrder: _nextTurnOrder,
        speaker: Speaker.student,
        text: transcript,
      ));
      _nextTurnOrder++;
    });
    _scrollToEnd();
    _realtimeClient.send({'type': 'turn_end'});
  }

  void _handleDecision(Map<String, dynamic> decision) {
    if (decision['should_continue'] == true) {
      _pendingPromptText = decision['next_prompt_text'] as String?;
    } else {
      _pendingPromptText = null;
    }
  }

  void _handleCorrection(Map<String, dynamic> event) {
    if (!mounted) return;
    final rawCorrections = (event['corrections'] as List?) ?? const [];
    final corrections = rawCorrections
        .cast<Map<String, dynamic>>()
        .map(_correctionFromJson)
        .toList();
    setState(() {
      final index =
          _visible.lastIndexWhere((t) => t.speaker == Speaker.student);
      if (index != -1) {
        final turn = _visible[index];
        _visible[index] = PracticeTurn(
          id: turn.id,
          turnOrder: turn.turnOrder,
          speaker: turn.speaker,
          text: turn.text,
          score: turn.score,
          spans: turn.spans,
          corrections: corrections,
        );
      }
      _recorderState = _RecorderState.idle;
    });
    _scrollToEnd();
  }

  Correction _correctionFromJson(Map<String, dynamic> json) {
    return Correction(
      type: _correctionTypeFromCategory(json['category'] as String?),
      before: json['original_text'] as String?,
      after: json['corrected_text'] as String?,
      note: (json['explanation'] as String?) ?? '',
    );
  }

  CorrectionType _correctionTypeFromCategory(String? category) {
    switch (category) {
      case 'vocabulary':
        return CorrectionType.vocabulary;
      case 'pronunciation':
        return CorrectionType.pronunciation;
      case 'fluency':
        return CorrectionType.fluency;
      default:
        return CorrectionType.grammar;
    }
  }

  /// Footer action of the (relabelled) CorrectionCard — the ONE new user action in this
  /// screen (mục 2.7b): advance to whatever's next (follow-up or a new MAIN question
  /// alike, same handling either way), only once it's actually buffered.
  Future<void> _handleContinue() async {
    final promptText = _pendingPromptText;
    if (promptText == null) {
      // Still resolving (bậc 4 / LLM taking a moment) -- CorrectionCard shows a loading
      // state for this tap instead of doing nothing silently, see correction_card.dart.
      return;
    }
    _pendingPromptText = null;
    _realtimeClient.send({'type': 'present_question', 'prompt_text': promptText});
    _hasSpokenThisTurn = false;
    _speakingNow = false;
    if (!mounted) return;
    setState(() => _recorderState = _RecorderState.recording);
    _armInitialSilenceTimer();
  }

  bool get _continueReady => _pendingPromptText != null;

  void _handleSessionEndedByServer() {
    _turnTimer?.cancel();
    _audioStreamSub?.cancel();
    _recorder.stop();
    if (!mounted) return;
    setState(() {
      _sessionEnded = true;
      _recorderState = _RecorderState.idle;
    });
  }

  // ── Mic mute toggle (NOT start/stop recording anymore) ──────────────────

  void _toggleMute() {
    if (_recorderState == _RecorderState.processing) return;
    setState(() => _muted = !_muted);
  }

  /// dBFS (roughly -45..0) → 0..1.
  double _normalise(double dbfs) {
    const floor = 45.0;
    return ((dbfs + floor) / floor).clamp(0.05, 1.0);
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
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ── Navigation / ending the session ──────────────────────────────────────

  Future<void> _finish() async {
    final session = _session;
    if (session == null) return;
    _clock?.cancel();
    await _endSession(clientInitiated: false);
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => SessionSummaryScreen(
          sessionId: session.id,
          recordingPath: null,
        ),
      ),
    );
  }

  /// Mirrors ExamAttemptRunner.RequestSubmit()'s exact ordering (mục 2.9 điểm 2): WS
  /// practice_end -> await practice_end_ack -> close WS -> THEN endPracticeSession mutation.
  /// clientInitiated=false skips the WS handshake (server already ended the session itself,
  /// e.g. budget_exhausted) and just tidies up + calls the mutation.
  Future<void> _endSession({required bool clientInitiated}) async {
    if (_endingSession || _sessionEnded) return;
    _endingSession = true;
    _turnTimer?.cancel();
    await _audioStreamSub?.cancel();
    try {
      await _recorder.stop();
    } catch (_) {
      // Best-effort -- the session is ending either way.
    }

    if (clientInitiated && _realtimeClient.isConnected) {
      final ack = _realtimeClient.events
          .firstWhere((e) => e['type'] == 'practice_end_ack')
          .timeout(const Duration(seconds: 5), onTimeout: () => const {});
      _realtimeClient.send({'type': 'practice_end'});
      await ack;
    }
    await _realtimeClient.close();

    final session = _session;
    if (session != null) {
      try {
        await _repository.endPracticeSession(
          sessionId: session.id,
          helpRequestCount: 0,
          longPauseCount: 0,
        );
      } catch (_) {
        // Ending the local session view must not get stuck on a network hiccup here --
        // the server independently expires stale IN_PROGRESS sessions.
      }
    }
    _sessionEnded = true;
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

  Future<void> _handleExitRequest() async {
    final leave = await _confirmExit();
    if (!mounted || !leave) return;
    await _endSession(clientInitiated: true);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _handleExitRequest();
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
                onClose: _handleExitRequest,
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
        // Real backend always sends a `correction` message after a student turn (even
        // with an empty corrections list) -- show the card (with its now-"Tiếp tục"
        // footer) once that's arrived, not gated on corrections being non-empty like the
        // old scripted mock, or there'd be no way to advance on a clean turn.
        final isLatestStudentTurn =
            index == _visible.lastIndexWhere((t) => t.speaker == Speaker.student);
        final showContinue = isLatestStudentTurn &&
            _recorderState == _RecorderState.idle &&
            !_sessionEnded;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StudentBubble(turn: turn),
            if (showContinue) ...[
              const SizedBox(height: 12),
              CorrectionCard(
                turn: turn,
                onHearCorrect: () => _toast(l10n.pzSessionNoSampleAudio),
                onContinue: _handleContinue,
                continueReady: _continueReady,
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

    final recording = _recorderState == _RecorderState.recording && !_muted;
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
            onTap: _toggleMute,
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
