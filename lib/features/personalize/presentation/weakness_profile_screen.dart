import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../app/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../data/models/practice_topic.dart';
import '../data/models/weakness.dart';
import '../data/personalize_repository.dart';
import 'personalize_styles.dart';
import 'personalize_widgets.dart';
import 'practice_topics_screen.dart';
import 'practice_session_screen.dart';

/// Design `1f`, screen 2 — the tracked error profile.
///
/// Real `myWeaknessProfile` — grouped by whatever criteria the school's
/// rubric actually configures (NOT a fixed grammar/pronunciation/expression
/// 3-way split, since real rubric criteria are a school-configurable list).
class WeaknessProfileScreen extends StatefulWidget {
  const WeaknessProfileScreen({super.key});

  @override
  State<WeaknessProfileScreen> createState() => _WeaknessProfileScreenState();
}

class _WeaknessProfileScreenState extends State<WeaknessProfileScreen> {
  final _repository = PersonalizeRepository();

  bool _loading = true;
  String? _error;
  WeaknessProfile? _profile;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await _repository.getWeaknessProfile();
      if (!mounted) return;
      setState(() => _profile = profile);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Opens the topic list pre-filtered to weakest-first — same session-start
  /// flow as everywhere else, no hardcoded demo topic.
  void _buildSession() async {
    final topic = await Navigator.of(context).push<PracticeTopic>(
      MaterialPageRoute(
        builder: (_) => const PracticeTopicsScreen(initialFilter: TopicFilter.byWeakness),
      ),
    );
    if (topic == null || !mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PracticeSessionScreen(topic: topic)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.pzWeaknessTitle)),
      body: switch ((_loading, _error, _profile)) {
        (true, _, _) => const Center(child: CircularProgressIndicator()),
        (_, final String error, _) =>
          PersonalizeErrorView(detail: error, onRetry: _load),
        (_, _, null) => PersonalizeErrorView(onRetry: _load),
        (_, _, final WeaknessProfile profile) => _buildBody(l10n, profile),
      },
    );
  }

  Widget _buildBody(AppLocalizations l10n, WeaknessProfile profile) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            children: [
              _SummaryCard(profile: profile),
              for (final criterion in profile.criteria) ...[
                const SizedBox(height: 20),
                SectionLabel(criterion.criterionName),
                const SizedBox(height: 10),
                _WeaknessRow(
                  title: criterion.criterionName,
                  severity: criterion.severity,
                  ratio: criterion.ratio,
                  detail: l10n.pzWeaknessObservations(criterion.observationCount),
                ),
                for (final sub in profile.subAttributesFor(criterion.criterionCode)) ...[
                  const SizedBox(height: 8),
                  _WeaknessRow(
                    title: sub.subAttribute,
                    severity: sub.severity,
                    ratio: sub.ratio,
                    detail: l10n.pzWeaknessOccurrences(sub.occurrenceCount),
                  ),
                ],
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: _buildSession,
              icon: const Icon(Icons.bolt, size: 19),
              label: Text(l10n.pzWeaknessBuildSession),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.indigo,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(99),
                ),
                textStyle: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The black counters card — all 3 numbers real (`sessionsAnalysed` counts
/// distinct graded evaluations in the observation window; `nearlyFixed`/
/// `newlyFound` come from comparing the real long-window vs recent-window
/// frequency the backend already tracks per sub-attribute).
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.profile});
  final WeaknessProfile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.pzWeaknessFromSessions(profile.sessionsAnalysed),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Counter(
                  value: profile.tracked,
                  label: l10n.pzWeaknessTracked,
                ),
              ),
              Expanded(
                child: _Counter(
                  value: profile.nearlyFixed,
                  label: l10n.pzWeaknessNearlyFixed,
                  color: const Color(0xFF34D399),
                ),
              ),
              Expanded(
                child: _Counter(
                  value: profile.newlyFound,
                  label: l10n.pzWeaknessNewlyFound,
                  color: const Color(0xFFFDBA74),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Counter extends StatelessWidget {
  const _Counter({
    required this.value,
    required this.label,
    this.color = Colors.white,
  });

  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$value',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            height: 1.3,
            color: Colors.white.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}

/// One weakness row — used for both criterion-level and sub-attribute-level
/// entries, since both share the same real shape (title/severity/ratio/detail).
class _WeaknessRow extends StatelessWidget {
  const _WeaknessRow({
    required this.title,
    required this.severity,
    required this.ratio,
    required this.detail,
  });

  final String title;
  final WeaknessSeverity severity;
  final double ratio;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = severityColors(severity);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: rowDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TagChip(
                severityLabel(l10n, severity),
                bg: colors.bg,
                fg: colors.fg,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            detail,
            style: const TextStyle(fontSize: 11.5, color: AppColors.textFaint),
          ),
          const SizedBox(height: 8),
          MeterBar(
            ratio: ratio,
            color: severityBarColor(severity),
            height: 6,
            track: AppColors.borderSoft,
          ),
        ],
      ),
    );
  }
}
