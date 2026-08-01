import '../../../core/network/graphql_client.dart';
import '../../profile/data/profile_api.dart';
import 'models/interest.dart';
import 'models/onboarding_question.dart';
import 'models/practice_dashboard.dart';
import 'models/practice_history_entry.dart';
import 'models/practice_session.dart';
import 'models/practice_topic.dart';
import 'models/progress_report.dart';
import 'models/session_summary.dart';
import 'models/weakness.dart';
import 'personalize_api.dart';
import 'personalize_demo_data.dart';

/// Data source for the personalized-practice feature.
///
/// Every method here is either a real GraphQL call or a documented
/// client-side aggregation of a few real calls (`getDashboard`/`getProgress`)
/// — see each method's doc comment.
class PersonalizeRepository {
  PersonalizeRepository({Duration? latency, PersonalizeApi? api, ProfileApi? profileApi})
      : _latency = latency ?? const Duration(milliseconds: 400),
        _api = api ?? PersonalizeApi(GraphQLClient()),
        _profileApi = profileApi ?? ProfileApi(GraphQLClient());

  final Duration _latency;
  final PersonalizeApi _api;
  final ProfileApi _profileApi;

  Future<T> _delayed<T>(T value) =>
      Future<T>.delayed(_latency, () => value);

  /// No single query returns this shape -- assembled from real
  /// `myPracticeDashboardStats`, `practiceTopicOffers` (bucket FOR_YOU),
  /// `myWeaknessProfile` and `profile { fullName }`. `sessionsThisWeek` is a
  /// real count of `myPracticeHistory` entries since the start of this
  /// calendar week (Monday) -- there's no "weekly goal target" anywhere in
  /// the backend, so no "/N" is shown (see conversation: confirmed no such
  /// field exists rather than guessing a number).
  Future<PracticeDashboard> getDashboard() async {
    final stats = await _api.getDashboardStats();
    final offers = await _api.getTopicOffers(bucket: 'FOR_YOU');
    final weakness = await getWeaknessProfile();
    final history = await getPracticeHistory(limit: 50);
    final profile = await _profileApi.getProfile();

    final topics = offers.map(PracticeTopic.fromOffer).toList();
    final now = DateTime.now();
    final startOfWeek = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final sessionsThisWeek = history
        .where((e) => e.startedAt != null && !e.startedAt!.isBefore(startOfWeek))
        .length;

    return PracticeDashboard(
      learnerName: profile.fullName ?? '',
      streakDays: (stats['streakDays'] as num?)?.toInt() ?? 0,
      todayTopic: topics.isEmpty ? null : topics.first,
      sessionsDone: (stats['sessionsDone'] as num?)?.toInt() ?? 0,
      averageScore: (stats['averageScore'] as num?)?.toDouble() ?? 0,
      sessionsThisWeek: sessionsThisWeek,
      weeklyFocus: weakness.criteria.take(2).toList(),
      suggestions: topics.skip(1).take(4).toList(),
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

  /// Maps to `myLearnerProfile { goalType }` — current EXAM_PREP/ABILITY_IMPROVEMENT goal.
  /// Defaults to `ABILITY_IMPROVEMENT` if the learner has never set one (matches the
  /// backend's own default fallback).
  Future<String> getPracticeGoal() async {
    final goal = await _api.getPracticeGoal();
    return goal ?? 'ABILITY_IMPROVEMENT';
  }

  /// Maps to `setPracticeGoal(goalType)` — returns the goal actually persisted.
  Future<String> setPracticeGoal(String goalType) => _api.setPracticeGoal(goalType);

  /// Maps to `interestQuizItems` — real AI-generated forced-choice triplets,
  /// NOT `PersonalizeDemoData` (this is the cold-start interest inventory).
  Future<List<InterestQuizItem>> getInterestQuizItems() async {
    final items = await _api.getInterestQuizItems();
    return items.map(InterestQuizItem.fromJson).toList();
  }

  /// Maps to `submitInterestQuiz` — scores answers into the real
  /// `dimension_interest_score` vector server-side.
  Future<void> submitInterestQuiz(List<InterestQuizAnswer> answers) {
    return _api.submitInterestQuiz(answers.map((a) => a.toJson()).toList());
  }

  Future<SessionSummary> getSessionSummary(String sessionId) async {
    final results = await Future.wait([
      _api.getPracticeSessionDetail(sessionId),
      _api.getPracticeHistory(50),
    ]);
    final detail = results[0] as Map<String, dynamic>;
    final historyRows = (results[1] as List<Map<String, dynamic>>)
        .map(PracticeHistoryEntry.fromJson)
        .toList()
      ..sort((a, b) => (a.startedAt ?? DateTime.fromMillisecondsSinceEpoch(0))
          .compareTo(b.startedAt ?? DateTime.fromMillisecondsSinceEpoch(0)));
    final currentIndex = historyRows.indexWhere((entry) => entry.id == sessionId);
    final currentScore = (detail['overallScore'] as num?)?.toDouble() ?? 0;
    final previousScore = currentIndex > 0 ? historyRows[currentIndex - 1].overallScore : null;

    final correctionCounts = <String, int>{};
    for (final turn in (detail['turns'] as List? ?? const [])) {
      final turnMap = turn as Map<String, dynamic>;
      for (final correction in (turnMap['corrections'] as List? ?? const [])) {
        final category = ((correction as Map<String, dynamic>)['category'] as String? ?? '').trim();
        if (category.isNotEmpty) correctionCounts.update(category, (value) => value + 1, ifAbsent: () => 1);
      }
    }

    return SessionSummary(
      sessionId: detail['sessionId'] as String,
      topicTitle: detail['topicName'] as String? ?? '',
      minutes: ((detail['durationSeconds'] as num?)?.toInt() ?? 0) ~/ 60,
      score: currentScore,
      delta: previousScore == null ? null : currentScore - previousScore,
      rubric: (detail['criterionScores'] as List? ?? const []).map((row) {
        final criterion = row as Map<String, dynamic>;
        final code = criterion['criterionCode'] as String? ?? '';
        return SessionRubricCriterion(
          label: _criterionLabel(code),
          score: (criterion['score'] as num?)?.toDouble() ?? 0,
        );
      }).toList(),
      repeatedErrors: correctionCounts.entries
          .map((entry) => RepeatedError(label: _criterionLabel(entry.key), count: entry.value))
          .toList()
        ..sort((a, b) => b.count.compareTo(a.count)),
    );
  }

  static String _criterionLabel(String code) {
    switch (code.trim().toUpperCase()) {
      case 'GRAMMAR': return 'Ngữ pháp';
      case 'VOCABULARY': return 'Từ vựng';
      case 'COHERENCE': return 'Mạch lạc';
      case 'FLUENCY': return 'Độ trôi chảy';
      case 'PRONUNCIATION': return 'Phát âm';
      default:
        if (code.isEmpty) return 'Khác';
        return code.replaceAll('_', ' ').toLowerCase().split(' ').map((part) => part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}').join(' ');
    }
  }

  /// Maps to `myWeaknessProfile` — real, not `PersonalizeDemoData`.
  Future<WeaknessProfile> getWeaknessProfile() async {
    final json = await _api.getWeaknessProfile();
    return WeaknessProfile.fromJson(json);
  }

  Future<List<OnboardingQuestion>> getOnboardingQuestions() =>
      _delayed(PersonalizeDemoData.onboardingQuestions);

  /// Maps to `submitFlsaSelfReport(answers)`.
  Future<void> submitFlsaSelfReport(List<int> answers) =>
      _api.submitFlsaSelfReport(answers);

  /// Maps to `saveTopic(topicId)`.
  Future<void> saveTopic(String topicId) => _api.saveTopic(topicId);

  /// Maps to `unsaveTopic(topicId)`.
  Future<void> unsaveTopic(String topicId) => _api.unsaveTopic(topicId);

  /// Maps to `pickRandomTopic`.
  Future<PracticeTopic> pickRandomTopic() async {
    final json = await _api.pickRandomTopic();
    return PracticeTopic.fromOffer(json);
  }

  /// Maps to `myPracticeHistory(limit)`.
  Future<List<PracticeHistoryEntry>> getPracticeHistory({int limit = 20}) async {
    final rows = await _api.getPracticeHistory(limit);
    return rows.map(PracticeHistoryEntry.fromJson).toList();
  }

  /// Builds a [ProgressReport] from real `myPracticeHistory` rows -- see
  /// `ProgressReport.fromHistory` for why this isn't `myPracticeProgress`.
  /// Fetches enough history to cover 2x the widest range (`all`) so the
  /// delta comparison always has a real previous period to diff against.
  Future<ProgressReport> getProgress(ProgressRange range) async {
    final entries = await getPracticeHistory(limit: 200);
    return ProgressReport.fromHistory(entries, range);
  }

  /// Maps to `myInterestProfile{topics, suggestions}` -- `topics` become
  /// active/cooling rows, PENDING `suggestions` become "discovered" cards.
  Future<List<Interest>> getInterests() async {
    final json = await _api.getInterestProfile();
    final topics = (json['topics'] as List? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(Interest.fromTopic);
    final suggestions = (json['suggestions'] as List? ?? const [])
        .cast<Map<String, dynamic>>()
        .where((s) => s['status'] == 'PENDING')
        .map(Interest.fromSuggestion);
    return [...suggestions, ...topics];
  }

  /// Maps to `respondToTopicSuggestion(suggestionId, accept)`.
  Future<void> respondToTopicSuggestion(String suggestionId, bool accept) =>
      _api.respondToTopicSuggestion(suggestionId, accept);

  /// Maps to `myLearnerProfile { interestAutoUpdateEnabled }`.
  Future<bool> getInterestAutoUpdateEnabled() => _api.getInterestAutoUpdateEnabled();

  /// Maps to `setInterestAutoUpdate(enabled)` -- returns the value actually
  /// persisted.
  Future<bool> setInterestAutoUpdate(bool enabled) => _api.setInterestAutoUpdate(enabled);
}
