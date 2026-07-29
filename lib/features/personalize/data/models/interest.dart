/// Where an interest sits in the self-updating profile.
enum InterestStatus {
  /// Spoken about recently — listed under "ĐANG HOẠT ĐỘNG".
  active,

  /// Not mentioned for a while — listed under "ĐANG NGUỘI DẦN".
  cooling,

  /// Inferred from transcripts, awaiting the learner's confirmation.
  discovered,
}

/// A topic the learner likes talking about.
class Interest {
  final String id;
  final String emoji;
  final String label;
  final InterestStatus status;

  /// Sub-caption, e.g. "nói 5/8 buổi" or "Không nhắc tới trong 6 buổi gần nhất".
  final String detail;

  /// Meter fill, 0..1. Unused for cooling entries.
  final double ratio;

  /// Only for [InterestStatus.discovered] — 0..100 confidence.
  final int? confidence;

  /// Only for [InterestStatus.discovered] — why it was inferred.
  final String? evidence;

  const Interest({
    required this.id,
    required this.emoji,
    required this.label,
    required this.status,
    this.detail = '',
    this.ratio = 0,
    this.confidence,
    this.evidence,
  });

  Interest copyWith({InterestStatus? status, String? detail, double? ratio}) {
    return Interest(
      id: id,
      emoji: emoji,
      label: label,
      status: status ?? this.status,
      detail: detail ?? this.detail,
      ratio: ratio ?? this.ratio,
      confidence: confidence,
      evidence: evidence,
    );
  }

  factory Interest.fromJson(Map<String, dynamic> json) {
    return Interest(
      id: json['id'] as String,
      emoji: json['emoji'] as String? ?? '',
      label: json['label'] as String,
      status: _statusFromJson(json['status'] as String?),
      detail: json['detail'] as String? ?? '',
      ratio: (json['ratio'] as num?)?.toDouble() ?? 0,
      confidence: (json['confidence'] as num?)?.toInt(),
      evidence: json['evidence'] as String?,
    );
  }

  static InterestStatus _statusFromJson(String? value) {
    switch (value) {
      case 'COOLING':
        return InterestStatus.cooling;
      case 'DISCOVERED':
        return InterestStatus.discovered;
      case 'ACTIVE':
      default:
        return InterestStatus.active;
    }
  }
}
