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

  WeaknessSeverity get severity => weakness > 0.3
      ? WeaknessSeverity.severe
      : (weakness > 0 ? WeaknessSeverity.medium : WeaknessSeverity.mild);

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

  /// Đổi nhịp xuất hiện so với cửa sổ trước, %. Dương = đang sai nhiều hơn.
  /// null khi mẫu quá nhỏ hoặc lỗi vừa mới phát hiện — lúc đó KHÔNG vẽ mũi tên,
  /// vì một buổi lẻ cũng đủ làm con số nhảy vài chục phần trăm.
  final double? trendPercent;

  /// Vài đoạn học sinh đã nói làm bằng chứng cho nhãn này, mới nhất trước.
  ///
  /// Rỗng với nhãn suy từ SỐ ĐO (phát âm, tốc độ nói): chúng không gắn với một câu cụ thể
  /// nào, nên bịa ra một câu làm ví dụ sẽ là nói sai về nguồn gốc của nhãn.
  final List<WeaknessExample> examples;

  /// Từng lặp lại nhưng cửa sổ gần đây không còn -- đang trên đà khỏi.
  ///
  /// Không tái phạm trong 60 ngày thì nhãn tự rụng hẳn khỏi danh sách
  /// (`replaceForStudents` tính lại từ đầu mỗi lần làm mới, chỉ đếm quan sát trong cửa sổ).
  final bool nearlyFixed;

  /// Mọi lần xuất hiện đều trong cửa sổ gần đây -- lỗi mới lộ ra.
  final bool newlyFound;

  const SubAttributeWeaknessRow({
    required this.criterionCode,
    required this.subAttribute,
    required this.occurrenceCount,
    required this.severity,
    required this.practiceable,
    this.trendPercent,
    this.examples = const [],
    this.nearlyFixed = false,
    this.newlyFound = false,
  });

  /// Nhãn hiển thị cho học sinh.
  ///
  /// `phoneme_n` là ĐỊNH DANH NỘI BỘ do nhánh suy-từ-phát-âm sinh ra, không thuộc 13 nhãn
  /// của SubAttributePolicy. Để lọt nguyên ra màn hình thì học sinh đọc được đúng chữ
  /// "phoneme_n" -- vô nghĩa với người học. Các nhãn còn lại giữ nguyên theo quyết định
  /// trước đó là không dịch sang tiếng Việt.
  String get displayLabel {
    if (subAttribute.startsWith('phoneme_')) {
      final sound = subAttribute.substring('phoneme_'.length);
      return sound.isEmpty ? subAttribute : 'Âm /$sound/';
    }
    return subAttribute;
  }

  /// Meter-bar fill derived from the real occurrence count (normalized
  /// against 5 -- same scale convention used elsewhere in this app for
  /// "bank availability" style ratios).
  double get ratio => (occurrenceCount / 5.0).clamp(0.0, 1.0);

  factory SubAttributeWeaknessRow.fromJson(Map<String, dynamic> json) {
    return SubAttributeWeaknessRow(
      criterionCode: json['criterionCode'] as String,
      subAttribute: json['subAttribute'] as String,
      examples: ((json['examples'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(WeaknessExample.fromJson)
          .where((e) => e.text.isNotEmpty)
          .toList(),
      nearlyFixed: json['nearlyFixed'] as bool? ?? false,
      newlyFound: json['newlyFound'] as bool? ?? false,
      occurrenceCount: (json['occurrenceCount'] as num?)?.toInt() ?? 0,
      severity: _severityFromCode(json['severity'] as String?),
      practiceable: json['practiceable'] as bool? ?? false,
      trendPercent: (json['trendPercent'] as num?)?.toDouble(),
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
          .map(
            (e) => SubAttributeWeaknessRow.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}


/// Một bằng chứng thật cho nhãn điểm yếu, kèm số lần lặp.
///
/// Với lỗi phát âm đây là phần duy nhất dùng được: nhãn "/d/" đứng một mình thì học sinh
/// không biết sửa gì, còn "read ×3 · daily ×2" thì luyện được ngay. Số lần theo TỪ cũng cho
/// thấy đó là lỗi âm lặp qua nhiều từ (luyện âm) hay chỉ vấp một từ (học lại từ đó).
class WeaknessExample {
  final String text;
  final int times;

  const WeaknessExample({required this.text, required this.times});

  factory WeaknessExample.fromJson(Map<String, dynamic> json) => WeaknessExample(
    text: (json['text'] as String? ?? '').trim(),
    times: (json['times'] as num?)?.toInt() ?? 1,
  );

  String get label => times > 1 ? '$text ×$times' : text;
}
