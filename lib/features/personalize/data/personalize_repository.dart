import 'models/interest.dart';
import 'models/learner_profile.dart';
import 'models/onboarding_question.dart';
import 'models/practice_dashboard.dart';
import 'models/practice_session.dart';
import 'models/practice_topic.dart';
import 'models/progress_report.dart';
import 'models/session_summary.dart';
import 'models/weakness.dart';
import 'personalize_demo_data.dart';

/// Data source for the personalized-practice feature.
///
/// The backend does not exist yet, so every method resolves against
/// [PersonalizeDemoData] after a short delay that stands in for network
/// latency — this keeps the screens' loading states honest. When the API
/// lands, only this class changes: swap the delay + demo constant for a
/// `PersonalizeApi(GraphQLClient())` call, exactly like
/// `RecordingsRepository` does.
class PersonalizeRepository {
  PersonalizeRepository({Duration? latency})
      : _latency = latency ?? const Duration(milliseconds: 400);

  final Duration _latency;

  Future<T> _delayed<T>(T value) =>
      Future<T>.delayed(_latency, () => value);

  Future<PracticeDashboard> getDashboard() =>
      _delayed(PersonalizeDemoData.dashboard);

  Future<List<PracticeTopic>> getTopics(TopicFilter filter) {
    final topics = PersonalizeDemoData.topics
        .where((t) => t.buckets.contains(filter))
        .toList();
    return _delayed(topics);
  }

  /// Full topic list, unfiltered — used by the search field.
  Future<List<PracticeTopic>> searchTopics(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return _delayed(PersonalizeDemoData.topics);
    final matches = PersonalizeDemoData.topics
        .where((t) =>
            t.title.toLowerCase().contains(q) ||
            t.focusTags.any((tag) => tag.toLowerCase().contains(q)))
        .toList();
    return _delayed(matches);
  }

  /// Loads the scripted conversation for [topicId].
  ///
  /// Only the Đà Lạt script exists in the demo data; any other topic reuses it
  /// with the requested topic's title so every card leads somewhere.
  Future<PracticeSession> startSession(PracticeTopic topic) {
    final script = PersonalizeDemoData.daLatSession;
    final session = PracticeSession(
      id: 'session-${topic.id}',
      topicId: topic.id,
      topicTitle: topic.title,
      focusTags: topic.focusTags.isEmpty ? script.focusTags : topic.focusTags,
      turns: script.turns,
    );
    return _delayed(session);
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
