import '../../../core/network/graphql_client.dart';

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
    final data = await _client.query('''
      query PracticeTopicOffers(\$excludeTopicIds: [ID!], \$round: Int, \$bucket: TopicOfferBucket) {
        practiceTopicOffers(excludeTopicIds: \$excludeTopicIds, round: \$round, bucket: \$bucket) {
          $_offerFields
        }
      }
    ''', variables: {
      'excludeTopicIds': excludeTopicIds,
      'round': round,
      'bucket': bucket,
    });

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
    final data = await _client.query('''
      query SearchPracticeTopics(\$keyword: String!) {
        searchPracticeTopics(keyword: \$keyword) {
          topics {
            $_offerFields
          }
          canGenerate
        }
      }
    ''', variables: {'keyword': keyword});

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
  Future<({Map<String, dynamic>? topic, String outcome})> generateTopicFromKeyword(
    String keyword,
  ) async {
    final data = await _client.query('''
      mutation GenerateTopicFromKeyword(\$keyword: String!) {
        generateTopicFromKeyword(keyword: \$keyword) {
          topic {
            $_offerFields
          }
          outcome
        }
      }
    ''', variables: {'keyword': keyword});

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
    preparationTimeSeconds
    maxResponseSeconds
    maxFollowupSeconds
    suggestedIdeas
  ''';

  /// Maps to `buildPracticePaper(input)` — builds ONLY the first MAIN question (gói 11 mục 2.2);
  /// later MAIN questions are pushed over the realtime WS during the session, not fetched here.
  Future<Map<String, dynamic>> buildPracticePaper({
    required String topicId,
    required String origin,
    String? fromSubAttribute,
    List<String>? offeredTopicIds,
    List<String>? previousOfferedTopicIds,
  }) async {
    final data = await _client.query('''
      mutation BuildPracticePaper(\$input: StartPracticeSessionInput!) {
        buildPracticePaper(input: \$input) {
          id
          topicId
          origin
          plannedSeconds
          reservedQuotaSeconds
          questions {
            $_paperQuestionFields
          }
        }
      }
    ''', variables: {
      'input': {
        'topicId': topicId,
        'origin': origin,
        'fromSubAttribute': fromSubAttribute,
        'offeredTopicIds': offeredTopicIds,
        'previousOfferedTopicIds': previousOfferedTopicIds,
      },
    });

    return data['buildPracticePaper'] as Map<String, dynamic>;
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
    final data = await _client.query('''
      mutation StartPracticeSession(\$paperId: ID!) {
        startPracticeSession(paperId: \$paperId) {
          $_sessionFields
        }
      }
    ''', variables: {'paperId': paperId});

    return data['startPracticeSession'] as Map<String, dynamic>;
  }

  /// Maps to `endPracticeSession(input)` — called AFTER the WS practice_end/practice_end_ack
  /// handshake and socket close (gói 11 mục 2.9 điểm 2), never before.
  Future<Map<String, dynamic>> endPracticeSession({
    required String sessionId,
    required int helpRequestCount,
    required int longPauseCount,
  }) async {
    final data = await _client.query('''
      mutation EndPracticeSession(\$input: EndPracticeSessionInput!) {
        endPracticeSession(input: \$input) {
          $_sessionFields
        }
      }
    ''', variables: {
      'input': {
        'sessionId': sessionId,
        'helpRequestCount': helpRequestCount,
        'longPauseCount': longPauseCount,
      },
    });

    return data['endPracticeSession'] as Map<String, dynamic>;
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

  /// Maps to `setPracticeGoal(goalType)` — goalType is `EXAM_PREP` or `ABILITY_IMPROVEMENT`.
  Future<String> setPracticeGoal(String goalType) async {
    final data = await _client.query('''
      mutation SetPracticeGoal(\$goalType: PracticeGoalType!) {
        setPracticeGoal(goalType: \$goalType) {
          goalType
        }
      }
    ''', variables: {'goalType': goalType});

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
    final data = await _client.query('''
      mutation SubmitInterestQuiz(\$answers: [InterestQuizAnswerInput!]!) {
        submitInterestQuiz(input: {answers: \$answers}) {
          goalType
          quizCompletedAt
        }
      }
    ''', variables: {'answers': answers});

    return data['submitInterestQuiz'] as Map<String, dynamic>;
  }

  /// Maps to `saveTopic(topicId)`.
  Future<void> saveTopic(String topicId) async {
    await _client.query('''
      mutation SaveTopic(\$topicId: ID!) {
        saveTopic(topicId: \$topicId)
      }
    ''', variables: {'topicId': topicId});
  }

  /// Maps to `unsaveTopic(topicId)`.
  Future<void> unsaveTopic(String topicId) async {
    await _client.query('''
      mutation UnsaveTopic(\$topicId: ID!) {
        unsaveTopic(topicId: \$topicId)
      }
    ''', variables: {'topicId': topicId});
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

  /// Maps to `submitFlsaSelfReport(answers)` — exactly 3-4 Likert(1-5) answers.
  Future<Map<String, dynamic>> submitFlsaSelfReport(List<int> answers) async {
    final data = await _client.query('''
      mutation SubmitFlsaSelfReport(\$answers: [Int!]!) {
        submitFlsaSelfReport(answers: \$answers) {
          flsaScore
        }
      }
    ''', variables: {'answers': answers});

    return data['submitFlsaSelfReport'] as Map<String, dynamic>;
  }

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
          }
        }
      }
    ''');

    return data['myWeaknessProfile'] as Map<String, dynamic>;
  }

  /// Maps to `myPracticeHistory(limit)`.
  Future<List<Map<String, dynamic>>> getPracticeHistory(int limit) async {
    final data = await _client.query('''
      query MyPracticeHistory(\$limit: Int) {
        myPracticeHistory(limit: \$limit) {
          $_sessionFields
        }
      }
    ''', variables: {'limit': limit});

    final sessions = data['myPracticeHistory'] as List;
    return sessions.cast<Map<String, dynamic>>();
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
  Future<void> respondToTopicSuggestion(String suggestionId, bool accept) async {
    await _client.query('''
      mutation RespondToTopicSuggestion(\$suggestionId: ID!, \$accept: Boolean!) {
        respondToTopicSuggestion(suggestionId: \$suggestionId, accept: \$accept)
      }
    ''', variables: {'suggestionId': suggestionId, 'accept': accept});
  }

  /// Maps to `setInterestAutoUpdate(enabled)`.
  Future<bool> setInterestAutoUpdate(bool enabled) async {
    final data = await _client.query('''
      mutation SetInterestAutoUpdate(\$enabled: Boolean!) {
        setInterestAutoUpdate(enabled: \$enabled) {
          interestAutoUpdateEnabled
        }
      }
    ''', variables: {'enabled': enabled});

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
