/// Which part of the onboarding questionnaire a question belongs to.
enum OnboardingCategory { flas, learningStyle }

/// One single-choice question in the onboarding questionnaire.
class OnboardingQuestion {
  final String id;
  final OnboardingCategory category;

  /// Chip caption above the prompt, e.g. "THÁI ĐỘ & ĐỘNG LỰC (FLAS)".
  final String categoryLabel;
  final String prompt;
  final List<String> options;

  const OnboardingQuestion({
    required this.id,
    required this.category,
    required this.categoryLabel,
    required this.prompt,
    required this.options,
  });

  factory OnboardingQuestion.fromJson(Map<String, dynamic> json) {
    return OnboardingQuestion(
      id: json['id'] as String,
      category: _categoryFromJson(json['category'] as String?),
      categoryLabel: json['categoryLabel'] as String? ?? '',
      prompt: json['prompt'] as String,
      options: (json['options'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toList(),
    );
  }

  static OnboardingCategory _categoryFromJson(String? value) {
    switch (value) {
      case 'LEARNING_STYLE':
        return OnboardingCategory.learningStyle;
      case 'FLAS':
      default:
        return OnboardingCategory.flas;
    }
  }
}

/// A selectable topic chip on the interests step.
class InterestChoice {
  final String id;
  final String emoji;
  final String label;

  const InterestChoice({
    required this.id,
    required this.emoji,
    required this.label,
  });

  factory InterestChoice.fromJson(Map<String, dynamic> json) {
    return InterestChoice(
      id: json['id'] as String,
      emoji: json['emoji'] as String? ?? '',
      label: json['label'] as String,
    );
  }
}

/// One of the main goals the learner picks during onboarding.
class LearningGoal {
  final String id;
  final String title;
  final String subtitle;
  final String icon;

  const LearningGoal({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  factory LearningGoal.fromJson(Map<String, dynamic> json) {
    return LearningGoal(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String? ?? '',
      icon: json['icon'] as String? ?? 'flag_outlined',
    );
  }
}
