import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../../app/theme.dart';
import '../../../app/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../data/models/session_summary.dart';
import '../data/personalize_repository.dart';
import 'personalize_styles.dart';
import 'personalize_widgets.dart';

/// Design `1f`, screen 1 — the post-session report.
class SessionSummaryScreen extends StatefulWidget {
  const SessionSummaryScreen({
    super.key,
    required this.sessionId,
    this.recordingPath,
  });

  final String sessionId;

  /// Local file captured during the session, replayed by "Nghe lại ghi âm".
  final String? recordingPath;

  @override
  State<SessionSummaryScreen> createState() => _SessionSummaryScreenState();
}

class _SessionSummaryScreenState extends State<SessionSummaryScreen> {
  final _repository = PersonalizeRepository();
  final _player = AudioPlayer();

  bool _loading = true;
  String? _error;
  SessionSummary? _summary;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final summary = await _repository.getSessionSummary(widget.sessionId);
      if (!mounted) return;
      setState(() => _summary = summary);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _togglePlayback() async {
    final l10n = AppLocalizations.of(context)!;
    final path = widget.recordingPath;
    if (path == null || !File(path).existsSync()) {
      _toast(l10n.pzSessionPlaybackUnavailable);
      return;
    }
    try {
      if (_player.playing) {
        await _player.pause();
        return;
      }
      if (_player.audioSource == null) await _player.setFilePath(path);
      // Restart when the previous playback ran to the end.
      if (_player.processingState == ProcessingState.completed) {
        await _player.seek(Duration.zero);
      }
      await _player.play();
    } catch (e) {
      if (!mounted) return;
      _toast('${l10n.pzSessionPlaybackUnavailable}\n$e');
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        title: Text(l10n.pzSummaryTitle),
      ),
      body: switch ((_loading, _error, _summary)) {
        (true, _, _) => const Center(child: CircularProgressIndicator()),
        (_, final String error, _) =>
          PersonalizeErrorView(detail: error, onRetry: _load),
        (_, _, null) => PersonalizeErrorView(onRetry: _load),
        (_, _, final SessionSummary summary) => _buildBody(l10n, summary),
      },
    );
  }

  Widget _buildBody(AppLocalizations l10n, SessionSummary summary) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        _ScoreHero(summary: summary),
        const SizedBox(height: 12),
        _SessionRubricCard(rubric: summary.rubric),
        const SizedBox(height: 12),
        _RepeatedErrorsCard(errors: summary.repeatedErrors),
        const SizedBox(height: 20),
        GradientButton(
          label: l10n.pzSummaryDrill(
            summary.repeatedErrors.length,
            summary.drillMinutes,
          ),
          icon: Icons.bolt,
          height: 52,
          // Restarting the drill needs the generated micro-session the backend
          // will provide; until then the button returns to the practice home.
          onTap: () => Navigator.of(context).pop(),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 48,
          child: StreamBuilder<bool>(
            stream: _player.playingStream,
            initialData: false,
            builder: (_, snapshot) {
              final playing = snapshot.data ?? false;
              return OutlinedButton.icon(
                onPressed: _togglePlayback,
                icon: Icon(playing ? Icons.pause : Icons.mic, size: 18),
                label: Text(l10n.pzSummaryReplay),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.indigo,
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(99),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ScoreHero extends StatelessWidget {
  const _ScoreHero({required this.summary});
  final SessionSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GradientHeroCard(
      child: Column(
        children: [
          Text(
            l10n
                .pzSummaryHeader(summary.topicTitle, summary.minutes)
                .toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 14),
          // The score is deliberately huge — scale it down rather than clip it
          // on narrow screens or at large system text sizes.
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  summary.score.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 58,
                    fontWeight: FontWeight.w800,
                    height: 1,
                    color: Colors.white,
                  ),
                ),
                Text(
                  ' / 10',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (summary.delta != null) Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  summary.delta! >= 0 ? Icons.trending_up : Icons.trending_down,
                  size: 16,
                  color: summary.delta! >= 0
                      ? AppColors.chipGreenFg
                      : AppColors.danger,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    l10n.pzSummaryDelta(formatDelta(summary.delta!)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: summary.delta! >= 0
                          ? AppColors.chipGreenFg
                          : AppColors.danger,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RepeatedErrorsCard extends StatelessWidget {
  const _RepeatedErrorsCard({required this.errors});
  final List<RepeatedError> errors;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionLabel(l10n.pzSummaryRepeatedErrors),
          const SizedBox(height: 12),
          if (errors.isEmpty)
            const Text(
              'Không ghi nhận lỗi lặp lại trong phiên này.',
              style: TextStyle(fontSize: 13, color: AppColors.muted),
            ),
          for (int i = 0; i < errors.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _ErrorRow(error: errors[i]),
          ],
        ],
      ),
    );
  }
}

class _ErrorRow extends StatelessWidget {
  const _ErrorRow({required this.error});
  final RepeatedError error;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.chipOrangeBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '×${error.count}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.chipOrangeFg,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            error.label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.dark,
            ),
          ),
        ),
      ],
    );
  }
}

class _SessionRubricCard extends StatelessWidget {
  const _SessionRubricCard({required this.rubric});

  final List<SessionRubricCriterion> rubric;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 12, 0, 6),
            child: SectionLabel(l10n.pzSummaryRubric),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          if (rubric.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text('Chưa có điểm chi tiết theo tiêu chí.', style: TextStyle(fontSize: 13, color: AppColors.muted)),
            ),
          for (int i = 0; i < rubric.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: Color(0xFFF1F5F9)),
            Padding(
              padding: EdgeInsets.fromLTRB(0, 9, 0, i == rubric.length - 1 ? 12 : 9),
              child: MeterRow(
                label: rubric[i].label,
                ratio: (rubric[i].score / 10).clamp(0, 1),
                value: rubric[i].score.toStringAsFixed(1),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

