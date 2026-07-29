/// Section a weakness is filed under on the profile screen.
enum WeaknessCategory { grammar, pronunciation, expression }

/// Badge shown on a weakness card.
enum WeaknessSeverity { severe, isNew, improving, mild }

/// One tracked weakness in the learner's error profile.
class Weakness {
  final String id;
  final WeaknessCategory category;
  final String title;
  final WeaknessSeverity severity;

  /// Sub-caption, e.g. "9 lần · trong 5/8 buổi gần đây".
  final String detail;

  /// Meter fill, 0..1.
  final double ratio;

  /// Right-hand delta caption, e.g. "↑ 12%". Empty renders an em dash.
  final String deltaLabel;

  /// `true` when [deltaLabel] is good news (green) rather than bad (red).
  final bool deltaIsPositive;

  const Weakness({
    required this.id,
    required this.category,
    required this.title,
    required this.severity,
    required this.detail,
    required this.ratio,
    this.deltaLabel = '',
    this.deltaIsPositive = false,
  });

  factory Weakness.fromJson(Map<String, dynamic> json) {
    return Weakness(
      id: json['id'] as String,
      category: _categoryFromJson(json['category'] as String?),
      title: json['title'] as String,
      severity: _severityFromJson(json['severity'] as String?),
      detail: json['detail'] as String? ?? '',
      ratio: (json['ratio'] as num?)?.toDouble() ?? 0,
      deltaLabel: json['deltaLabel'] as String? ?? '',
      deltaIsPositive: json['deltaIsPositive'] as bool? ?? false,
    );
  }

  static WeaknessCategory _categoryFromJson(String? value) {
    switch (value) {
      case 'PRONUNCIATION':
        return WeaknessCategory.pronunciation;
      case 'EXPRESSION':
        return WeaknessCategory.expression;
      case 'GRAMMAR':
      default:
        return WeaknessCategory.grammar;
    }
  }

  static WeaknessSeverity _severityFromJson(String? value) {
    switch (value) {
      case 'NEW':
        return WeaknessSeverity.isNew;
      case 'IMPROVING':
        return WeaknessSeverity.improving;
      case 'MILD':
        return WeaknessSeverity.mild;
      case 'SEVERE':
      default:
        return WeaknessSeverity.severe;
    }
  }
}

/// The header counters on the weakness-profile screen.
class WeaknessProfile {
  final int sessionsAnalysed;
  final int tracked;
  final int nearlyFixed;
  final int newlyFound;
  final List<Weakness> weaknesses;

  const WeaknessProfile({
    required this.sessionsAnalysed,
    required this.tracked,
    required this.nearlyFixed,
    required this.newlyFound,
    this.weaknesses = const [],
  });

  List<Weakness> byCategory(WeaknessCategory category) =>
      weaknesses.where((w) => w.category == category).toList();

  factory WeaknessProfile.fromJson(Map<String, dynamic> json) {
    return WeaknessProfile(
      sessionsAnalysed: (json['sessionsAnalysed'] as num?)?.toInt() ?? 0,
      tracked: (json['tracked'] as num?)?.toInt() ?? 0,
      nearlyFixed: (json['nearlyFixed'] as num?)?.toInt() ?? 0,
      newlyFound: (json['newlyFound'] as num?)?.toInt() ?? 0,
      weaknesses: (json['weaknesses'] as List<dynamic>? ?? const [])
          .map((e) => Weakness.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
