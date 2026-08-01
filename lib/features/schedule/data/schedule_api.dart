import '../../../core/network/graphql_client.dart';
import '../../../core/network/api_client.dart';
import 'models/exam_room_schedule.dart';
import 'models/exam_schedule.dart';

class ScheduleApi {
  ScheduleApi(this._client, [ApiClient? apiClient])
      : _apiClient = apiClient ?? ApiClient();

  final GraphQLClient _client;
  final ApiClient _apiClient;

  Future<List<ExamSchedule>> getExams({int page = 0, int size = 100}) async {
    final response = await _apiClient.get(
      '/v1/exams',
      queryParameters: {'page': page, 'size': size},
    );
    final envelope = response.data as Map<String, dynamic>;
    final payload = envelope['data'];
    final content = payload is List
        ? payload
        : (payload as Map<String, dynamic>)['content'] as List;
    return content
        .map((e) => ExamSchedule.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ExamRoomSchedule>> getExamSchedules(String? examId) async {
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

  Future<List<ExamRoomSchedule>> getMyExamSchedules() async {
    final data = await _client.query('''
      query MyExamSchedules {
        myExamSchedules {
          id examId startDate endDate
          room { name code }
          proctors { teacher { id } }
        }
      }
    ''');

    final list = data['myExamSchedules'] as List;
    return list
        .map((e) => ExamRoomSchedule.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
