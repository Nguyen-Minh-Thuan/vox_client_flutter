import 'practice_history_entry.dart';

/// Time window behind the pills on the progress screen.
enum ProgressRange { fourWeeks, threeMonths, all }

const _rangeDays = {
  ProgressRange.fourWeeks: 28,
  ProgressRange.threeMonths: 90,
  ProgressRange.all: 36500,
};

extension ProgressRangeDays on ProgressRange {
  int get days => _rangeDays[this]!;
}

/// One bar in the average-score chart -- one real completed session.
class ProgressPoint {
  final String label;
  final double value;

  const ProgressPoint({required this.label, required this.value});
}

/// One row of "BUỔI GẦN ĐÂY" -- straight from a real `PracticeHistoryEntry`.
class SessionHistoryItem {
  final String id;
  final String title;
  final String subtitle;
  final double score;

  const SessionHistoryItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.score,
  });
}

/// The chart + history shown on "Tiến độ" for one [ProgressRange].
///
/// No single GraphQL field returns this shape -- it's built client-side from
/// real `myPracticeHistory` rows (`overallScore`/`startedAt` per session),
/// NOT `myPracticeProgress` (that query mixes per-criterion scores across
/// different criteria, which don't average into one meaningful number).
class ProgressReport {
  final ProgressRange range;
  final double averageScore;

  /// Real comparison against the equal-length period right before this one.
  /// `0` when there's no prior period to compare against (not fabricated --
  /// genuinely no data, and `0` reads as "no change" which is the honest
  /// answer here).
  final double delta;
  final List<ProgressPoint> points;
  final List<SessionHistoryItem> recentSessions;

  const ProgressReport({
    required this.range,
    required this.averageScore,
    required this.delta,
    this.points = const [],
    this.recentSessions = const [],
  });

  double get peak =>
      points.fold<double>(1, (max, p) => p.value > max ? p.value : max);

  factory ProgressReport.fromHistory(
    List<PracticeHistoryEntry> entries,
    ProgressRange range,
  ) {
    final days = _rangeDays[range]!;
    final now = DateTime.now();
    final cutoff = now.subtract(Duration(days: days));
    final previousCutoff = now.subtract(Duration(days: days * 2));

    bool isScored(PracticeHistoryEntry e) =>
        e.overallScore != null && e.startedAt != null;

    final current =
        entries
            .where((e) => isScored(e) && e.startedAt!.isAfter(cutoff))
            .toList()
          ..sort((a, b) => a.startedAt!.compareTo(b.startedAt!));
    final previous = entries.where(
      (e) =>
          isScored(e) &&
          e.startedAt!.isAfter(previousCutoff) &&
          e.startedAt!.isBefore(cutoff),
    );

    double average(Iterable<PracticeHistoryEntry> items) {
      if (items.isEmpty) return 0;
      return items.map((e) => e.overallScore!).reduce((a, b) => a + b) /
          items.length;
    }

    final averageScore = average(current);
    final delta = previous.isEmpty ? 0.0 : averageScore - average(previous);

    final chartEntries = current.length > 10
        ? current.sublist(current.length - 10)
        : current;
    final points = [
      for (final e in chartEntries)
        ProgressPoint(
          label: '${e.startedAt!.day}/${e.startedAt!.month}',
          value: e.overallScore!,
        ),
    ];

    final recent = [...current.reversed.take(10)];
    final recentSessions = [
      for (final e in recent)
        SessionHistoryItem(
          id: e.id,
          title: e.topicName,
          subtitle:
              '${e.startedAt!.day}/${e.startedAt!.month}/${e.startedAt!.year}',
          score: e.overallScore!,
        ),
    ];

    return ProgressReport(
      range: range,
      averageScore: averageScore,
      delta: delta,
      points: points,
      recentSessions: recentSessions,
    );
  }
}
