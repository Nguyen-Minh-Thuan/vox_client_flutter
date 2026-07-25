import 'models/exam_candidate_result.dart';
import 'models/exam_result_summary.dart';
import 'result_api.dart';

class ResultRepository {
  ResultRepository(this._resultApi);

  final ResultApi _resultApi;

  Future<List<ExamResultSummary>> getMyExamResults() =>
      _resultApi.getMyExamResults();

  Future<ExamCandidateResult> getSessionResult(String sessionId) =>
      _resultApi.getSessionResult(sessionId);
}
