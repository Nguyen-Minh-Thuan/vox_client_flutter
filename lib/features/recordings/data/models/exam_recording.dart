class ExamRecording {
  const ExamRecording({
    required this.id,
    this.examName,
    required this.audioUrl,
    this.durationSeconds,
    this.transcript,
    required this.submittedAt,
  });

  final String id;
  final String? examName;
  final String audioUrl;
  final int? durationSeconds;
  final String? transcript;
  final DateTime submittedAt;

  factory ExamRecording.fromJson(Map<String, dynamic> json) {
    return ExamRecording(
      id: json['id'] as String,
      examName: (json['exam'] as Map<String, dynamic>?)?['name'] as String?,
      audioUrl: json['audioUrl'] as String,
      durationSeconds: json['durationSeconds'] as int?,
      transcript: json['transcript'] as String?,
      submittedAt:
          DateTime.tryParse(json['submittedAt'] as String? ?? '') ??
              DateTime.now(),
    );
  }
}
