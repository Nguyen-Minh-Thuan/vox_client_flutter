enum ExamResultStatus {
  pendingReview,
  released,
  appealed,
  reGrading,
  final_,
  invalid,
  retakeRequired,
}

class ExamResultSummary {
  const ExamResultSummary({
    required this.id,
    required this.examName,
    required this.totalScore,
    required this.status,
    required this.createdAt,
    this.releasedAt,
  });

  final String id;
  final String examName;
  final double? totalScore;
  final ExamResultStatus status;
  final DateTime createdAt;
  final DateTime? releasedAt;

  factory ExamResultSummary.fromJson(Map<String, dynamic> json) {
    final exam = json['exam'] as Map<String, dynamic>?;
    return ExamResultSummary(
      id: json['id'] as String,
      examName: exam?['name'] as String? ?? 'Exam',
      totalScore: (json['totalScore'] as num?)?.toDouble(),
      status: _statusFromJson(json['status'] as String?),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      releasedAt: json['releasedAt'] == null
          ? null
          : DateTime.tryParse(json['releasedAt'] as String),
    );
  }

  static ExamResultStatus _statusFromJson(String? value) {
    switch (value) {
      case 'RELEASED':
        return ExamResultStatus.released;
      case 'APPEALED':
        return ExamResultStatus.appealed;
      case 'RE_GRADING':
        return ExamResultStatus.reGrading;
      case 'FINAL':
        return ExamResultStatus.final_;
      case 'INVALID':
        return ExamResultStatus.invalid;
      case 'RETAKE_REQUIRED':
        return ExamResultStatus.retakeRequired;
      case 'PENDING_REVIEW':
      default:
        return ExamResultStatus.pendingReview;
    }
  }
}
