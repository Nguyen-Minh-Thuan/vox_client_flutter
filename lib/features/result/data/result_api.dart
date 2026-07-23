import '../../../core/network/graphql_client.dart';
import 'models/exam_result_summary.dart';

class ResultApi {
  ResultApi(this._client);

  final GraphQLClient _client;

  Future<List<ExamResultSummary>> getMyExamResults() async {
    final data = await _client.query('''
      query MyExamResults {
        myExamResults(size: 100) {
          content {
            id
            totalScore
            status
            releasedAt
            createdAt
            exam { id name }
          }
        }
      }
    ''');

    final content =
        (data['myExamResults'] as Map<String, dynamic>)['content'] as List;
    return content
        .map((e) => ExamResultSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
