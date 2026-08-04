/// Where an interest sits in the self-updating profile.
enum InterestStatus {
  /// Real `TopicInterest` row, mentioned within the last 21 days.
  active,

  /// Real `TopicInterest` row, not mentioned in 21+ days -- derived from the
  /// real `lastMentionedAt` timestamp (now exposed by the backend), NOT
  /// fabricated: a fixed cutoff applied to a real date.
  cooling,

  /// A real AI `TopicSuggestion` (status PENDING) awaiting the learner's
  /// accept/dismiss via `respondToTopicSuggestion`.
  discovered,
}

const _coolingCutoffDays = 21;

/// A topic the learner likes talking about (real `topics`/`suggestions` from
/// `myInterestProfile`).
class Interest {
  final String id;
  final String label;
  final InterestStatus status;

  /// Sub-caption, e.g. "nói 5 buổi".
  final String detail;

  /// Meter fill, 0..1. Unused for [InterestStatus.discovered].
  final double ratio;

  /// Only for [InterestStatus.discovered] -- 0..100 confidence, real field
  /// from `TopicSuggestion.confidence`.
  final int? confidence;

  /// Only for [InterestStatus.discovered] -- real `TopicSuggestion.reasonText`.
  final String? evidence;

  const Interest({
    required this.id,
    required this.label,
    required this.status,
    this.detail = '',
    this.ratio = 0,
    this.confidence,
    this.evidence,
  });

  Interest copyWith({InterestStatus? status}) {
    return Interest(
      id: id,
      label: label,
      status: status ?? this.status,
      detail: detail,
      ratio: ratio,
      confidence: confidence,
      evidence: evidence,
    );
  }

  /// Builds from one `TopicInterest` row (`topics` in `myInterestProfile`).
  factory Interest.fromTopic(Map<String, dynamic> json) {
    final score = (json['score'] as num?)?.toDouble() ?? 0;
    final sessionsMentioned = (json['sessionsMentioned'] as num?)?.toInt() ?? 0;
    final lastMentionedAt = json['lastMentionedAt'] == null
        ? null
        : DateTime.tryParse(json['lastMentionedAt'] as String);
    final cooling =
        lastMentionedAt == null ||
        DateTime.now().difference(lastMentionedAt).inDays > _coolingCutoffDays;
    return Interest(
      id: json['topicId'] as String,
      label: json['name'] as String,
      status: cooling ? InterestStatus.cooling : InterestStatus.active,
      detail: 'Nói $sessionsMentioned buổi',
      ratio: score.clamp(0.0, 1.0),
    );
  }

  /// Builds from one `TopicSuggestion` row (`suggestions`, status PENDING
  /// only -- `id` here is the suggestion id, used for `respondToTopicSuggestion`).
  factory Interest.fromSuggestion(Map<String, dynamic> json) {
    final confidence = (json['confidence'] as num?)?.toDouble();
    return Interest(
      id: json['id'] as String,
      label: json['suggestedTopicName'] as String,
      status: InterestStatus.discovered,
      confidence: confidence == null ? null : (confidence * 100).round(),
      evidence: json['reasonText'] as String?,
    );
  }
}
