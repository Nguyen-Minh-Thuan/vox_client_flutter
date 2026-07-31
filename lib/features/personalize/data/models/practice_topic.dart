/// Buckets behind the filter pills on the topics screen.
enum TopicFilter { forYou, byGoal, byWeakness, saved }

/// Difficulty band shown next to the duration.
enum TopicLevel { beginner, intermediate, advanced }

/// A speaking topic the app can propose for a practice session.
class PracticeTopic {
  final String id;
  final String title;

  /// Why this topic was picked — shown on the priority card.
  final String? rationale;
  final int minutes;
  final TopicLevel level;

  /// 0..100 match score; only the top suggestion renders it.
  final int? matchPercent;

  /// Short "Vì bạn thích bóng đá" style chips.
  final List<String> reasons;

  /// Skill the topic drills, e.g. "Thì quá khứ" — rendered as an amber chip.
  final List<String> focusTags;

  /// Material icon codepoint name resolved by the UI; kept as a plain string
  /// so the model stays free of Flutter imports.
  final String icon;
  final Set<TopicFilter> buckets;

  const PracticeTopic({
    required this.id,
    required this.title,
    this.rationale,
    required this.minutes,
    required this.level,
    this.matchPercent,
    this.reasons = const [],
    this.focusTags = const [],
    this.icon = 'chat_bubble_outline',
    this.buckets = const {TopicFilter.forYou},
  });

  /// Builds from the real backend shape (`PracticeTopicOffer`/`TopicSearchResult.topics`
  /// in `practice-planning.graphqls`) — see gói 11 mục 2.6b for the field-by-field mapping.
  factory PracticeTopic.fromOffer(
    Map<String, dynamic> json, {
    TopicFilter bucket = TopicFilter.forYou,
  }) {
    final savedByMe = json['savedByMe'] as bool? ?? false;
    return PracticeTopic(
      id: json['topicId'] as String,
      title: json['name'] as String,
      rationale: json['rationale'] as String?,
      minutes: (json['minutes'] as num?)?.toInt() ?? 0,
      level: _levelFromJson(json['level'] as String?),
      matchPercent: (json['matchPercent'] as num?)?.toInt(),
      reasons: (json['reasons'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toList(),
      focusTags: (json['focusTags'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toList(),
      buckets: {
        bucket,
        if (savedByMe) TopicFilter.saved,
      },
    );
  }

  factory PracticeTopic.fromJson(Map<String, dynamic> json) {
    return PracticeTopic(
      id: json['id'] as String,
      title: json['title'] as String,
      rationale: json['rationale'] as String?,
      minutes: (json['minutes'] as num?)?.toInt() ?? 0,
      level: _levelFromJson(json['level'] as String?),
      matchPercent: (json['matchPercent'] as num?)?.toInt(),
      reasons: (json['reasons'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toList(),
      focusTags: (json['focusTags'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toList(),
      icon: json['icon'] as String? ?? 'chat_bubble_outline',
      buckets: (json['buckets'] as List<dynamic>? ?? const [])
          .map((e) => _filterFromJson(e as String?))
          .toSet(),
    );
  }

  static TopicLevel _levelFromJson(String? value) {
    switch (value) {
      case 'BEGINNER':
        return TopicLevel.beginner;
      case 'ADVANCED':
        return TopicLevel.advanced;
      case 'INTERMEDIATE':
      default:
        return TopicLevel.intermediate;
    }
  }

  static TopicFilter _filterFromJson(String? value) {
    switch (value) {
      case 'BY_GOAL':
        return TopicFilter.byGoal;
      case 'BY_WEAKNESS':
        return TopicFilter.byWeakness;
      case 'SAVED':
        return TopicFilter.saved;
      case 'FOR_YOU':
      default:
        return TopicFilter.forYou;
    }
  }
}
