import 'exam_result_summary.dart';

class ExamCandidateResultSection {
  const ExamCandidateResultSection({
    required this.title,
    required this.score,
  });

  final String? title;
  final double score;

  factory ExamCandidateResultSection.fromJson(Map<String, dynamic> json) {
    return ExamCandidateResultSection(
      title: json['title'] as String?,
      score: (json['score'] as num).toDouble(),
    );
  }
}

/// Full per-attempt result, from `examSessionResult` (ExamCandidateResult).
class ExamCandidateResult {
  const ExamCandidateResult({
    required this.scoreVisible,
    required this.totalScore,
    required this.status,
    required this.sections,
  });

  final bool scoreVisible;
  final double? totalScore;
  final ExamResultStatus status;
  final List<ExamCandidateResultSection> sections;

  factory ExamCandidateResult.fromJson(Map<String, dynamic> json) {
    return ExamCandidateResult(
      scoreVisible: json['scoreVisible'] as bool? ?? false,
      totalScore: (json['totalScore'] as num?)?.toDouble(),
      status: ExamResultSummary.statusFromJson(json['status'] as String?),
      sections: (json['sections'] as List? ?? const [])
          .map((e) =>
              ExamCandidateResultSection.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
