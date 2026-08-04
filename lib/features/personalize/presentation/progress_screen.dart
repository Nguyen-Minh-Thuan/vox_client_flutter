import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../app/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../data/models/criterion_band_trend.dart';
import '../data/models/progress_report.dart';
import '../data/personalize_repository.dart';
import 'personalize_styles.dart';
import 'personalize_widgets.dart';
import 'practice_history_screen.dart';

/// Design `1f`, screen 4 — score trend and session history.
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final _repository = PersonalizeRepository();

  ProgressRange _range = ProgressRange.fourWeeks;
  List<CriterionBandTrend> _bandTrends = const [];
  bool _loading = true;
  String? _error;
  ProgressReport? _report;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _repository.getProgress(_range),
        _repository.getCriterionBandTrends(_range),
      ]);
      final report = results[0] as ProgressReport;
      final trends = results[1] as List<CriterionBandTrend>;
      if (!mounted) return;
      setState(() {
        _report = report;
        _bandTrends = trends;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _selectRange(ProgressRange range) {
    if (_range == range) return;
    setState(() => _range = range);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final labels = <ProgressRange, String>{
      ProgressRange.fourWeeks: l10n.pzProgressRangeFourWeeks,
      ProgressRange.threeMonths: l10n.pzProgressRangeThreeMonths,
      ProgressRange.all: l10n.pzProgressRangeAll,
    };

    return Scaffold(
      appBar: AppBar(title: Text(l10n.pzProgressTitle)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final entry in labels.entries) ...[
                    SelectablePill(
                      label: entry.value,
                      active: entry.key == _range,
                      onTap: () => _selectRange(entry.key),
                    ),
                    const SizedBox(width: 7),
                  ],
                ],
              ),
            ),
          ),
          Expanded(
            child: switch ((_loading, _error, _report)) {
              (true, _, _) => const Center(child: CircularProgressIndicator()),
              (_, final String error, _) => PersonalizeErrorView(
                detail: error,
                onRetry: _load,
              ),
              (_, _, null) => PersonalizeErrorView(onRetry: _load),
              (_, _, final ProgressReport report) => ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                children: [
                  _AverageCard(report: report),
                  const SizedBox(height: 20),
                  _BandTrendCard(trends: _bandTrends),
                  const SizedBox(height: 20),
                  // Ở đây chỉ liệt kê vài buổi gần nhất; danh sách đầy đủ (và bấm vào
                  // xem lại tổng kết từng buổi) nằm ở PracticeHistoryScreen -- màn đó
                  // viết xong từ lâu nhưng chưa có nút nào dẫn tới, đây là nút đó.
                  Row(
                    children: [
                      Expanded(
                        child: SectionLabel(l10n.pzProgressRecentSessions),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const PracticeHistoryScreen(),
                          ),
                        ),
                        child: Text(
                          l10n.pzSeeAll,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.indigo,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  for (final session in report.recentSessions) ...[
                    _HistoryRow(session: session),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            },
          ),
        ],
      ),
    );
  }
}

/// Average-score headline plus the bar chart.
class _AverageCard extends StatelessWidget {
  const _AverageCard({required this.report});
  final ProgressReport report;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final peak = report.peak;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: rowDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(child: SectionLabel(l10n.pzProgressAverage)),
              Text(
                report.averageScore.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formatDelta(report.delta),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: report.delta >= 0
                      ? AppColors.chipGreenFg
                      : AppColors.danger,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (int i = 0; i < report.points.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: _Bar(
                      point: report.points[i],
                      peak: peak,
                      highlighted: i == report.points.length - 1,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.point,
    required this.peak,
    required this.highlighted,
  });

  final ProgressPoint point;
  final double peak;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    // Reserve room for the label row so the tallest bar still fits.
    const labelHeight = 20.0;
    final ratio = (point.value / peak).clamp(0.08, 1.0);

    return LayoutBuilder(
      builder: (_, constraints) {
        final available = constraints.maxHeight - labelHeight;
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              height: available * ratio,
              decoration: BoxDecoration(
                color: highlighted
                    ? AppColors.indigo
                    : Color.lerp(
                        AppColors.chipBlueBg,
                        const Color(0xFFA5B4FC),
                        ratio,
                      ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              point.label,
              maxLines: 1,
              overflow: TextOverflow.clip,
              style: TextStyle(
                fontSize: 10,
                fontWeight: highlighted ? FontWeight.w800 : FontWeight.w700,
                color: highlighted ? AppColors.indigo : AppColors.textGhost,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.session});
  final SessionHistoryItem session;

  @override
  Widget build(BuildContext context) {
    final positive = session.score >= 7.5;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: rowDecoration,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.fieldBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.chat_bubble_outline,
              size: 20,
              color: Color(0xFF555555),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  session.subtitle,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textGhost,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: positive ? AppColors.chipGreenBg : AppColors.chipOrangeBg,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              session.score.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: positive
                    ? AppColors.chipGreenFg
                    : AppColors.chipOrangeFg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


/// "Bậc theo tiêu chí" — thước đo tiến bộ không co giãn.
///
/// Đặt ngay dưới thẻ điểm trung bình là có chủ đích: điểm ở trên trả lời "buổi vừa rồi thế
/// nào", thẻ này trả lời "mình có khá lên không" — và hai câu đó có thể ngược nhau. Điểm
/// đứng yên trong khi bậc đi lên nghĩa là em ấy đang trả lời được những câu khó hơn ở cùng
/// mức hoàn thành.
class _BandTrendCard extends StatelessWidget {
  const _BandTrendCard({required this.trends});
  final List<CriterionBandTrend> trends;

  static const labels = {
    'GRAMMAR': 'Ngữ pháp',
    'VOCABULARY': 'Từ vựng',
    'COHERENCE': 'Mạch lạc',
    'PRONUNCIATION': 'Phát âm',
    'FLUENCY': 'Lưu loát',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionLabel('BẬC THEO TIÊU CHÍ'),
          const SizedBox(height: 4),
          const Text(
            'Bậc mà câu trả lời thực sự đạt được — không phụ thuộc bậc mục tiêu, nên so được giữa các buổi.',
            style: TextStyle(fontSize: 12, height: 1.35, color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          // Luôn liệt kê ĐỦ 5 tiêu chí, kể cả tiêu chí chưa có dữ liệu. Bản trước chỉ vẽ
          // những tiêu chí có bậc, nên tiêu chí thiếu lặng lẽ biến mất -- học sinh thấy 4 dòng
          // mà không biết dòng thứ 5 là "chưa đo được" hay "không tồn tại". Mà thiếu là chuyện
          // xảy ra thật: bản chấm bị đánh dấu độ tin cậy thấp, hoặc mô hình trả về mã bậc
          // không hợp lệ và bị chốt chặn loại đi.
          for (int i = 0; i < labels.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            () {
              final code = labels.keys.elementAt(i);
              final match = trends.where((t) => t.criterionCode.toUpperCase() == code);
              return match.isEmpty
                  ? _MissingBandRow(label: labels[code]!)
                  : _BandTrendRow(trend: match.first);
            }(),
          ],
          if (trends.isNotEmpty && !trends.any((t) => t.hasExam)) ...[
            const SizedBox(height: 12),
            const Text(
              'Số liệu chỉ từ bài luyện. Độ khó câu luyện bám theo trình độ hiện tại, nên đường này thường phẳng hơn thực tế — bài thi phản ánh đúng hơn.',
              style: TextStyle(
                fontSize: 11.5,
                height: 1.35,
                color: AppColors.textFaint,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Tiêu chí chưa có bậc nào trong khoảng đang xem.
///
/// Nói ra thay vì bỏ trống: "chưa đo được" là một thông tin, còn một dòng biến mất thì học
/// sinh không phân biệt được với "không có tiêu chí này".
class _MissingBandRow extends StatelessWidget {
  const _MissingBandRow({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.muted,
            ),
          ),
        ),
        const Text(
          'chưa đo được',
          style: TextStyle(fontSize: 12.5, color: AppColors.textFaint),
        ),
      ],
    );
  }
}

class _BandTrendRow extends StatelessWidget {
  const _BandTrendRow({required this.trend});
  final CriterionBandTrend trend;

  @override
  Widget build(BuildContext context) {
    final delta = trend.delta;
    // Ngưỡng 0.05 bậc: dưới mức đó là nhiễu làm tròn, vẽ mũi tên vào sẽ nói một điều mà dữ
    // liệu không nói.
    final meaningful = delta != null && delta.abs() >= 0.05;
    final better = (delta ?? 0) > 0;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _BandTrendCard.labels[trend.criterionCode.toUpperCase()] ??
                    trend.criterionCode,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${trend.observationCount} lần chấm',
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.textFaint,
                ),
              ),
            ],
          ),
        ),
        Text(
          trend.bandLabel,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.indigo,
          ),
        ),
        if (meaningful) ...[
          const SizedBox(width: 8),
          Icon(
            better ? Icons.arrow_upward : Icons.arrow_downward,
            size: 14,
            color: better ? AppColors.chipGreenFg : AppColors.danger,
          ),
          Text(
            delta.abs().toStringAsFixed(1).replaceAll('.', ','),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: better ? AppColors.chipGreenFg : AppColors.danger,
            ),
          ),
        ],
      ],
    );
  }
}
