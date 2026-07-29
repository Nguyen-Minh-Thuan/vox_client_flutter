import 'exam_result_summary.dart';

class ExamCandidateResultSection {
  const ExamCandidateResultSection({
    required this.sectionId,
    required this.title,
    required this.score,
  });

  final String sectionId;
  final String? title;
  final double score;

  factory ExamCandidateResultSection.fromJson(Map<String, dynamic> json) {
    return ExamCandidateResultSection(
      sectionId: json['sectionId'] as String,
      title: json['title'] as String?,
      score: (json['score'] as num).toDouble(),
    );
  }
}

/// One graded part of the attempt — the unit a student picks when appealing.
class ExamCandidateResultItem {
  const ExamCandidateResultItem({
    required this.paperItemId,
    required this.sectionId,
    required this.itemScore,
  });

  final String paperItemId;
  final String sectionId;
  final double itemScore;

  factory ExamCandidateResultItem.fromJson(Map<String, dynamic> json) {
    return ExamCandidateResultItem(
      paperItemId: json['paperItemId'] as String,
      sectionId: json['sectionId'] as String,
      itemScore: (json['itemScore'] as num).toDouble(),
    );
  }
}

/// Full per-attempt result, from `examSessionResult` (ExamCandidateResult).
class ExamCandidateResult {
  const ExamCandidateResult({
    required this.id,
    required this.scoreVisible,
    required this.totalScore,
    required this.status,
    required this.sections,
    required this.items,
  });

  /// candidateResultId — required to submit an appeal for this attempt.
  final String id;
  final bool scoreVisible;
  final double? totalScore;
  final ExamResultStatus status;
  final List<ExamCandidateResultSection> sections;
  final List<ExamCandidateResultItem> items;

  factory ExamCandidateResult.fromJson(Map<String, dynamic> json) {
    return ExamCandidateResult(
      id: json['id'] as String,
      scoreVisible: json['scoreVisible'] as bool? ?? false,
      totalScore: (json['totalScore'] as num?)?.toDouble(),
      status: ExamResultSummary.statusFromJson(json['status'] as String?),
      sections: (json['sections'] as List? ?? const [])
          .map((e) =>
              ExamCandidateResultSection.fromJson(e as Map<String, dynamic>))
          .toList(),
      items: (json['items'] as List? ?? const [])
          .map((e) =>
              ExamCandidateResultItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
