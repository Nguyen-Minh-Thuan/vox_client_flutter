import '../../../core/network/graphql_client.dart';
import 'models/learner_band.dart';

/// Real GraphQL calls backing [PersonalizeRepository] — topic-selection
/// queries plus saved-topics and dashboard stats (`practice-planning.graphqls`).
/// See gói 11 mục 2.6b for the field-by-field mapping this mirrors.
class PersonalizeApi {
  PersonalizeApi(this._client);

  final GraphQLClient _client;

  static const _offerFields = '''
    topicId
    name
    dimension
    savedByMe
    matchPercent
    minutes
    level
    rationale
    reasons
    focusTags
  ''';

  /// Maps to `practiceTopicOffers(excludeTopicIds, round, bucket)`.
  Future<List<Map<String, dynamic>>> getTopicOffers({
    List<String> excludeTopicIds = const [],
    int round = 1,
    String bucket = 'FOR_YOU',
  }) async {
    final data = await _client.query(
      '''
      query PracticeTopicOffers(\$excludeTopicIds: [ID!], \$round: Int, \$bucket: TopicOfferBucket) {
        practiceTopicOffers(excludeTopicIds: \$excludeTopicIds, round: \$round, bucket: \$bucket) {
          $_offerFields
        }
      }
    ''',
      variables: {
        'excludeTopicIds': excludeTopicIds,
        'round': round,
        'bucket': bucket,
      },
    );

    final offers = data['practiceTopicOffers'] as List;
    return offers.cast<Map<String, dynamic>>();
  }

  /// Maps to `mySavedTopics` — topics the learner explicitly saved.
  Future<List<Map<String, dynamic>>> getSavedTopics() async {
    final data = await _client.query('''
      query MySavedTopics {
        mySavedTopics {
          $_offerFields
        }
      }
    ''');

    final topics = data['mySavedTopics'] as List;
    return topics.cast<Map<String, dynamic>>();
  }

  /// Maps to `myPracticeDashboardStats` — `sessionsDone`/`averageScore`/`streakDays`.
  Future<Map<String, dynamic>> getDashboardStats() async {
    final data = await _client.query('''
      query MyPracticeDashboardStats {
        myPracticeDashboardStats {
          sessionsDone
          averageScore
          streakDays
        }
      }
    ''');

    return data['myPracticeDashboardStats'] as Map<String, dynamic>;
  }

  /// Maps to `searchPracticeTopics(keyword)` — full `TopicSearchResult` shape
  /// (`topics` + `canGenerate`), not just the topic list, so callers can
  /// offer "create this topic" the same way the schema intends.
  Future<({List<Map<String, dynamic>> topics, bool canGenerate})> searchTopics(
    String keyword,
  ) async {
    final data = await _client.query(
      '''
      query SearchPracticeTopics(\$keyword: String!) {
        searchPracticeTopics(keyword: \$keyword) {
          topics {
            $_offerFields
          }
          canGenerate
        }
      }
    ''',
      variables: {'keyword': keyword},
    );

    final result = data['searchPracticeTopics'] as Map<String, dynamic>;
    final topics = result['topics'] as List;
    return (
      topics: topics.cast<Map<String, dynamic>>(),
      canGenerate: result['canGenerate'] as bool? ?? false,
    );
  }

  /// Maps to `generateTopicFromKeyword(keyword)` — full `TopicFromKeywordResult`
  /// shape (`topic` + `outcome`), used when `searchTopics` comes back with
  /// `canGenerate: true` and the learner asks to create the topic.
  Future<({Map<String, dynamic>? topic, String outcome})>
  generateTopicFromKeyword(String keyword) async {
    final data = await _client.query(
      '''
      mutation GenerateTopicFromKeyword(\$keyword: String!) {
        generateTopicFromKeyword(keyword: \$keyword) {
          topic {
            $_offerFields
          }
          outcome
        }
      }
    ''',
      variables: {'keyword': keyword},
    );

    final result = data['generateTopicFromKeyword'] as Map<String, dynamic>;
    return (
      topic: result['topic'] as Map<String, dynamic>?,
      outcome: result['outcome'] as String,
    );
  }

  static const _paperQuestionFields = '''
    questionId
    slot
    questionText
    criterionCode
    subAttribute
    difficultyRank
    minResponseSeconds
    maxResponseSeconds
    suggestedIdeas
  ''';

  static const _paperDraftFields =
      '''
    draftId
    status
    reason
    paper {
      id
      topicId
      origin
      plannedSeconds
      reservedQuotaSeconds
      sessionBudgetSeconds
      questions {
        $_paperQuestionFields
      }
    }
  ''';

  /// Maps to `buildPracticePaper(input)` — builds ONLY the first MAIN question (gói 11 mục 2.2);
  /// later MAIN questions are pushed over the realtime WS during the session, not fetched here.
  ///
  /// Pha 1 của luồng 2 pha: trả về ngay `PracticePaperDraft`. `status=READY` khi kho câu hỏi đã
  /// có sẵn câu phù hợp (đường thường gặp, vài chục ms); `status=PREPARING` khi phải nhờ AI sinh
  /// câu mới (10-20s) -- lúc đó gọi tiếp [practicePaperDraft] để hỏi lại.
  Future<Map<String, dynamic>> buildPracticePaper({
    required String topicId,
    required String origin,
    String? fromSubAttribute,
    List<String>? offeredTopicIds,
    List<String>? previousOfferedTopicIds,
  }) async {
    final data = await _client.query(
      '''
      mutation BuildPracticePaper(\$input: StartPracticeSessionInput!) {
        buildPracticePaper(input: \$input) {
          $_paperDraftFields
        }
      }
    ''',
      variables: {
        'input': {
          'topicId': topicId,
          'origin': origin,
          'fromSubAttribute': fromSubAttribute,
          'offeredTopicIds': offeredTopicIds,
          'previousOfferedTopicIds': previousOfferedTopicIds,
        },
      },
    );

    return data['buildPracticePaper'] as Map<String, dynamic>;
  }

  /// Pha 2: hỏi lại kết quả dựng đề đã khởi động ở [buildPracticePaper].
  Future<Map<String, dynamic>> practicePaperDraft(String draftId) async {
    final data = await _client.query(
      '''
      query PracticePaperDraft(\$draftId: ID!) {
        practicePaperDraft(draftId: \$draftId) {
          $_paperDraftFields
        }
      }
    ''',
      variables: {'draftId': draftId},
    );

    return data['practicePaperDraft'] as Map<String, dynamic>;
  }

  static const _sessionFields = '''
    id
    paperId
    topicId
    topicName
    origin
    status
    abandonDiagnosis
    overallScore
    gradedSeconds
    startedAt
    endedAt
  ''';

  /// Maps to `startPracticeSession(paperId)` — mints the real session id, which is also the
  /// realtime WebSocket's practiceSessionId (`/realtime/practice-sessions/{id}`).
  Future<Map<String, dynamic>> startPracticeSession(String paperId) async {
    final data = await _client.query(
      '''
      mutation StartPracticeSession(\$paperId: ID!) {
        startPracticeSession(paperId: \$paperId) {
          $_sessionFields
        }
      }
    ''',
      variables: {'paperId': paperId},
    );

    return data['startPracticeSession'] as Map<String, dynamic>;
  }

  /// Maps to `endPracticeSession(input)` — called AFTER the WS practice_end/practice_end_ack
  /// handshake and socket close (gói 11 mục 2.9 điểm 2), never before.
  Future<Map<String, dynamic>> endPracticeSession({
    required String sessionId,
    required int helpRequestCount,
    required int longPauseCount,
  }) async {
    final data = await _client.query(
      '''
      mutation EndPracticeSession(\$input: EndPracticeSessionInput!) {
        endPracticeSession(input: \$input) {
          $_sessionFields
        }
      }
    ''',
      variables: {
        'input': {
          'sessionId': sessionId,
          'helpRequestCount': helpRequestCount,
          'longPauseCount': longPauseCount,
        },
      },
    );

    return data['endPracticeSession'] as Map<String, dynamic>;
  }

  /// Đã làm xong quiz sở thích chưa -- hỏi SERVER, không hỏi máy.
  ///
  /// `quiz_completed_at` là sự thật; cờ trong SharedPreferences chỉ là bộ nhớ đệm của một
  /// thiết bị. Cài lại app, đổi máy, hay xoá dữ liệu ứng dụng là cờ mất, và học sinh bị bắt
  /// làm lại một bài quiz mà server đã có -- làm lại còn ghi đè điểm sở thích đang dùng để
  /// xếp chủ đề.
  Future<bool> isInterestQuizCompleted() async {
    final data = await _client.query('''
      query MyLearnerProfile {
        myLearnerProfile {
          quizCompletedAt
        }
      }
    ''');
    final profile = data['myLearnerProfile'] as Map<String, dynamic>?;
    return (profile?['quizCompletedAt'] as String?)?.isNotEmpty ?? false;
  }

  /// Maps to `myLearnerProfile { goalType }` — current EXAM_PREP/ABILITY_IMPROVEMENT goal.
  Future<String?> getPracticeGoal() async {
    final data = await _client.query('''
      query MyLearnerProfile {
        myLearnerProfile {
          goalType
        }
      }
    ''');

    final profile = data['myLearnerProfile'] as Map<String, dynamic>?;
    return profile?['goalType'] as String?;
  }

  /// Maps to `myLearnerProfile { …band fields }` — bậc hiện tại và bậc mục tiêu.
  ///
  /// Backend đã có sẵn ba field này từ lâu (practice.graphqls:86), client chỉ chưa đọc.
  /// `estimatedFrameworkBandCode` là nullable: null nghĩa là chưa đủ 5 lượt chấm.
  Future<LearnerBand> getLearnerBand() async {
    final data = await _client.query('''
      query MyLearnerBand {
        myLearnerProfile {
          estimatedFrameworkBandCode
          targetFrameworkBandCode
          targetFrameworkBandLabel
          targetBandAttainmentPercent
        }
      }
    ''');

    final profile = data['myLearnerProfile'] as Map<String, dynamic>?;
    if (profile == null) {
      throw StateError('myLearnerProfile trả về null');
    }
    return LearnerBand.fromJson(profile);
  }

  /// Maps to `setPracticeGoal(goalType)` — goalType is `EXAM_PREP` or `ABILITY_IMPROVEMENT`.
  Future<String> setPracticeGoal(String goalType) async {
    final data = await _client.query(
      '''
      mutation SetPracticeGoal(\$goalType: PracticeGoalType!) {
        setPracticeGoal(goalType: \$goalType) {
          goalType
        }
      }
    ''',
      variables: {'goalType': goalType},
    );

    final profile = data['setPracticeGoal'] as Map<String, dynamic>;
    return profile['goalType'] as String;
  }

  /// Maps to `interestQuizItems` — forced-choice triplets for the cold-start
  /// interest inventory (AI-generated, diversified per student).
  Future<List<Map<String, dynamic>>> getInterestQuizItems() async {
    final data = await _client.query('''
      query InterestQuizItems {
        interestQuizItems {
          id
          statements
        }
      }
    ''');

    final items = data['interestQuizItems'] as List;
    return items.cast<Map<String, dynamic>>();
  }

  /// Maps to `submitInterestQuiz(input)` — scores the answers into the
  /// student's dimension_interest_score vector server-side.
  Future<Map<String, dynamic>> submitInterestQuiz(
    List<Map<String, dynamic>> answers,
  ) async {
    final data = await _client.query(
      '''
      mutation SubmitInterestQuiz(\$answers: [InterestQuizAnswerInput!]!) {
        submitInterestQuiz(input: {answers: \$answers}) {
          goalType
          quizCompletedAt
        }
      }
    ''',
      variables: {'answers': answers},
    );

    return data['submitInterestQuiz'] as Map<String, dynamic>;
  }

  /// Maps to `saveTopic(topicId)`.
  Future<void> saveTopic(String topicId) async {
    await _client.query(
      '''
      mutation SaveTopic(\$topicId: ID!) {
        saveTopic(topicId: \$topicId)
      }
    ''',
      variables: {'topicId': topicId},
    );
  }

  /// Maps to `unsaveTopic(topicId)`.
  Future<void> unsaveTopic(String topicId) async {
    await _client.query(
      '''
      mutation UnsaveTopic(\$topicId: ID!) {
        unsaveTopic(topicId: \$topicId)
      }
    ''',
      variables: {'topicId': topicId},
    );
  }

  /// Maps to `pickRandomTopic`.
  Future<Map<String, dynamic>> pickRandomTopic() async {
    final data = await _client.query('''
      mutation PickRandomTopic {
        pickRandomTopic {
          $_offerFields
        }
      }
    ''');

    return data['pickRandomTopic'] as Map<String, dynamic>;
  }

  // FLAS/self-report onboarding step removed client-side (2026-08-02, no
  // question-generation mechanism ever consumed flsaScore — see
  // onboarding_flow.dart doc comment). The `submitFlsaSelfReport` mutation
  // still exists on the backend if this needs to be re-added later.

  /// Maps to `myWeaknessProfile`.
  Future<Map<String, dynamic>> getWeaknessProfile() async {
    final data = await _client.query('''
      query MyWeaknessProfile {
        myWeaknessProfile {
          sessionsAnalysed
          nearlyFixed
          newlyFound
          criteria {
            criterionCode
            criterionName
            weakness
            observationCount
            reliable
          }
          subAttributes {
            criterionCode
            subAttribute
            occurrenceCount
            severity
            practiceable
            trendPercent
            nearlyFixed
            newlyFound
            examples { text times }
          }
        }
      }
    ''');

    return data['myWeaknessProfile'] as Map<String, dynamic>;
  }

  /// Maps to `myPracticeProgress(criterionCode, days)`.
  ///
  /// Đây là thước đo tiến bộ DUY NHẤT không co giãn theo người học: `latentLevel` =
  /// (bậc câu trả lời thực sự khớp - 1) + phần trăm điểm trong bậc đó. Điểm phiên thì neo vào
  /// bậc mục tiêu và độ khó câu hỏi lại bám theo bậc hiện tại, nên em giỏi lên thì câu khó lên
  /// và điểm đứng yên. Truy vấn này có sẵn từ lâu nhưng chưa từng có ai gọi.
  Future<List<Map<String, dynamic>>> getCriterionProgress(int days) async {
    final data = await _client.query(
      '''
      query MyPracticeProgress(\$days: Int) {
        myPracticeProgress(days: \$days) {
          criterionCode
          date
          value
          source
        }
      }
    ''',
      variables: {'days': days},
    );
    return (data['myPracticeProgress'] as List).cast<Map<String, dynamic>>();
  }

  /// Maps to `myPracticeHistory(limit)`.
  Future<List<Map<String, dynamic>>> getPracticeHistory(int limit) async {
    final data = await _client.query(
      '''
      query MyPracticeHistory(\$limit: Int) {
        myPracticeHistory(limit: \$limit) {
          $_sessionFields
        }
      }
    ''',
      variables: {'limit': limit},
    );

    final sessions = data['myPracticeHistory'] as List;
    return sessions.cast<Map<String, dynamic>>();
  }

  /// Bai cua CHINH HOC SINH dang dang nhap -- KHONG phai studentPracticeSessionDetail,
  /// cai do la endpoint cua giao vien (@PreAuthorize hasRole('TEACHER')) nen goi vao se
  /// dinh Access Denied ngay khi hoc sinh bam "Hoan tat".
  Future<Map<String, dynamic>> getPracticeSessionDetail(
    String sessionId,
  ) async {
    final data = await _client.query(
      '''
      query MyPracticeSessionDetail(\$sessionId: ID!) {
        myPracticeSessionDetail(sessionId: \$sessionId) {
          sessionId
          topicName
          startedAt
          durationSeconds
          itemCount
          overallScore
          completed
          pendingEvaluationCount
          difficultyRank
          criterionScores { criterionCode score matchedBandCode }
          turns {
            turnOrder transcript audioUrl wordFeedbackJson turnScore
            corrections { category originalText correctedText explanation correctAudioUrl }
          }
        }
      }
    ''',
      variables: {'sessionId': sessionId},
    );
    return data['myPracticeSessionDetail'] as Map<String, dynamic>;
  }

  /// Maps to `myInterestProfile` — `topics` (real score/sessionsMentioned/lastMentionedAt)
  /// plus `suggestions` (AI-suggested topics, status PENDING become the "discovered" cards).
  Future<Map<String, dynamic>> getInterestProfile() async {
    final data = await _client.query('''
      query MyInterestProfile {
        myInterestProfile {
          topics {
            topicId
            name
            score
            sessionsMentioned
            lastMentionedAt
          }
          suggestions {
            id
            suggestedTopicName
            interestDimension
            confidence
            reasonText
            status
          }
        }
      }
    ''');

    return data['myInterestProfile'] as Map<String, dynamic>;
  }

  /// Maps to `respondToTopicSuggestion(suggestionId, accept)`.
  Future<void> respondToTopicSuggestion(
    String suggestionId,
    bool accept,
  ) async {
    await _client.query(
      '''
      mutation RespondToTopicSuggestion(\$suggestionId: ID!, \$accept: Boolean!) {
        respondToTopicSuggestion(suggestionId: \$suggestionId, accept: \$accept)
      }
    ''',
      variables: {'suggestionId': suggestionId, 'accept': accept},
    );
  }

  /// Maps to `setInterestAutoUpdate(enabled)`.
  Future<bool> setInterestAutoUpdate(bool enabled) async {
    final data = await _client.query(
      '''
      mutation SetInterestAutoUpdate(\$enabled: Boolean!) {
        setInterestAutoUpdate(enabled: \$enabled) {
          interestAutoUpdateEnabled
        }
      }
    ''',
      variables: {'enabled': enabled},
    );

    final profile = data['setInterestAutoUpdate'] as Map<String, dynamic>;
    return profile['interestAutoUpdateEnabled'] as bool;
  }

  /// Maps to `myLearnerProfile { interestAutoUpdateEnabled }`.
  Future<bool> getInterestAutoUpdateEnabled() async {
    final data = await _client.query('''
      query MyLearnerProfileAutoUpdate {
        myLearnerProfile {
          interestAutoUpdateEnabled
        }
      }
    ''');

    final profile = data['myLearnerProfile'] as Map<String, dynamic>?;
    return profile?['interestAutoUpdateEnabled'] as bool? ?? true;
  }
}
