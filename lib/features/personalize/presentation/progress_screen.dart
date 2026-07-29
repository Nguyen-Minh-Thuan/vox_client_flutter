import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../app/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../data/models/progress_report.dart';
import '../data/personalize_repository.dart';
import 'personalize_styles.dart';
import 'personalize_widgets.dart';

/// Design `1f`, screen 4 — score trend and session history.
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final _repository = PersonalizeRepository();

  ProgressRange _range = ProgressRange.fourWeeks;
  bool _loading = true;
  String? _error;
  ProgressReport? _report;

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
      final report = await _repository.getProgress(_range);
      if (!mounted) return;
      setState(() => _report = report);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _selectRange(ProgressRange range) {
    if (_range == range) return;
    setState(() => _range = range);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final labels = <ProgressRange, String>{
      ProgressRange.fourWeeks: l10n.pzProgressRangeFourWeeks,
      ProgressRange.threeMonths: l10n.pzProgressRangeThreeMonths,
      ProgressRange.all: l10n.pzProgressRangeAll,
    };

    return Scaffold(
      appBar: AppBar(title: Text(l10n.pzProgressTitle)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final entry in labels.entries) ...[
                    SelectablePill(
                      label: entry.value,
                      active: entry.key == _range,
                      onTap: () => _selectRange(entry.key),
                    ),
                    const SizedBox(width: 7),
                  ],
                ],
              ),
            ),
          ),
          Expanded(
            child: switch ((_loading, _error, _report)) {
              (true, _, _) => const Center(child: CircularProgressIndicator()),
              (_, final String error, _) =>
                PersonalizeErrorView(detail: error, onRetry: _load),
              (_, _, null) => PersonalizeErrorView(onRetry: _load),
              (_, _, final ProgressReport report) => ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  children: [
                    _AverageCard(report: report),
                    const SizedBox(height: 20),
                    SectionLabel(l10n.pzProgressRecentSessions),
                    const SizedBox(height: 10),
                    for (final session in report.recentSessions) ...[
                      _HistoryRow(session: session),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
            },
          ),
        ],
      ),
    );
  }
}

/// Average-score headline plus the bar chart.
class _AverageCard extends StatelessWidget {
  const _AverageCard({required this.report});
  final ProgressReport report;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final peak = report.peak;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: rowDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(child: SectionLabel(l10n.pzProgressAverage)),
              Text(
                report.averageScore.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formatDelta(report.delta),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: report.delta >= 0
                      ? AppColors.chipGreenFg
                      : AppColors.danger,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (int i = 0; i < report.points.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: _Bar(
                      point: report.points[i],
                      peak: peak,
                      highlighted: i == report.points.length - 1,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.point,
    required this.peak,
    required this.highlighted,
  });

  final ProgressPoint point;
  final double peak;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    // Reserve room for the label row so the tallest bar still fits.
    const labelHeight = 20.0;
    final ratio = (point.value / peak).clamp(0.08, 1.0);

    return LayoutBuilder(
      builder: (_, constraints) {
        final available = constraints.maxHeight - labelHeight;
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              height: available * ratio,
              decoration: BoxDecoration(
                color: highlighted
                    ? AppColors.indigo
                    : Color.lerp(
                        AppColors.chipBlueBg,
                        const Color(0xFFA5B4FC),
                        ratio,
                      ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              point.label,
              maxLines: 1,
              overflow: TextOverflow.clip,
              style: TextStyle(
                fontSize: 10,
                fontWeight: highlighted ? FontWeight.w800 : FontWeight.w700,
                color: highlighted ? AppColors.indigo : AppColors.textGhost,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.session});
  final SessionHistoryItem session;

  @override
  Widget build(BuildContext context) {
    final positive = session.score >= 7.5;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: rowDecoration,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.fieldBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(iconForName(session.icon),
                size: 20, color: const Color(0xFF555555)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  session.subtitle,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textGhost,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color:
                  positive ? AppColors.chipGreenBg : AppColors.chipOrangeBg,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              session.score.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color:
                    positive ? AppColors.chipGreenFg : AppColors.chipOrangeFg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
