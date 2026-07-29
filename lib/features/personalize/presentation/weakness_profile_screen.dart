import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../app/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../data/models/weakness.dart';
import '../data/personalize_demo_data.dart';
import '../data/personalize_repository.dart';
import 'personalize_styles.dart';
import 'personalize_widgets.dart';
import 'practice_session_screen.dart';

/// Design `1f`, screen 2 — the tracked error profile.
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

  /// Builds a drill session around the learner's worst weak spots.
  void _buildSession() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PracticeSessionScreen(
          topic: PersonalizeDemoData.topFootballTopic,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.pzWeaknessTitle),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: TagChip(l10n.pzWeaknessRange),
            ),
          ),
        ],
      ),
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
    final sections = <(String, WeaknessCategory)>[
      (l10n.pzWeaknessGrammar, WeaknessCategory.grammar),
      (l10n.pzWeaknessPronunciation, WeaknessCategory.pronunciation),
      (l10n.pzWeaknessExpression, WeaknessCategory.expression),
    ];

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            children: [
              _SummaryCard(profile: profile),
              for (final (label, category) in sections) ...[
                if (profile.byCategory(category).isNotEmpty) ...[
                  const SizedBox(height: 20),
                  SectionLabel(label),
                  const SizedBox(height: 10),
                  for (final weakness in profile.byCategory(category)) ...[
                    _WeaknessCard(weakness: weakness),
                    const SizedBox(height: 8),
                  ],
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

/// The black counters card.
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

class _WeaknessCard extends StatelessWidget {
  const _WeaknessCard({required this.weakness});
  final Weakness weakness;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = severityColors(weakness.severity);

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
                  weakness.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TagChip(
                severityLabel(l10n, weakness.severity),
                bg: colors.bg,
                fg: colors.fg,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            weakness.detail,
            style: const TextStyle(fontSize: 11.5, color: AppColors.textFaint),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: MeterBar(
                  ratio: weakness.ratio,
                  color: severityBarColor(weakness.severity),
                  height: 6,
                  track: AppColors.borderSoft,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 44,
                child: Text(
                  weakness.deltaLabel.isEmpty ? '—' : weakness.deltaLabel,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: weakness.deltaLabel.isEmpty
                        ? AppColors.textFaint
                        : (weakness.deltaIsPositive
                            ? AppColors.chipGreenFg
                            : AppColors.danger),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
