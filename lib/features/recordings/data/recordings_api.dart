import '../../../core/network/graphql_client.dart';
import 'models/exam_recording.dart';

class RecordingsApi {
  RecordingsApi(this._client);

  final GraphQLClient _client;

  Future<List<ExamRecording>> getMyRecordings() async {
    final data = await _client.query('''
      query MyRecordings {
        myRecordings {
          id
          exam { name }
          audioUrl
          durationSeconds
          transcript
          submittedAt
        }
      }
    ''');

    final recordings = data['myRecordings'] as List;
    return recordings
        .map((e) => ExamRecording.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
