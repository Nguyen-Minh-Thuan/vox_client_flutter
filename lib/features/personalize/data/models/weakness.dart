/// Badge shown on a weakness row — maps 1:1 to the real `severity` string
/// backend already computes for sub-attributes (`NANG`/`VUA`/`NHE`); for
/// criterion-level rows there's no such field, so it's derived from the real
/// `weakness` score via fixed thresholds (a real number bucketed, not a made
/// up value).
enum WeaknessSeverity { severe, medium, mild }

WeaknessSeverity _severityFromCode(String? value) {
  switch (value) {
    case 'NANG':
      return WeaknessSeverity.severe;
    case 'NHE':
      return WeaknessSeverity.mild;
    case 'VUA':
    default:
      return WeaknessSeverity.medium;
  }
}

/// One row from `WeaknessProfile.criteria` — a whole rubric criterion
/// (e.g. "Coherence", "Grammar"), configured per school/framework, NOT a
/// fixed 3-way grammar/pronunciation/expression split.
class CriterionWeaknessRow {
  final String criterionCode;
  final String criterionName;

  /// Real, centered relative score from `learner_weakness_snapshot.weakness`
  /// (roughly -1..1, higher = weaker than average). NOT a 0..1 ratio itself.
  final double weakness;
  final int observationCount;
  final bool reliable;

  const CriterionWeaknessRow({
    required this.criterionCode,
    required this.criterionName,
    required this.weakness,
    required this.observationCount,
    required this.reliable,
  });

  /// Meter-bar fill, derived from the real (roughly -1..1) [weakness] score.
  double get ratio => ((weakness + 1) / 2).clamp(0.0, 1.0);

  WeaknessSeverity get severity =>
      weakness > 0.3 ? WeaknessSeverity.severe : (weakness > 0 ? WeaknessSeverity.medium : WeaknessSeverity.mild);

  factory CriterionWeaknessRow.fromJson(Map<String, dynamic> json) {
    return CriterionWeaknessRow(
      criterionCode: json['criterionCode'] as String,
      criterionName: json['criterionName'] as String,
      weakness: (json['weakness'] as num?)?.toDouble() ?? 0,
      observationCount: (json['observationCount'] as num?)?.toInt() ?? 0,
      reliable: json['reliable'] as bool? ?? false,
    );
  }
}

/// One row from `WeaknessProfile.subAttributes` — a finer-grained recurring
/// issue within a criterion (e.g. "past tense" under Grammar).
class SubAttributeWeaknessRow {
  final String criterionCode;
  final String subAttribute;
  final int occurrenceCount;
  final WeaknessSeverity severity;
  final bool practiceable;

  const SubAttributeWeaknessRow({
    required this.criterionCode,
    required this.subAttribute,
    required this.occurrenceCount,
    required this.severity,
    required this.practiceable,
  });

  /// Meter-bar fill derived from the real occurrence count (normalized
  /// against 5 -- same scale convention used elsewhere in this app for
  /// "bank availability" style ratios).
  double get ratio => (occurrenceCount / 5.0).clamp(0.0, 1.0);

  factory SubAttributeWeaknessRow.fromJson(Map<String, dynamic> json) {
    return SubAttributeWeaknessRow(
      criterionCode: json['criterionCode'] as String,
      subAttribute: json['subAttribute'] as String,
      occurrenceCount: (json['occurrenceCount'] as num?)?.toInt() ?? 0,
      severity: _severityFromCode(json['severity'] as String?),
      practiceable: json['practiceable'] as bool? ?? false,
    );
  }
}

/// `myWeaknessProfile` — every field here is either a real backend value or
/// a documented derivation of one; no fabricated counters (the old mock's
/// per-card trend arrow had no real source and was dropped).
class WeaknessProfile {
  final int sessionsAnalysed;
  final int nearlyFixed;
  final int newlyFound;
  final List<CriterionWeaknessRow> criteria;
  final List<SubAttributeWeaknessRow> subAttributes;

  const WeaknessProfile({
    required this.sessionsAnalysed,
    required this.nearlyFixed,
    required this.newlyFound,
    this.criteria = const [],
    this.subAttributes = const [],
  });

  int get tracked => subAttributes.length;

  List<SubAttributeWeaknessRow> subAttributesFor(String criterionCode) =>
      subAttributes.where((row) => row.criterionCode == criterionCode).toList();

  factory WeaknessProfile.fromJson(Map<String, dynamic> json) {
    return WeaknessProfile(
      sessionsAnalysed: (json['sessionsAnalysed'] as num?)?.toInt() ?? 0,
      nearlyFixed: (json['nearlyFixed'] as num?)?.toInt() ?? 0,
      newlyFound: (json['newlyFound'] as num?)?.toInt() ?? 0,
      criteria: (json['criteria'] as List<dynamic>? ?? const [])
          .map((e) => CriterionWeaknessRow.fromJson(e as Map<String, dynamic>))
          .toList(),
      subAttributes: (json['subAttributes'] as List<dynamic>? ?? const [])
          .map((e) => SubAttributeWeaknessRow.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
