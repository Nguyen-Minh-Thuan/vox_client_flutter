/// Audio/transcript detail for one answered item
class ExamItemResponse {
  const ExamItemResponse({
    required this.id,
    required this.audioUrl,
    this.durationSeconds,
    this.transcript,
    this.submittedAt,
  });

  final String id;
  final String? audioUrl;
  final int? durationSeconds;
  final String? transcript;
  final DateTime? submittedAt;

  factory ExamItemResponse.fromJson(Map<String, dynamic> json) {
    return ExamItemResponse(
      id: json['id'] as String,
      audioUrl: json['audioUrl'] as String?,
      durationSeconds: json['durationSeconds'] as int?,
      transcript: json['transcript'] as String?,
      submittedAt: json['submittedAt'] != null
          ? DateTime.tryParse(json['submittedAt'] as String)
          : null,
    );
  }
}
