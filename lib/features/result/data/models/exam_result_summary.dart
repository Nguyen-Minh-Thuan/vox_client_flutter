enum ExamResultStatus {
  pendingReview,
  released,
  appealed,
  reGrading,
  final_,
  invalid,
  retakeRequired,
  passed,
  failed,
}

/// One past exam attempt, from `myExamResults` (StudentExamResultSummary).
class ExamResultSummary {
  const ExamResultSummary({
    required this.sessionId,
    required this.examName,
    required this.totalScore,
    required this.status,
    required this.submittedAt,
  });

  final String sessionId;
  final String examName;
  final double? totalScore;
  final ExamResultStatus status;
  final DateTime? submittedAt;

  factory ExamResultSummary.fromJson(Map<String, dynamic> json) {
    return ExamResultSummary(
      sessionId: json['sessionId'] as String,
      examName: json['examName'] as String? ?? 'Exam',
      totalScore: (json['totalScore'] as num?)?.toDouble(),
      status: statusFromJson(json['resultStatus'] as String?),
      submittedAt: json['submittedAt'] != null
          ? DateTime.tryParse(json['submittedAt'] as String)
          : null,
    );
  }

  static ExamResultStatus statusFromJson(String? value) {
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
      case 'PASSED':
        return ExamResultStatus.passed;
      case 'FAILED':
        return ExamResultStatus.failed;
      case 'PENDING_REVIEW':
      default:
        return ExamResultStatus.pendingReview;
    }
  }
}
