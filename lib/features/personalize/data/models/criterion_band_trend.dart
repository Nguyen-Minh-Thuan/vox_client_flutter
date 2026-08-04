/// Diễn biến BẬC của một tiêu chí theo thời gian.
///
/// Vì sao cần thứ này bên cạnh điểm phiên: điểm phiên được neo vào **bậc mục tiêu**, còn độ
/// khó câu hỏi lại bám theo bậc hiện tại của học sinh. Em giỏi lên thì hệ thống ra câu khó
/// hơn, và điểm đứng yên. Hai buổi cùng 6.5 nhưng một buổi trả lời câu bậc 3 còn buổi kia
/// bậc 4 là tiến bộ rõ rệt mà con số không nói được.
///
/// `latentLevel` không có vấn đề đó: phần nguyên là bậc câu trả lời THỰC SỰ khớp
/// (`matched_band_code`, độc lập với bậc mục tiêu), phần thập phân là mức thoả bậc mục tiêu
/// trong bậc ấy. Thang tuyệt đối, so được giữa các thời điểm.
class CriterionBandTrend {
  final String criterionCode;

  /// Giá trị mới nhất trong khoảng đang xem.
  final double latest;

  /// Chênh lệch so với giá trị ĐẦU TIÊN trong khoảng. null khi chỉ có một điểm đo —
  /// một điểm thì không có gì để so, và vẽ mũi tên phẳng ở đó là bịa ra một kết luận.
  final double? delta;

  /// Số lần chấm góp vào đường này. Hiện ra để học sinh biết con số dựa trên bao nhiêu lần,
  /// thay vì tin một mũi tên dựng từ hai điểm.
  final int observationCount;

  /// Có điểm nào đến từ bài THI không. Điểm luyện có thiên lệch hệ thống (độ khó bám theo
  /// bậc hiện tại nên đường luyện phẳng hơn thực tế); điểm thi thì không.
  final bool hasExam;

  const CriterionBandTrend({
    required this.criterionCode,
    required this.latest,
    required this.delta,
    required this.observationCount,
    required this.hasExam,
  });

  /// Bậc là số NGUYÊN. `result_band_order` là thang THỨ BẬC, không phải thang khoảng:
  /// khoảng cách A2→B1 không bằng B1→B2. "Bậc 2,4" giả định các bậc rộng bằng nhau và chia
  /// nhỏ được — không có thứ đó. Phần lẻ tách riêng thành [withinBandPercent].
  int get bandOrder => latest.floor() + 1;

  String get bandLabel => 'Bậc $bandOrder';

  // KHÔNG có "phần trăm trong bậc". Phần lẻ của latentLevel là final_score, mà final_score đo
  // "thoả bao nhiêu phần mô tả của bậc MỤC TIÊU" -- còn phần nguyên là bậc câu trả lời THỰC SỰ
  // khớp, độc lập với bậc mục tiêu. Hai nửa đo theo hai mốc khác nhau, dán vào nhau là nói sai:
  // khớp Bậc 3 với mục tiêu Bậc 2 và điểm 70 thì "70% trong Bậc 3" hoàn toàn vô nghĩa -- 70%
  // đó là của Bậc 2.
  //
  // matched_band_code đứng một mình mới là thứ so được giữa mọi lần chấm: nó không phụ thuộc
  // bậc mục tiêu, nên trường đổi chính sách hay học sinh lên lớp thì nó vẫn so được.

  /// Gom các điểm thô của `myPracticeProgress` thành một dòng cho mỗi tiêu chí.
  ///
  /// Backend đã trả về theo thứ tự thời gian tăng dần, nên phần tử đầu/cuối của mỗi nhóm
  /// chính là mốc đầu và mốc mới nhất.
  static List<CriterionBandTrend> fromPoints(List<Map<String, dynamic>> rows) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final row in rows) {
      final code = (row['criterionCode'] as String? ?? '').trim();
      if (code.isEmpty) continue;
      grouped.putIfAbsent(code, () => []).add(row);
    }
    final result = <CriterionBandTrend>[];
    grouped.forEach((code, points) {
      final values = points
          .map((p) => (p['value'] as num?)?.toDouble())
          .whereType<double>()
          .toList();
      if (values.isEmpty) return;
      result.add(
        CriterionBandTrend(
          criterionCode: code,
          latest: values.last,
          delta: values.length < 2 ? null : values.last - values.first,
          observationCount: values.length,
          hasExam: points.any((p) => (p['source'] as String?) == 'EXAM'),
        ),
      );
    });
    result.sort((a, b) => a.criterionCode.compareTo(b.criterionCode));
    return result;
  }
}
