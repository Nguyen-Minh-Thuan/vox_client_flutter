class ExamRoomSchedule {
  final String id;
  final String examId;
  final String? roomName;
  final String? roomCode;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String> proctorUserIds;

  const ExamRoomSchedule({
    required this.id,
    required this.examId,
    this.roomName,
    this.roomCode,
    this.startDate,
    this.endDate,
    this.proctorUserIds = const [],
  });

  factory ExamRoomSchedule.fromJson(Map<String, dynamic> json) {
    final room = json['room'] as Map<String, dynamic>?;
    final proctors = (json['proctors'] as List<dynamic>?) ?? const [];
    return ExamRoomSchedule(
      id: json['id'] as String,
      examId: json['examId'] as String,
      roomName: room?['name'] as String?,
      roomCode: room?['code'] as String?,
      startDate: _parseDate(json['startDate'] as String?),
      endDate: _parseDate(json['endDate'] as String?),
      proctorUserIds: proctors
          .map((p) => ((p as Map<String, dynamic>)['teacher']
              as Map<String, dynamic>?)?['id'] as String?)
          .whereType<String>()
          .toList(),
    );
  }

  static DateTime? _parseDate(String? value) =>
      value == null ? null : DateTime.tryParse(value)?.toLocal();
}
