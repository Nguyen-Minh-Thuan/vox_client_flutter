import 'models/learner_profile.dart';
import 'models/onboarding_question.dart';
import 'models/practice_session.dart';

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

  // weaknessProfile/interests/progressReports demo blocks removed -- those 3
  // screens now call real backend data (`getWeaknessProfile`/`getInterests`/
  // `getProgress` in `PersonalizeRepository`), see gói "nối personalize".

  // ── Onboarding ────────────────────────────────────────────────────────────

  // Đúng 3 câu -- khớp `LearnerProfileCommandService.submitFlsa` (nhận 3-4 câu
  // Likert 1-5, câu thứ 3 (index 2) bị đảo điểm `6 - value` trước khi tính
  // trung bình). LƯU Ý: q3 gốc không thực sự soạn theo hướng "đảo chiều"
  // (index 4 vẫn là lựa chọn tích cực nhất, giống q1/q2) -- việc đảo điểm cơ
  // học vẫn xảy ra vì backend áp dụng cứng theo vị trí, không theo nội dung.
  // Soạn lại câu 3 thật sự đảo chiều (kiểm định Cronbach's alpha, cân bằng
  // social desirability...) là việc nghiên cứu tâm lý học riêng, ngoài phạm
  // vi nối dây hôm nay.
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
