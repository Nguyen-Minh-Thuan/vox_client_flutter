import '../../../core/network/graphql_client.dart';
import 'models/interest.dart';
import 'models/learner_profile.dart';
import 'models/onboarding_question.dart';
import 'models/practice_dashboard.dart';
import 'models/practice_session.dart';
import 'models/practice_topic.dart';
import 'models/progress_report.dart';
import 'models/session_summary.dart';
import 'models/weakness.dart';
import 'personalize_api.dart';
import 'personalize_demo_data.dart';

/// Data source for the personalized-practice feature.
///
/// Topic selection (`getTopics`/`searchTopics`/saved topics) and
/// `getDashboard`'s `sessionsDone`/`averageScore`/`streakDays` are wired to
/// the real backend via [PersonalizeApi] — see gói 11 mục 2.6b for exactly
/// which fields are real vs. still backend gaps. Everything else here still
/// resolves against [PersonalizeDemoData] after a short delay standing in
/// for network latency (today's topic, weekly goal, onboarding, sessions,
/// etc. have no backend support yet — same gói, same section).
class PersonalizeRepository {
  PersonalizeRepository({Duration? latency, PersonalizeApi? api})
      : _latency = latency ?? const Duration(milliseconds: 400),
        _api = api ?? PersonalizeApi(GraphQLClient());

  final Duration _latency;
  final PersonalizeApi _api;

  Future<T> _delayed<T>(T value) =>
      Future<T>.delayed(_latency, () => value);

  /// `sessionsDone`/`averageScore`/`streakDays` come from the real
  /// `myPracticeDashboardStats` query; the rest (today's topic, weekly
  /// focus/goal, suggestions) still resolves against demo data — see gói 11
  /// mục 2.6b for what's still a backend gap.
  Future<PracticeDashboard> getDashboard() async {
    final base = PersonalizeDemoData.dashboard;
    final stats = await _api.getDashboardStats();
    return PracticeDashboard(
      learnerName: base.learnerName,
      streakDays: (stats['streakDays'] as num?)?.toInt() ?? base.streakDays,
      todayTopic: base.todayTopic,
      sessionsDone: (stats['sessionsDone'] as num?)?.toInt() ?? base.sessionsDone,
      averageScore:
          (stats['averageScore'] as num?)?.toDouble() ?? base.averageScore,
      weeklyGoalDone: base.weeklyGoalDone,
      weeklyGoalTarget: base.weeklyGoalTarget,
      weeklyFocus: base.weeklyFocus,
      suggestions: base.suggestions,
    );
  }

  static const _bucketByFilter = {
    TopicFilter.forYou: 'FOR_YOU',
    TopicFilter.byGoal: 'BY_GOAL',
    TopicFilter.byWeakness: 'BY_WEAKNESS',
  };

  /// `forYou`/`byGoal`/`byWeakness` each map to a real ranking bucket on
  /// `practiceTopicOffers` (gói 11 mục 2.6b); `saved` calls `mySavedTopics`.
  Future<List<PracticeTopic>> getTopics(TopicFilter filter) async {
    if (filter == TopicFilter.saved) {
      final saved = await _api.getSavedTopics();
      return saved
          .map((json) => PracticeTopic.fromOffer(json, bucket: filter))
          .toList();
    }
    final offers = await _api.getTopicOffers(bucket: _bucketByFilter[filter]!);
    return offers
        .map((json) => PracticeTopic.fromOffer(json, bucket: filter))
        .toList();
  }

  /// Full topic list, unfiltered — used by the search field. `canGenerate`
  /// mirrors `TopicSearchResult.canGenerate` (schema) so the search screen
  /// can offer "create this topic" instead of a plain empty state.
  Future<({List<PracticeTopic> topics, bool canGenerate})> searchTopics(
    String query,
  ) async {
    final keyword = query.trim();
    if (keyword.isEmpty) {
      final topics = await getTopics(TopicFilter.forYou);
      return (topics: topics, canGenerate: false);
    }
    final result = await _api.searchTopics(keyword);
    return (
      topics: result.topics.map(PracticeTopic.fromOffer).toList(),
      canGenerate: result.canGenerate,
    );
  }

  /// Maps to `generateTopicFromKeyword` — called when the learner accepts
  /// the "create this topic" offer surfaced by `canGenerate`. Returns the
  /// created/matched topic, or null if the AI rejected the keyword
  /// (`REJECTED_UNSUITABLE`/`OUT_OF_EXAM_SCOPE`).
  Future<PracticeTopic?> generateTopicFromKeyword(String keyword) async {
    final result = await _api.generateTopicFromKeyword(keyword);
    if (result.topic == null) return null;
    return PracticeTopic.fromOffer(result.topic!);
  }

  /// Builds the first MAIN question + starts a real practice session (gói 11 mục 2.2/2.7b):
  /// `buildPracticePaper` -> `startPracticeSession`. `session.id` is also the realtime
  /// WebSocket's practiceSessionId; `firstQuestion` is the raw `PracticePaperQuestion` JSON,
  /// handed back so the caller can send it as the WS `question_start` payload.
  Future<({PracticeSession session, Map<String, dynamic> firstQuestion})> startSession(
    PracticeTopic topic,
  ) async {
    final paper = await _api.buildPracticePaper(topicId: topic.id, origin: 'SELECTED');
    final questions = (paper['questions'] as List).cast<Map<String, dynamic>>();
    final firstQuestion = questions.first;
    final sessionJson = await _api.startPracticeSession(paper['id'] as String);
    final session = PracticeSession(
      id: sessionJson['id'] as String,
      topicId: (sessionJson['topicId'] as String?) ?? topic.id,
      topicTitle: (sessionJson['topicName'] as String?) ?? topic.title,
      focusTags: topic.focusTags,
      turns: const [],
    );
    return (session: session, firstQuestion: firstQuestion);
  }

  /// Maps to `endPracticeSession` — called AFTER the WS practice_end/practice_end_ack
  /// handshake and socket close (gói 11 mục 2.9 điểm 2), never before.
  Future<void> endPracticeSession({
    required String sessionId,
    required int helpRequestCount,
    required int longPauseCount,
  }) {
    return _api.endPracticeSession(
      sessionId: sessionId,
      helpRequestCount: helpRequestCount,
      longPauseCount: longPauseCount,
    );
  }

  Future<SessionSummary> getSessionSummary(String sessionId) =>
      _delayed(PersonalizeDemoData.sessionSummary);

  Future<WeaknessProfile> getWeaknessProfile() =>
      _delayed(PersonalizeDemoData.weaknessProfile);

  Future<List<Interest>> getInterests() =>
      _delayed(PersonalizeDemoData.interests);

  Future<ProgressReport> getProgress(ProgressRange range) => _delayed(
        PersonalizeDemoData.progressReports[range] ??
            PersonalizeDemoData.progressReports[ProgressRange.fourWeeks]!,
      );

  Future<List<OnboardingQuestion>> getOnboardingQuestions() =>
      _delayed(PersonalizeDemoData.onboardingQuestions);

  Future<List<InterestChoice>> getInterestChoices() =>
      _delayed(PersonalizeDemoData.interestChoices);

  Future<List<LearningGoal>> getLearningGoals() =>
      _delayed(PersonalizeDemoData.learningGoals);

  /// Submits the questionnaire and returns the derived profile.
  ///
  /// The answers are ignored while the scoring model lives on the backend.
  Future<LearnerProfile> submitOnboarding({
    required Map<String, int> answers,
    required Set<String> interestIds,
    required String? goalId,
  }) =>
      _delayed(PersonalizeDemoData.learnerProfile);
}
