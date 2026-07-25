import '../../../core/network/graphql_client.dart';
import 'models/exam_candidate_result.dart';
import 'models/exam_result_summary.dart';

class ResultApi {
  ResultApi(this._client);

  final GraphQLClient _client;

  Future<List<ExamResultSummary>> getMyExamResults() async {
    final data = await _client.query('''
      query MyExamResults {
        myExamResults {
          sessionId
          examName
          totalScore
          resultStatus
          submittedAt
        }
      }
    ''');

    final results = data['myExamResults'] as List;
    return results
        .map((e) => ExamResultSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ExamCandidateResult> getSessionResult(String sessionId) async {
    final data = await _client.query('''
      query ExamSessionResult(\$sessionId: ID!) {
        examSessionResult(sessionId: \$sessionId) {
          scoreVisible
          totalScore
          status
          sections { title score }
        }
      }
    ''', variables: {'sessionId': sessionId});

    return ExamCandidateResult.fromJson(
        data['examSessionResult'] as Map<String, dynamic>);
  }
}
