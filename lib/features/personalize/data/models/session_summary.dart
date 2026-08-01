/// Everything shown on the "Tổng kết buổi nói" screen.
class SessionSummary {
  final String sessionId;
  final String topicTitle;
  final int minutes;
  final double score;

  /// Difference against the previous session, e.g. `+0.4`.
  final double? delta;
  final List<SessionRubricCriterion> rubric;
  final List<RepeatedError> repeatedErrors;

  /// Estimated minutes for the "Luyện lại N lỗi này" drill.
  final int drillMinutes;

  const SessionSummary({
    required this.sessionId,
    required this.topicTitle,
    required this.minutes,
    required this.score,
    required this.delta,
    this.rubric = const [],
    this.repeatedErrors = const [],
    this.drillMinutes = 4,
  });

  factory SessionSummary.fromJson(Map<String, dynamic> json) {
    return SessionSummary(
      sessionId: json['sessionId'] as String,
      topicTitle: json['topicTitle'] as String,
      minutes: (json['minutes'] as num?)?.toInt() ?? 0,
      score: (json['score'] as num?)?.toDouble() ?? 0,
      delta: (json['delta'] as num?)?.toDouble() ?? 0,
      rubric: (json['rubric'] as List<dynamic>? ?? const [])
          .map((e) => SessionRubricCriterion.fromJson(e as Map<String, dynamic>))
          .toList(),
      repeatedErrors: (json['repeatedErrors'] as List<dynamic>? ?? const [])
          .map((e) => RepeatedError.fromJson(e as Map<String, dynamic>))
          .toList(),
      drillMinutes: (json['drillMinutes'] as num?)?.toInt() ?? 4,
    );
  }
}

/// How a repeated error trended within the session.
class SessionRubricCriterion {
  final String label;
  final double score;

  const SessionRubricCriterion({required this.label, required this.score});

  factory SessionRubricCriterion.fromJson(Map<String, dynamic> json) =>
      SessionRubricCriterion(
        label: json['label'] as String,
        score: (json['score'] as num?)?.toDouble() ?? 0,
      );
}

/// One row of "LỖI LẶP LẠI TRONG BUỔI".
class RepeatedError {
  final String label;
  final int count;
  const RepeatedError({
    required this.label,
    required this.count,
  });

  factory RepeatedError.fromJson(Map<String, dynamic> json) {
    return RepeatedError(
      label: json['label'] as String,
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}
