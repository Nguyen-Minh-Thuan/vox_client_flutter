/// Một chủ đề AI đề xuất từ CHÍNH LỜI học sinh nói trong các buổi luyện gần đây.
///
/// Khác hẳn chủ đề trong danh sách thường: những chủ đề kia do `topicOfferBackfillService`
/// soạn nền theo hồ sơ sở thích, còn cái này đọc `transcript` 30 ngày gần nhất, đếm từ khoá
/// theo SỐ BUỔI xuất hiện rồi nhờ LLM đề xuất. Vì vậy nó phải hỏi học sinh trước khi thành
/// chủ đề thật -- nhận hay bỏ.
class TopicSuggestion {
  const TopicSuggestion({
    required this.id,
    required this.name,
    required this.interestDimension,
    required this.confidence,
    required this.reasonText,
  });

  final String id;
  final String name;
  final String interestDimension;

  /// 0..1. Là TRẦN theo lượng bằng chứng thật, không phải điểm tự tin LLM tự khai:
  /// xuất hiện ≤ 1 buổi → tối đa 0,5; 2 buổi → 0,7; từ 3 buổi → 0,85.
  final double confidence;

  /// Vì sao đề xuất, viết bằng lời -- hiện thẳng cho học sinh đọc.
  final String reasonText;

  factory TopicSuggestion.fromJson(Map<String, dynamic> json) {
    return TopicSuggestion(
      id: json['id'] as String,
      name: json['suggestedTopicName'] as String,
      interestDimension: json['interestDimension'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      reasonText: json['reasonText'] as String? ?? '',
    );
  }
}
