import '../../../core/network/graphql_client.dart';
import 'models/exam_room_schedule.dart';
import 'models/exam_schedule.dart';

class ScheduleApi {
  ScheduleApi(this._client);

  final GraphQLClient _client;

  Future<List<ExamSchedule>> getExams({int page = 0, int size = 100}) async {
    final data = await _client.query('''
      query Exams(\$page: Int, \$size: Int) {
        exams(page: \$page, size: \$size) {
          content { id name description kind status openAt closeAt }
        }
      }
    ''', variables: {'page': page, 'size': size});

    final content = (data['exams'] as Map<String, dynamic>)['content'] as List;
    return content
        .map((e) => ExamSchedule.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ExamRoomSchedule>> getExamSchedules(String examId) async {
    final data = await _client.query('''
      query ExamSchedules(\$examId: ID) {
        examSchedules(examId: \$examId) {
          id examId startDate endDate
          room { name code }
          proctors { teacher { id } }
        }
      }
    ''', variables: {'examId': examId});

    final list = data['examSchedules'] as List;
    return list
        .map((e) => ExamRoomSchedule.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
