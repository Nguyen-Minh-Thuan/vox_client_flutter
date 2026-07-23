import '../../teacher_exam/data/models/exam_detail.dart';
import '../../teacher_exam/data/teacher_exam_graphql_api.dart';
import 'models/exam_room_schedule.dart';
import 'models/exam_schedule.dart';
import 'schedule_api.dart';

class TeacherScheduleItem {
  final ExamDetail exam;
  final ExamRoomSchedule schedule;

  const TeacherScheduleItem({required this.exam, required this.schedule});
}

class ScheduleRepository {
  ScheduleRepository(this._api, [TeacherExamGraphQLApi? teacherApi])
      : _teacherApi = teacherApi;

  final ScheduleApi _api;
  final TeacherExamGraphQLApi? _teacherApi;

  Future<List<ExamSchedule>> getExams() => _api.getExams();

  /// Centralized exams the teacher proctors, one item per room assignment.
  Future<List<TeacherScheduleItem>> getTeacherCentralizedSchedule({
    required String schoolId,
    required String myUserId,
  }) async {
    final teacherApi = _teacherApi;
    if (teacherApi == null) {
      throw StateError('ScheduleRepository was not given a TeacherExamGraphQLApi');
    }

    final exams = await teacherApi.getSchoolCentralizedExams(schoolId);

    final items = <TeacherScheduleItem>[];
    for (final exam in exams) {
      final schedules = await _api.getExamSchedules(exam.id);
      for (final schedule in schedules) {
        if (schedule.proctorUserIds.contains(myUserId)) {
          items.add(TeacherScheduleItem(exam: exam, schedule: schedule));
        }
      }
    }
    return items;
  }
}
