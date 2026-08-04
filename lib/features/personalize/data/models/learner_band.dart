/// Bậc năng lực của học sinh theo khung của trường (VSTEP 6 bậc, CEFR, IELTS...).
///
/// Ba số này backend đã tính sẵn và phơi qua `myLearnerProfile` từ lâu, chỉ là client
/// chưa đọc. Không có nhãn CEFR kiểu "B1+" trong dữ liệu — `framework_result_bands` chỉ
/// có `code` (BAC_3) và `label` ("Bậc 3"), nên đừng dựng nhãn CEFR ở client.
class LearnerBand {
  /// Mã bậc ước lượng từ lịch sử chấm (thi + luyện). `null` khi chưa đủ 5 lượt chấm.
  final String? estimatedCode;

  /// Nhãn bậc MỤC TIÊU do trường đặt qua chính sách chấm — luôn có.
  final String targetLabel;

  /// Mã bậc mục tiêu.
  final String targetCode;

  /// Phần trăm đã đạt so với bậc mục tiêu, 0..100. `null` khi chưa có dữ liệu chấm.
  final double? targetAttainmentPercent;

  const LearnerBand({
    required this.estimatedCode,
    required this.targetLabel,
    required this.targetCode,
    required this.targetAttainmentPercent,
  });

  /// `false` khi học sinh chưa đủ dữ liệu để ước lượng — UI phải nói rõ "chưa đủ dữ liệu"
  /// thay vì hiện bậc mục tiêu như thể đó là trình độ hiện tại.
  bool get hasEstimate => estimatedCode != null;

  factory LearnerBand.fromJson(Map<String, dynamic> json) {
    return LearnerBand(
      estimatedCode: json['estimatedFrameworkBandCode'] as String?,
      targetLabel: json['targetFrameworkBandLabel'] as String? ?? '—',
      targetCode: json['targetFrameworkBandCode'] as String? ?? '—',
      targetAttainmentPercent: (json['targetBandAttainmentPercent'] as num?)
          ?.toDouble(),
    );
  }
}
