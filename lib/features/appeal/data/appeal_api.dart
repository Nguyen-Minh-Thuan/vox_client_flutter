import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/graphql_client.dart';
import 'models/appeal_summary.dart';

class AppealApi {
  AppealApi(this._client, this._graphQLClient);

  final ApiClient _client;
  final GraphQLClient _graphQLClient;

  Future<String> createAppeal({
    required String candidateResultId,
    required List<String> paperItemIds,
    required String reason,
    String? notes,
  }) async {
    final response = await _client.post(ApiEndpoints.examAppeals, data: {
      'candidateResultId': candidateResultId,
      'paperItemIds': paperItemIds,
      'reason': reason,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
    return response.data['data'] as String;
  }

  /// the student's own appeal requests.
  Future<List<AppealSummary>> getMyAppeals() async {
    final data = await _graphQLClient.query('''
      query MyAppeals {
        myAppeals(size: 50) {
          content {
            id
            className
            examName
            partLabels
            originalScore
            status
            requestedAt
            deadline
            reviewerCount
            doneCount
            overdue
          }
        }
      }
    ''');

    final content = data['myAppeals']['content'] as List;
    return content
        .map((e) => AppealSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
