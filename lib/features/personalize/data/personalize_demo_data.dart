import 'models/interest.dart';
import 'models/learner_profile.dart';
import 'models/onboarding_question.dart';
import 'models/practice_dashboard.dart';
import 'models/practice_session.dart';
import 'models/practice_topic.dart';
import 'models/progress_report.dart';
import 'models/session_summary.dart';
import 'models/weakness.dart';

/// Hand-written stand-in for the personalized-practice backend.
///
/// The content mirrors the design doc verbatim so the built screens can be
/// compared against the mockups. Everything here is replaced by real API calls
/// once the backend lands — see [PersonalizeRepository], the only consumer.
///
/// Note the copy is Vietnamese-only on purpose: these are *content* strings
/// (topic titles, transcripts, AI feedback) that the backend will own. UI
/// chrome — labels, captions, buttons — goes through `AppLocalizations`.
abstract final class PersonalizeDemoData {
  // ── Topics ────────────────────────────────────────────────────────────────

  static const topFootballTopic = PracticeTopic(
    id: 'topic-football-match',
    title: 'Trận đấu đáng nhớ nhất bạn từng xem',
    rationale: 'Bạn nhắc tới bóng đá trong 5/8 buổi gần đây, và chủ đề này ép '
        'bạn dùng thì quá khứ liên tục.',
    minutes: 6,
    level: TopicLevel.intermediate,
    matchPercent: 94,
    reasons: ['Vì bạn thích bóng đá'],
    focusTags: ['Thì quá khứ'],
    icon: 'sports_soccer',
    buckets: {TopicFilter.forYou, TopicFilter.byWeakness},
  );

  static const daLatTopic = PracticeTopic(
    id: 'topic-da-lat',
    title: 'Kể lại chuyến đi Đà Lạt của bạn',
    minutes: 8,
    level: TopicLevel.intermediate,
    reasons: ['Vì bạn thích du lịch'],
    focusTags: ['Thì quá khứ', 'Âm cuối /s/'],
    icon: 'flight_takeoff',
    buckets: {TopicFilter.forYou, TopicFilter.byWeakness},
  );

  static const topics = <PracticeTopic>[
    topFootballTopic,
    PracticeTopic(
      id: 'topic-trip-changed-mind',
      title: 'Chuyến đi khiến bạn thay đổi cách nghĩ',
      minutes: 7,
      level: TopicLevel.intermediate,
      reasons: ['Vì bạn thích du lịch'],
      icon: 'flight_takeoff',
      buckets: {TopicFilter.forYou, TopicFilter.saved},
    ),
    PracticeTopic(
      id: 'topic-ai-grading',
      title: 'AI có nên chấm bài thay giáo viên?',
      minutes: 8,
      level: TopicLevel.advanced,
      reasons: ['Dạng IELTS Part 3', 'Công nghệ'],
      focusTags: ['Nêu quan điểm'],
      icon: 'smart_toy',
      buckets: {TopicFilter.forYou, TopicFilter.byGoal},
    ),
    PracticeTopic(
      id: 'topic-favourite-dish',
      title: 'Món ăn bạn có thể nấu cho người khác',
      minutes: 5,
      level: TopicLevel.beginner,
      reasons: ['Vì bạn hay nhắc tới ẩm thực'],
      icon: 'restaurant',
      buckets: {TopicFilter.forYou},
    ),
    PracticeTopic(
      id: 'topic-describe-hometown',
      title: 'Mô tả quê hương bạn cho một người bạn nước ngoài',
      minutes: 6,
      level: TopicLevel.beginner,
      reasons: ['Dạng IELTS Part 2'],
      focusTags: ['Danh từ số nhiều'],
      icon: 'location_city',
      buckets: {TopicFilter.byGoal, TopicFilter.byWeakness},
    ),
    PracticeTopic(
      id: 'topic-new-tech',
      title: 'Một công nghệ đã thay đổi cách bạn học',
      minutes: 7,
      level: TopicLevel.intermediate,
      reasons: ['Vì bạn thích công nghệ'],
      icon: 'devices',
      buckets: {TopicFilter.byGoal, TopicFilter.saved},
    ),
  ];

  // ── Home dashboard ────────────────────────────────────────────────────────

  static const dashboard = PracticeDashboard(
    learnerName: 'Minh Anh',
    streakDays: 12,
    todayTopic: daLatTopic,
    sessionsDone: 24,
    averageScore: 7.8,
    weeklyGoalDone: 4,
    weeklyGoalTarget: 5,
    weeklyFocus: [
      Weakness(
        id: 'weak-past-simple',
        category: WeaknessCategory.grammar,
        title: 'Thì quá khứ đơn',
        severity: WeaknessSeverity.severe,
        detail: '9 lỗi',
        ratio: 0.45,
        deltaLabel: '9 lỗi',
      ),
      Weakness(
        id: 'weak-final-s',
        category: WeaknessCategory.pronunciation,
        title: 'Âm cuối /s/, /z/',
        severity: WeaknessSeverity.improving,
        detail: '↑ 18%',
        ratio: 0.72,
        deltaLabel: '↑ 18%',
        deltaIsPositive: true,
      ),
    ],
    suggestions: [topFootballTopic],
  );

  // ── Live session script ───────────────────────────────────────────────────

  /// The scripted Đà Lạt conversation from mockup `1c`.
  ///
  /// Turn 0 is revealed immediately; every student turn (and the AI follow-up
  /// after it) is appended when the learner finishes a recording.
  static const daLatSession = PracticeSession(
    id: 'session-da-lat',
    topicId: 'topic-da-lat',
    topicTitle: 'Chuyến đi Đà Lạt',
    focusTags: ['Thì quá khứ'],
    turns: [
      PracticeTurn(
        id: 'turn-1',
        turnOrder: 1,
        speaker: Speaker.ai,
        text: 'So — where did you go last weekend, and who was with you?',
      ),
      PracticeTurn(
        id: 'turn-2',
        turnOrder: 2,
        speaker: Speaker.student,
        text: 'I go to Da Lat with my family. We stay there three day '
            'and the weather was very nice.',
        score: 7.5,
        spans: [
          // "go"
          ErrorSpan(start: 2, length: 2, type: CorrectionType.grammar),
          // "three day"
          ErrorSpan(start: 45, length: 9, type: CorrectionType.grammar),
          // "very nice"
          ErrorSpan(start: 75, length: 9, type: CorrectionType.vocabulary),
        ],
        corrections: [
          Correction(
            type: CorrectionType.grammar,
            before: 'I go',
            after: 'I went',
            note: 'Chuyện đã xảy ra cuối tuần rồi → thì quá khứ đơn.',
            repeatCount: 9,
          ),
          Correction(
            type: CorrectionType.grammar,
            before: 'three day',
            after: 'three days',
            note: 'Danh từ đếm được số nhiều.',
          ),
          Correction(
            type: CorrectionType.vocabulary,
            before: 'very nice',
            after: 'breathtaking',
            note: 'Nói tự nhiên hơn: “the weather was breathtaking”.',
          ),
        ],
      ),
      PracticeTurn(
        id: 'turn-3',
        turnOrder: 3,
        speaker: Speaker.ai,
        text: 'Nice! What did you do on the second day?',
      ),
      PracticeTurn(
        id: 'turn-4',
        turnOrder: 4,
        speaker: Speaker.student,
        text: 'We visited the flower garden and… ưm… we take many photo.',
        score: 8.2,
        spans: [
          // "visited"
          ErrorSpan(start: 3, length: 7, type: CorrectionType.grammar),
          // "we take many photo"
          ErrorSpan(start: 39, length: 18, type: CorrectionType.fluency),
        ],
        corrections: [
          Correction(
            type: CorrectionType.grammar,
            before: 'we take many photo',
            after: 'we took a lot of photos',
            note: 'Lại là thì quá khứ + số nhiều — hai lỗi cũ đi cùng nhau.',
          ),
          Correction(
            type: CorrectionType.fluency,
            headline: 'Ngập ngừng 2.4 giây trước “we take”',
            note: 'Thử cụm nối: “and then…” để giữ nhịp.',
          ),
        ],
      ),
      PracticeTurn(
        id: 'turn-5',
        turnOrder: 5,
        speaker: Speaker.ai,
        text: 'Would you go back to Da Lat again? Why, or why not?',
      ),
      PracticeTurn(
        id: 'turn-6',
        turnOrder: 6,
        speaker: Speaker.student,
        text: 'Yes, I would love to come back because the food there was '
            'amazing and the people were friendly.',
        score: 8.6,
        corrections: [
          Correction(
            type: CorrectionType.vocabulary,
            headline: 'Tiến bộ: cả câu đúng thì quá khứ ✓',
            note: 'Lần đầu bạn tự dùng đúng quá khứ mà không cần nhắc.',
          ),
        ],
      ),
    ],
  );

  // ── Post-session ──────────────────────────────────────────────────────────

  static const sessionSummary = SessionSummary(
    sessionId: 'session-da-lat',
    topicTitle: 'Chuyến đi Đà Lạt',
    minutes: 8,
    score: 8.1,
    delta: 0.4,
    drillMinutes: 4,
    rubric: [
      RubricCriterion(label: 'Đáp ứng yêu cầu', weight: 25, score: 8.0),
      RubricCriterion(label: 'Trôi chảy & mạch lạc', weight: 20, score: 8.4),
      RubricCriterion(label: 'Từ vựng', weight: 20, score: 8.5),
      RubricCriterion(label: 'Ngữ pháp', weight: 20, score: 7.2),
      RubricCriterion(label: 'Phát âm', weight: 15, score: 7.8),
    ],
    repeatedErrors: [
      RepeatedError(
        label: 'Thì quá khứ đơn',
        count: 4,
        trend: ErrorTrend.topWeakness,
        trendLabel: 'Điểm yếu #1',
      ),
      RepeatedError(
        label: 'Danh từ số nhiều',
        count: 3,
        trend: ErrorTrend.newlySeen,
        trendLabel: 'Mới xuất hiện',
      ),
      RepeatedError(
        label: 'Ngập ngừng > 2 giây',
        count: 2,
        trend: ErrorTrend.improving,
        trendLabel: '↓ giảm 30%',
      ),
    ],
  );

  static const weaknessProfile = WeaknessProfile(
    sessionsAnalysed: 24,
    tracked: 6,
    nearlyFixed: 2,
    newlyFound: 1,
    weaknesses: [
      Weakness(
        id: 'weak-past-simple',
        category: WeaknessCategory.grammar,
        title: 'Thì quá khứ đơn',
        severity: WeaknessSeverity.severe,
        detail: '9 lần · trong 5/8 buổi gần đây',
        ratio: 0.82,
        deltaLabel: '↑ 12%',
      ),
      Weakness(
        id: 'weak-plural-nouns',
        category: WeaknessCategory.grammar,
        title: 'Danh từ đếm được số nhiều',
        severity: WeaknessSeverity.isNew,
        detail: '3 lần · buổi hôm nay',
        ratio: 0.38,
      ),
      Weakness(
        id: 'weak-final-s',
        category: WeaknessCategory.pronunciation,
        title: 'Âm cuối /s/, /z/',
        severity: WeaknessSeverity.improving,
        detail: 'Chính xác 58% → 76% trong 3 tuần',
        ratio: 0.76,
        deltaLabel: '↑ 18%',
        deltaIsPositive: true,
      ),
      Weakness(
        id: 'weak-word-repetition',
        category: WeaknessCategory.expression,
        title: 'Lặp từ “very”, “good”',
        severity: WeaknessSeverity.mild,
        detail: '14 lần · gợi ý 6 từ thay thế',
        ratio: 0.5,
      ),
    ],
  );

  static const interests = <Interest>[
    Interest(
      id: 'interest-food',
      emoji: '🍜',
      label: 'Ẩm thực & nấu ăn',
      status: InterestStatus.discovered,
      confidence: 82,
      evidence: 'Bạn nhắc “food”, “restaurant”, “cooking” 14 lần trong 4 buổi '
          'gần đây — nhưng chủ đề này chưa có trong danh sách.',
      detail: 'nói 4/8 buổi',
      ratio: 0.6,
    ),
    Interest(
      id: 'interest-football',
      emoji: '⚽',
      label: 'Bóng đá',
      status: InterestStatus.active,
      detail: 'nói 5/8 buổi',
      ratio: 0.88,
    ),
    Interest(
      id: 'interest-travel',
      emoji: '✈️',
      label: 'Du lịch',
      status: InterestStatus.active,
      detail: 'nói 4/8 buổi',
      ratio: 0.7,
    ),
    Interest(
      id: 'interest-tech',
      emoji: '💻',
      label: 'Công nghệ',
      status: InterestStatus.active,
      detail: 'nói 2/8 buổi',
      ratio: 0.34,
    ),
    Interest(
      id: 'interest-books',
      emoji: '📚',
      label: 'Sách',
      status: InterestStatus.cooling,
      detail: 'Không nhắc tới trong 6 buổi gần nhất',
    ),
  ];

  static const progressReports = <ProgressRange, ProgressReport>{
    ProgressRange.fourWeeks: ProgressReport(
      range: ProgressRange.fourWeeks,
      averageScore: 8.1,
      delta: 0.9,
      points: [
        ProgressPoint(label: 'T1', value: 6.4),
        ProgressPoint(label: 'T2', value: 7.0),
        ProgressPoint(label: 'T3', value: 6.8),
        ProgressPoint(label: 'T4', value: 7.5),
        ProgressPoint(label: 'T5', value: 7.9),
        ProgressPoint(label: 'T6', value: 7.4),
        ProgressPoint(label: 'T7', value: 8.1),
      ],
      recentSessions: [
        SessionHistoryItem(
          id: 'hist-1',
          title: 'Chuyến đi Đà Lạt',
          subtitle: 'Hôm nay · 8 phút',
          score: 8.1,
          icon: 'flight_takeoff',
        ),
        SessionHistoryItem(
          id: 'hist-2',
          title: 'Trận đấu yêu thích',
          subtitle: 'Hôm qua · 6 phút',
          score: 7.7,
          icon: 'sports_soccer',
        ),
        SessionHistoryItem(
          id: 'hist-3',
          title: 'AI trong lớp học',
          subtitle: '3 ngày trước · 9 phút',
          score: 6.9,
          icon: 'smart_toy',
        ),
      ],
    ),
    ProgressRange.threeMonths: ProgressReport(
      range: ProgressRange.threeMonths,
      averageScore: 7.6,
      delta: 1.4,
      points: [
        ProgressPoint(label: 'Th4', value: 6.2),
        ProgressPoint(label: 'Th5', value: 6.7),
        ProgressPoint(label: 'Th6', value: 7.1),
        ProgressPoint(label: 'Th7', value: 7.6),
      ],
      recentSessions: [
        SessionHistoryItem(
          id: 'hist-1',
          title: 'Chuyến đi Đà Lạt',
          subtitle: 'Hôm nay · 8 phút',
          score: 8.1,
          icon: 'flight_takeoff',
        ),
        SessionHistoryItem(
          id: 'hist-4',
          title: 'Món ăn quê hương',
          subtitle: '2 tuần trước · 5 phút',
          score: 7.2,
          icon: 'restaurant',
        ),
      ],
    ),
    ProgressRange.all: ProgressReport(
      range: ProgressRange.all,
      averageScore: 7.2,
      delta: 2.1,
      points: [
        ProgressPoint(label: '2024', value: 6.0),
        ProgressPoint(label: 'Q1', value: 6.5),
        ProgressPoint(label: 'Q2', value: 7.0),
        ProgressPoint(label: 'Q3', value: 7.2),
      ],
      recentSessions: [
        SessionHistoryItem(
          id: 'hist-1',
          title: 'Chuyến đi Đà Lạt',
          subtitle: 'Hôm nay · 8 phút',
          score: 8.1,
          icon: 'flight_takeoff',
        ),
        SessionHistoryItem(
          id: 'hist-5',
          title: 'Buổi đầu tiên',
          subtitle: '6 tháng trước · 4 phút',
          score: 5.4,
          icon: 'mic',
        ),
      ],
    ),
  };

  // ── Onboarding ────────────────────────────────────────────────────────────

  static const onboardingQuestions = <OnboardingQuestion>[
    OnboardingQuestion(
      id: 'q1',
      category: OnboardingCategory.flas,
      categoryLabel: 'THÁI ĐỘ & ĐỘNG LỰC (FLAS)',
      prompt: 'Khi phải nói tiếng Anh trước cả lớp, mình thường thấy…',
      options: [
        'Rất lo lắng, muốn né đi',
        'Hơi hồi hộp nhưng vẫn nói được',
        'Bình thường, tuỳ chủ đề',
        'Khá tự tin, thích được gọi',
        'Rất tự tin, mình xung phong',
      ],
    ),
    OnboardingQuestion(
      id: 'q2',
      category: OnboardingCategory.flas,
      categoryLabel: 'THÁI ĐỘ & ĐỘNG LỰC (FLAS)',
      prompt: 'Khi không hiểu người khác nói gì bằng tiếng Anh, mình…',
      options: [
        'Im lặng và gật đầu cho qua',
        'Ngại nhưng vẫn cố đoán',
        'Hỏi lại nếu thật sự cần',
        'Hỏi lại ngay, thấy bình thường',
        'Hỏi lại và còn nhờ nói chậm hơn',
      ],
    ),
    OnboardingQuestion(
      id: 'q3',
      category: OnboardingCategory.flas,
      categoryLabel: 'THÁI ĐỘ & ĐỘNG LỰC (FLAS)',
      prompt: 'Khi bị sửa lỗi giữa lúc đang nói, cảm giác của mình là…',
      options: [
        'Mất hết hứng, không muốn nói tiếp',
        'Hơi ngượng, cần một lúc mới nói lại được',
        'Bình thường, nghe rồi nói tiếp',
        'Thấy hữu ích, muốn sửa ngay',
        'Rất thích, mình chủ động nhờ sửa',
      ],
    ),
    OnboardingQuestion(
      id: 'q4',
      category: OnboardingCategory.flas,
      categoryLabel: 'THÁI ĐỘ & ĐỘNG LỰC (FLAS)',
      prompt: 'Trước một buổi luyện nói, mình thường…',
      options: [
        'Tìm cách hoãn lại',
        'Lo lắng nhưng vẫn vào',
        'Không nghĩ gì nhiều',
        'Khá mong chờ',
        'Rất háo hức, chuẩn bị sẵn ý',
      ],
    ),
    OnboardingQuestion(
      id: 'q5',
      category: OnboardingCategory.flas,
      categoryLabel: 'THÁI ĐỘ & ĐỘNG LỰC (FLAS)',
      prompt: 'Mình luyện nói tiếng Anh chủ yếu vì…',
      options: [
        'Bị bắt buộc phải học',
        'Cần điểm cho môn học',
        'Cần cho kỳ thi sắp tới',
        'Muốn dùng được trong công việc',
        'Mình thực sự thích nói tiếng Anh',
      ],
    ),
    OnboardingQuestion(
      id: 'q6',
      category: OnboardingCategory.flas,
      categoryLabel: 'THÁI ĐỘ & ĐỘNG LỰC (FLAS)',
      prompt: 'Nếu nói sai ngữ pháp giữa chừng, mình sẽ…',
      options: [
        'Dừng hẳn, không biết nói tiếp thế nào',
        'Lúng túng một lúc lâu',
        'Sửa lại rồi nói tiếp',
        'Bỏ qua và nói tiếp cho trôi',
        'Không bận tâm, miễn người nghe hiểu',
      ],
    ),
    OnboardingQuestion(
      id: 'q7',
      category: OnboardingCategory.learningStyle,
      categoryLabel: 'PHONG CÁCH HỌC',
      prompt: 'Mình nhớ từ mới tốt nhất khi…',
      options: [
        'Nhìn thấy từ đó viết ra',
        'Nghe ai đó phát âm nhiều lần',
        'Tự nói thành câu của mình',
        'Thấy nó trong một câu chuyện',
        'Dùng nó trong hội thoại thật',
      ],
    ),
    OnboardingQuestion(
      id: 'q8',
      category: OnboardingCategory.learningStyle,
      categoryLabel: 'PHONG CÁCH HỌC',
      prompt: 'Mình thích nhận nhận xét về bài nói theo kiểu…',
      options: [
        'Chỉ điểm số là đủ',
        'Vài gạch đầu dòng ngắn gọn',
        'Sửa từng câu một cách chi tiết',
        'So sánh với câu mẫu chuẩn',
        'Nghe lại chính giọng mình rồi tự sửa',
      ],
    ),
    OnboardingQuestion(
      id: 'q9',
      category: OnboardingCategory.learningStyle,
      categoryLabel: 'PHONG CÁCH HỌC',
      prompt: 'Một buổi luyện nói lý tưởng với mình dài khoảng…',
      options: [
        'Dưới 5 phút',
        '5–10 phút',
        '10–15 phút',
        '15–25 phút',
        'Trên 25 phút',
      ],
    ),
    OnboardingQuestion(
      id: 'q10',
      category: OnboardingCategory.learningStyle,
      categoryLabel: 'PHONG CÁCH HỌC',
      prompt: 'Mình luyện nói đều đặn nhất vào lúc…',
      options: [
        'Sáng sớm trước khi đi học/làm',
        'Giờ nghỉ trưa',
        'Chiều sau giờ học',
        'Tối trước khi ngủ',
        'Không cố định, lúc nào rảnh thì tập',
      ],
    ),
    OnboardingQuestion(
      id: 'q11',
      category: OnboardingCategory.learningStyle,
      categoryLabel: 'PHONG CÁCH HỌC',
      prompt: 'Khi bí ý tưởng giữa lúc nói, mình muốn app…',
      options: [
        'Gợi ý luôn cả câu mẫu',
        'Gợi ý vài từ khoá',
        'Hỏi thêm một câu dẫn dắt',
        'Chờ mình tự nghĩ ra',
        'Cho phép chuyển sang câu khác',
      ],
    ),
    OnboardingQuestion(
      id: 'q12',
      category: OnboardingCategory.learningStyle,
      categoryLabel: 'PHONG CÁCH HỌC',
      prompt: 'Điều khiến mình muốn quay lại luyện tiếp là…',
      options: [
        'Thấy điểm số tăng lên',
        'Giữ được chuỗi ngày liên tục',
        'Chủ đề đúng thứ mình thích',
        'Thấy rõ lỗi cũ đã bớt đi',
        'Nói trôi chảy hơn trong đời thật',
      ],
    ),
  ];

  static const interestChoices = <InterestChoice>[
    InterestChoice(id: 'football', emoji: '⚽', label: 'Bóng đá'),
    InterestChoice(id: 'food', emoji: '🍜', label: 'Ẩm thực'),
    InterestChoice(id: 'travel', emoji: '✈️', label: 'Du lịch'),
    InterestChoice(id: 'movies', emoji: '🎬', label: 'Phim ảnh'),
    InterestChoice(id: 'music', emoji: '🎵', label: 'Âm nhạc'),
    InterestChoice(id: 'tech', emoji: '💻', label: 'Công nghệ'),
    InterestChoice(id: 'scholarship', emoji: '🎓', label: 'Học bổng'),
    InterestChoice(id: 'environment', emoji: '🌿', label: 'Môi trường'),
    InterestChoice(id: 'books', emoji: '📚', label: 'Sách'),
    InterestChoice(id: 'family', emoji: '👨‍👩‍👧', label: 'Gia đình'),
    InterestChoice(id: 'startup', emoji: '🚀', label: 'Khởi nghiệp'),
    InterestChoice(id: 'health', emoji: '💪', label: 'Sức khoẻ'),
  ];

  static const learningGoals = <LearningGoal>[
    LearningGoal(
      id: 'goal-ielts',
      title: 'Thi IELTS Speaking 6.5',
      subtitle: 'Còn 14 tuần · 3 buổi/tuần',
      icon: 'school',
    ),
    LearningGoal(
      id: 'goal-work',
      title: 'Giao tiếp trong công việc',
      subtitle: 'Họp, thuyết trình, email thoại',
      icon: 'work_outline',
    ),
    LearningGoal(
      id: 'goal-daily',
      title: 'Tự tin nói hằng ngày',
      subtitle: 'Không áp lực điểm số',
      icon: 'forum',
    ),
  ];

  static const learnerProfile = LearnerProfile(
    cefrLevel: 'B1+',
    traits: ['Người học thận trọng', 'Động lực cao'],
    flas: [
      FlasScore(label: 'Lo lắng khi nói', value: 41, inverted: true),
      FlasScore(label: 'Động lực học', value: 78),
    ],
    rubric: [
      RubricCriterion(label: 'Đáp ứng yêu cầu', weight: 25, score: 7.5),
      RubricCriterion(label: 'Trôi chảy & mạch lạc', weight: 20, score: 8.0),
      RubricCriterion(label: 'Từ vựng', weight: 20, score: 8.5),
      RubricCriterion(label: 'Ngữ pháp', weight: 20, score: 6.5),
      RubricCriterion(label: 'Phát âm', weight: 15, score: 7.5),
    ],
    roadmap: [
      RoadmapWeek(badge: 'T1', title: 'Kể chuyện quá khứ — du lịch & bóng đá'),
      RoadmapWeek(badge: 'T2', title: 'Nêu quan điểm — công nghệ & sách'),
      RoadmapWeek(badge: 'T3', title: 'Mô tả & so sánh — ẩm thực & nơi chốn'),
      RoadmapWeek(badge: 'T4', title: 'Tranh luận ngắn — dạng IELTS Part 3'),
    ],
  );
}
