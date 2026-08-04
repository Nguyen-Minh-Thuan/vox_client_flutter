import 'dart:convert';

import '../../../core/network/graphql_client.dart';
import '../../profile/data/profile_api.dart';
import 'models/interest.dart';
import 'models/learner_band.dart';
import 'models/onboarding_question.dart';
import 'models/practice_dashboard.dart';
import 'models/practice_history_entry.dart';
import 'models/practice_session.dart';
import 'models/practice_topic.dart';
import 'models/criterion_band_trend.dart';
import 'models/progress_report.dart';
import 'models/session_summary.dart';
import 'models/weakness.dart';
import 'personalize_api.dart';

/// Data source for the personalized-practice feature.
///
/// Every method here is either a real GraphQL call or a documented
/// client-side aggregation of a few real calls (`getDashboard`/`getProgress`)
/// — see each method's doc comment.
class PersonalizeRepository {
  PersonalizeRepository({PersonalizeApi? api, ProfileApi? profileApi})
    : _api = api ?? PersonalizeApi(GraphQLClient()),
      _profileApi = profileApi ?? ProfileApi(GraphQLClient());

  final PersonalizeApi _api;
  final ProfileApi _profileApi;

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
    final startOfWeek = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final sessionsThisWeek = history
        .where(
          (e) => e.startedAt != null && !e.startedAt!.isBefore(startOfWeek),
        )
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
  /// Lối C -- học sinh tự gõ từ khoá, tín hiệu mạnh nhất (1.00) nên gắn `KEYWORD`.
  Future<PracticeTopic?> generateTopicFromKeyword(String keyword) async {
    final result = await _api.generateTopicFromKeyword(keyword);
    if (result.topic == null) return null;
    return PracticeTopic.fromOffer(result.topic!, origin: 'KEYWORD');
  }

  /// Bao lâu thì hỏi lại kết quả dựng đề, và bỏ cuộc sau bao lâu. Dựng đề chậm là khi phải
  /// nhờ AI sinh câu mới; pipeline fast bên Python thường xong trong ~5-8s nên 45s là dư
  /// nhưng vẫn đủ ngắn để không treo học sinh vô hạn nếu có sự cố.
  static const _draftPollInterval = Duration(seconds: 2);
  static const _draftTimeout = Duration(seconds: 45);

  /// Builds the first MAIN question + starts a real practice session (gói 11 mục 2.2/2.7b):
  /// `buildPracticePaper` -> `startPracticeSession`. `session.id` is also the realtime
  /// WebSocket's practiceSessionId; `firstQuestion` is the raw `PracticePaperQuestion` JSON,
  /// handed back so the caller can send it as the WS `question_start` payload.
  ///
  /// `buildPracticePaper` giờ là 2 pha (xem `PracticePaperDraft` phía backend): trả về ngay,
  /// nếu còn PREPARING thì hỏi lại cho tới khi READY/FAILED. [onPreparing] được gọi khi phải
  /// chờ, để UI hiện trạng thái "đang chuẩn bị" thay vì đứng im.
  /// `budgetSeconds` là trần NÓI của cả phiên — nền cho thanh tiến độ "đã nói / ngân sách".
  /// Lấy từ đề vì lượt đầu chưa nộp nên chưa có kết quả nộp lượt nào để lấy con số này ra.
  Future<
    ({
      PracticeSession session,
      Map<String, dynamic> firstQuestion,
      int budgetSeconds,
    })
  >
  startSession(PracticeTopic topic, {void Function()? onPreparing}) async {
    final paper = await _buildPaper(topic, onPreparing: onPreparing);
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
    return (
      session: session,
      firstQuestion: firstQuestion,
      budgetSeconds: (paper['sessionBudgetSeconds'] as int?) ?? 0,
    );
  }

  /// Chạy luồng dựng đề 2 pha tới khi có đề thật, ném lỗi đọc được nếu backend báo FAILED.
  Future<Map<String, dynamic>> _buildPaper(
    PracticeTopic topic, {
    void Function()? onPreparing,
  }) async {
    // origin đi theo chủ đề (xem PracticeTopic.origin), KHÔNG cứng 'SELECTED': chủ đề do hệ
    // thống bấm hộ ("chọn giúp tôi") mà ghi như học sinh tự chọn là dương giả.
    var draft = await _api.buildPracticePaper(
      topicId: topic.id,
      origin: topic.origin,
    );
    if (draft['status'] == 'READY') {
      return draft['paper'] as Map<String, dynamic>;
    }
    if (draft['status'] == 'FAILED') {
      throw Exception(draft['reason'] ?? 'Không dựng được đề luyện.');
    }

    onPreparing?.call();
    final draftId = draft['draftId'] as String;
    final deadline = DateTime.now().add(_draftTimeout);
    while (DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(_draftPollInterval);
      draft = await _api.practicePaperDraft(draftId);
      if (draft['status'] == 'READY') {
        return draft['paper'] as Map<String, dynamic>;
      }
      if (draft['status'] == 'FAILED') {
        throw Exception(draft['reason'] ?? 'Không dựng được đề luyện.');
      }
    }
    throw Exception('Chuẩn bị câu hỏi lâu hơn dự kiến, vui lòng thử lại.');
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
  Future<String> setPracticeGoal(String goalType) =>
      _api.setPracticeGoal(goalType);

  /// Bậc hiện tại + bậc mục tiêu theo khung của trường.
  ///
  /// `estimatedCode` là null cho tới khi có đủ 5 lượt chấm (thi hoặc luyện) — KHÔNG lấy
  /// bậc mục tiêu ra thế chỗ, vì mục tiêu của trường không phải trình độ của học sinh.
  Future<LearnerBand> getLearnerBand() => _api.getLearnerBand();

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
    final historyRows =
        (results[1] as List<Map<String, dynamic>>)
            .map(PracticeHistoryEntry.fromJson)
            .toList()
          ..sort(
            (a, b) => (a.startedAt ?? DateTime.fromMillisecondsSinceEpoch(0))
                .compareTo(
                  b.startedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
                ),
          );
    final currentIndex = historyRows.indexWhere(
      (entry) => entry.id == sessionId,
    );
    final currentScore = (detail['overallScore'] as num?)?.toDouble() ?? 0;
    final previousScore = currentIndex > 0
        ? historyRows[currentIndex - 1].overallScore
        : null;

    // Giữ NGUYÊN VĂN lỗi, không chỉ đếm: xem chú thích RepeatedError.examples.
    final correctionsByCategory = <String, List<SessionCorrection>>{};
    final mispronounced = <String, MispronouncedWord>{};
    for (final turn in (detail['turns'] as List? ?? const [])) {
      final turnMap = turn as Map<String, dynamic>;
      for (final correction in (turnMap['corrections'] as List? ?? const [])) {
        final row = SessionCorrection.fromJson(
          correction as Map<String, dynamic>,
        );
        if (row.category.isEmpty) continue;
        correctionsByCategory
            .putIfAbsent(row.category, () => <SessionCorrection>[])
            .add(row);
      }
      _collectMispronounced(
        turnMap['wordFeedbackJson'] as String?,
        mispronounced,
      );
    }
    final mispronouncedRows = mispronounced.values.toList()
      ..sort((a, b) => a.accuracy.compareTo(b.accuracy));

    return SessionSummary(
      sessionId: detail['sessionId'] as String,
      topicTitle: detail['topicName'] as String? ?? '',
      minutes: ((detail['durationSeconds'] as num?)?.toInt() ?? 0) ~/ 60,
      score: currentScore,
      delta: previousScore == null ? null : currentScore - previousScore,
      // GỘP theo tiêu chí. `criterionScores` trả về một dòng cho mỗi (bài chấm × tiêu chí),
      // nên buổi có 2 câu đã chấm sẽ ra 10 dòng và màn hình hiện "Ngữ pháp" hai lần với hai
      // điểm khác nhau -- trong khi nhãn thẻ ghi "5 tiêu chí". Trung bình cộng các câu, cùng
      // cách overall_score được tính (AVG item_score).
      rubric: _averageByCriterion(detail['criterionScores'] as List?),
      repeatedErrors:
          correctionsByCategory.entries
              .map(
                (entry) => RepeatedError(
                  label: _criterionLabel(entry.key),
                  count: entry.value.length,
                  // Bỏ những dòng không có cả câu gốc lẫn câu sửa -- chúng không nói được
                  // "sai ở đâu", để lại chỉ làm loãng thẻ.
                  examples: entry.value
                      .where(
                        (c) =>
                            c.originalText.isNotEmpty ||
                            c.correctedText.isNotEmpty,
                      )
                      .toList(),
                ),
              )
              .toList()
            ..sort((a, b) => b.count.compareTo(a.count)),
      mispronounced: mispronouncedRows,
      pendingEvaluations:
          (detail['pendingEvaluationCount'] as num?)?.toInt() ?? 0,
      difficultyRank: (detail['difficultyRank'] as num?)?.toDouble(),
    );
  }

  /// Trung bình điểm theo từng tiêu chí trên cả buổi, giữ thứ tự gặp đầu tiên.
  static List<SessionRubricCriterion> _averageByCriterion(List? rows) {
    final sums = <String, double>{};
    final counts = <String, int>{};
    for (final row in rows ?? const []) {
      final map = row as Map<String, dynamic>;
      final code = (map['criterionCode'] as String? ?? '').trim();
      if (code.isEmpty) continue;
      sums[code] = (sums[code] ?? 0) + ((map['score'] as num?)?.toDouble() ?? 0);
      counts[code] = (counts[code] ?? 0) + 1;
    }
    return sums.entries
        .map(
          (entry) => SessionRubricCriterion(
            label: _criterionLabel(entry.key),
            score: entry.value / counts[entry.key]!,
          ),
        )
        .toList();
  }

  /// Bóc từ phát âm chưa đạt ra khỏi `wordFeedbackJson` của một lượt, gộp theo TỪ vào [into].
  ///
  /// JSON này là `pronunciation_result` do PronunciationNode bên Python ghi lúc học sinh nói,
  /// đã lưu sẵn ở `practice_response_turn.word_feedback_json` và GraphQL đã trả về cùng mỗi
  /// lượt — trước đây màn tổng kết tải về rồi bỏ không dùng.
  ///
  /// Cùng một từ sai ở nhiều lượt thì giữ lần TỆ NHẤT và đếm số lần: học sinh cần biết mình
  /// hay vấp từ nào, không phải xem cùng một từ liệt kê lặp ba dòng.
  static void _collectMispronounced(
    String? json,
    Map<String, MispronouncedWord> into,
  ) {
    if (json == null || json.trim().isEmpty) return;
    final Object? decoded;
    try {
      decoded = jsonDecode(json);
    } on FormatException {
      return;
    }
    if (decoded is! Map<String, dynamic>) return;
    for (final entry in (decoded['words'] as List? ?? const [])) {
      if (entry is! Map<String, dynamic>) continue;
      final word = (entry['word'] as String? ?? '').trim();
      final accuracy = (entry['accuracy_score'] as num?)?.toDouble();
      if (word.isEmpty ||
          accuracy == null ||
          accuracy >= _weakPronunciationScore) {
        continue;
      }

      // Âm vị kém nhất trong từ — "sai ở chỗ nào".
      String? worstPhoneme;
      double? worstAccuracy;
      for (final item in (entry['phonemes'] as List? ?? const [])) {
        if (item is! Map<String, dynamic>) continue;
        final value = (item['accuracy_score'] as num?)?.toDouble();
        if (value == null) continue;
        if (worstAccuracy == null || value < worstAccuracy) {
          worstAccuracy = value;
          worstPhoneme = item['phoneme'] as String?;
        }
      }

      final key = word.toLowerCase();
      final seen = into[key];
      if (seen == null) {
        into[key] = MispronouncedWord(
          word: word,
          accuracy: accuracy,
          worstPhoneme: worstPhoneme,
          worstPhonemeAccuracy: worstAccuracy,
        );
      } else {
        into[key] = MispronouncedWord(
          word: seen.word,
          accuracy: accuracy < seen.accuracy ? accuracy : seen.accuracy,
          worstPhoneme: accuracy < seen.accuracy
              ? worstPhoneme
              : seen.worstPhoneme,
          worstPhonemeAccuracy: accuracy < seen.accuracy
              ? worstAccuracy
              : seen.worstPhonemeAccuracy,
          times: seen.times + 1,
        );
      }
    }
  }

  /// Cùng ngưỡng với `_PRONUNCIATION_WEAK_THRESHOLD` của realtimeCorrectionGraph — thẻ sửa
  /// lúc đang nói và bản tổng kết cuối buổi phải coi cùng một từ là "chưa đạt", không thì
  /// học sinh thấy một từ bị bắt lỗi lúc nói rồi biến mất khỏi tổng kết.
  static const double _weakPronunciationScore = 70.0;

  static String _criterionLabel(String code) {
    switch (code.trim().toUpperCase()) {
      case 'GRAMMAR':
        return 'Ngữ pháp';
      case 'VOCABULARY':
        return 'Từ vựng';
      case 'COHERENCE':
        return 'Mạch lạc';
      case 'FLUENCY':
        return 'Độ trôi chảy';
      case 'PRONUNCIATION':
        return 'Phát âm';
      default:
        if (code.isEmpty) return 'Khác';
        return code
            .replaceAll('_', ' ')
            .toLowerCase()
            .split(' ')
            .map(
              (part) => part.isEmpty
                  ? part
                  : '${part[0].toUpperCase()}${part.substring(1)}',
            )
            .join(' ');
    }
  }

  /// Maps to `myWeaknessProfile` — real, not `PersonalizeDemoData`.
  Future<WeaknessProfile> getWeaknessProfile() async {
    final json = await _api.getWeaknessProfile();
    return WeaknessProfile.fromJson(json);
  }

  /// Maps to `saveTopic(topicId)`.
  Future<void> saveTopic(String topicId) => _api.saveTopic(topicId);

  /// Maps to `unsaveTopic(topicId)`.
  Future<void> unsaveTopic(String topicId) => _api.unsaveTopic(topicId);

  /// Maps to `pickRandomTopic` — lối B "chọn giúp tôi". Gắn `EXPLORATION` để tín hiệu sở
  /// thích ghi 0.60 thay vì 0.95: hệ thống chọn hộ thì không phải học sinh thích chủ đề đó.
  Future<PracticeTopic> pickRandomTopic() async {
    final json = await _api.pickRandomTopic();
    return PracticeTopic.fromOffer(json, origin: 'EXPLORATION');
  }

  /// Maps to `myPracticeHistory(limit)`.
  Future<List<PracticeHistoryEntry>> getPracticeHistory({
    int limit = 20,
  }) async {
    final rows = await _api.getPracticeHistory(limit);
    return rows.map(PracticeHistoryEntry.fromJson).toList();
  }

  /// Builds a [ProgressReport] from real `myPracticeHistory` rows -- see
  /// `ProgressReport.fromHistory` for why this isn't `myPracticeProgress`.
  /// Fetches enough history to cover 2x the widest range (`all`) so the
  /// delta comparison always has a real previous period to diff against.
  /// Server có ghi nhận đã làm xong quiz sở thích không -- xem [PersonalizeApi].
  Future<bool> isInterestQuizCompleted() => _api.isInterestQuizCompleted();

  Future<ProgressReport> getProgress(ProgressRange range) async {
    final entries = await getPracticeHistory(limit: 200);
    return ProgressReport.fromHistory(entries, range);
  }

  /// Diễn biến BẬC theo từng tiêu chí — xem [CriterionBandTrend] để biết vì sao cần nó bên
  /// cạnh điểm phiên.
  Future<List<CriterionBandTrend>> getCriterionBandTrends(
    ProgressRange range,
  ) async {
    final rows = await _api.getCriterionProgress(range.days);
    return CriterionBandTrend.fromPoints(rows);
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
  Future<bool> getInterestAutoUpdateEnabled() =>
      _api.getInterestAutoUpdateEnabled();

  /// Maps to `setInterestAutoUpdate(enabled)` -- returns the value actually
  /// persisted.
  Future<bool> setInterestAutoUpdate(bool enabled) =>
      _api.setInterestAutoUpdate(enabled);
}
