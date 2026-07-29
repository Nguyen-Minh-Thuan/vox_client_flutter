/// Time window behind the pills on the progress screen.
enum ProgressRange { fourWeeks, threeMonths, all }

/// The chart + history shown on "Tiến độ" for one [ProgressRange].
class ProgressReport {
  final ProgressRange range;
  final double averageScore;

  /// Change across the window, e.g. `+0.9`.
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

  /// Highest value in [points], used to scale the bars. Never zero.
  double get peak => points.fold<double>(
        1,
        (max, p) => p.value > max ? p.value : max,
      );

  factory ProgressReport.fromJson(Map<String, dynamic> json) {
    return ProgressReport(
      range: _rangeFromJson(json['range'] as String?),
      averageScore: (json['averageScore'] as num?)?.toDouble() ?? 0,
      delta: (json['delta'] as num?)?.toDouble() ?? 0,
      points: (json['points'] as List<dynamic>? ?? const [])
          .map((e) => ProgressPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      recentSessions: (json['recentSessions'] as List<dynamic>? ?? const [])
          .map((e) => SessionHistoryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static ProgressRange _rangeFromJson(String? value) {
    switch (value) {
      case 'THREE_MONTHS':
        return ProgressRange.threeMonths;
      case 'ALL':
        return ProgressRange.all;
      case 'FOUR_WEEKS':
      default:
        return ProgressRange.fourWeeks;
    }
  }
}

/// One bar in the average-score chart.
class ProgressPoint {
  final String label;
  final double value;

  const ProgressPoint({required this.label, required this.value});

  factory ProgressPoint.fromJson(Map<String, dynamic> json) {
    return ProgressPoint(
      label: json['label'] as String,
      value: (json['value'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// One row of "BUỔI GẦN ĐÂY".
class SessionHistoryItem {
  final String id;
  final String title;

  /// Relative caption, e.g. "Hôm nay · 8 phút".
  final String subtitle;
  final double score;
  final String icon;

  const SessionHistoryItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.score,
    this.icon = 'chat_bubble_outline',
  });

  factory SessionHistoryItem.fromJson(Map<String, dynamic> json) {
    return SessionHistoryItem(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String? ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 0,
      icon: json['icon'] as String? ?? 'chat_bubble_outline',
    );
  }
}
