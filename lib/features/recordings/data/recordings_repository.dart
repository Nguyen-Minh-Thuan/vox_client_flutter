import 'models/exam_recording.dart';
import 'recordings_api.dart';

class RecordingsRepository {
  RecordingsRepository(this._recordingsApi);

  final RecordingsApi _recordingsApi;

  Future<List<ExamRecording>> getMyRecordings() =>
      _recordingsApi.getMyRecordings();
}
