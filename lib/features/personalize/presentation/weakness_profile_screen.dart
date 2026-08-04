import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../app/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../data/models/learner_band.dart';
import '../data/models/weakness.dart';
import '../data/personalize_repository.dart';
import 'personalize_styles.dart';
import 'personalize_widgets.dart';
import 'progress_screen.dart';

/// Design `1f`, screen 2 — the tracked error profile.
///
/// Real `myWeaknessProfile` — grouped by whatever criteria the school's
/// rubric actually configures (NOT a fixed grammar/pronunciation/expression
/// 3-way split, since real rubric criteria are a school-configurable list).
class WeaknessProfileScreen extends StatefulWidget {
  const WeaknessProfileScreen({super.key});

  @override
  State<WeaknessProfileScreen> createState() => _WeaknessProfileScreenState();
}

class _WeaknessProfileScreenState extends State<WeaknessProfileScreen> {
  final _repository = PersonalizeRepository();

  bool _loading = true;
  String? _error;
  WeaknessProfile? _profile;

  /// Bậc năng lực -- tải song song và KHÔNG chặn màn hình: hồ sơ điểm yếu vẫn xem được
  /// nếu query bậc lỗi, nên lỗi ở đây chỉ làm ẩn thẻ bậc chứ không đẩy cả màn vào error.
  LearnerBand? _band;

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
      // Hai query độc lập -> chạy song song. Bậc năng lực nuốt lỗi riêng (xem _band).
      final results = await Future.wait([
        _repository.getWeaknessProfile(),
        _repository
            .getLearnerBand()
            .then<LearnerBand?>((b) => b)
            .catchError((_) => null),
      ]);
      if (!mounted) return;
      setState(() {
        _profile = results[0] as WeaknessProfile;
        _band = results[1] as LearnerBand?;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.pzWeaknessTitle)),
      body: switch ((_loading, _error, _profile)) {
        (true, _, _) => const Center(child: CircularProgressIndicator()),
        (_, final String error, _) => PersonalizeErrorView(
          detail: error,
          onRetry: _load,
        ),
        (_, _, null) => PersonalizeErrorView(onRetry: _load),
        (_, _, final WeaknessProfile profile) => _buildBody(l10n, profile),
      },
    );
  }

  Widget _buildBody(AppLocalizations l10n, WeaknessProfile profile) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
              if (_band != null) ...[
                _BandCard(band: _band!),
                const SizedBox(height: 12),
              ],
              // Hồ sơ HỌC TẬP nằm cạnh hồ sơ ĐIỂM YẾU: cùng là "hồ sơ của tôi", tách ra hai
              // đường vào khác nhau thì học sinh phải nhớ cái nào ở đâu. ProgressScreen vốn
              // đã viết xong từ trước nhưng chưa có nút nào dẫn tới -- đây là nút đó.
              _LearningProfileTile(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProgressScreen()),
                ),
              ),
              const SizedBox(height: 12),
              _SummaryCard(profile: profile),
              for (final criterion in profile.criteria) ...[
                const SizedBox(height: 20),
                // Tiêu đề nhóm mang LUÔN mức nặng/nhẹ và số lần của tiêu chí. Bản trước có
                // thêm một thẻ _WeaknessRow ngay dưới với đúng cái tên vừa in ở tiêu đề
                // ("NGỮ PHÁP" rồi "Ngữ pháp") -- chiếm trọn một thẻ để nói lại điều vừa nói.
                _CriterionHeader(
                  name: criterion.criterionName,
                  severity: criterion.severity,
                  detail: l10n.pzWeaknessObservations(
                    criterion.observationCount,
                  ),
                ),
                const SizedBox(height: 10),
                if (profile.subAttributesFor(criterion.criterionCode).isEmpty)
                  const _NoLabelYetNote(),
                for (final sub in profile.subAttributesFor(
                  criterion.criterionCode,
                )) ...[
                  const SizedBox(height: 8),
                  _WeaknessRow(
                    title: sub.displayLabel,
                    severity: sub.severity,
                    ratio: sub.ratio,
                    detail: l10n.pzWeaknessOccurrences(sub.occurrenceCount),
                    trendPercent: sub.trendPercent,
                    examples: sub.examples,
                    nearlyFixed: sub.nearlyFixed,
                  ),
                ],
              ],
      ],
    );
  }
}

/// Đường vào hồ sơ học tập ([ProgressScreen]) — điểm trung bình và các buổi gần đây.
class _LearningProfileTile extends StatelessWidget {
  const _LearningProfileTile({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: cardDecoration,
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.chipBlueBg,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.insights,
                  size: 20,
                  color: AppColors.chipBlueFg,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.pzLearningProfile,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.pzLearningProfileHint,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 22,
                color: AppColors.textFaint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bậc năng lực hiện tại so với bậc mục tiêu của trường.
///
/// Hai bậc này là HAI KHÁI NIỆM KHÁC NHAU và không được trộn: bậc ước lượng là trình độ
/// suy từ lịch sử chấm của chính học sinh, bậc mục tiêu do trường đặt trong chính sách
/// chấm. Chưa đủ dữ liệu thì nói thẳng "chưa đủ", không lấy mục tiêu ra thế chỗ.
class _BandCard extends StatelessWidget {
  const _BandCard({required this.band});
  final LearnerBand band;

  @override
  Widget build(BuildContext context) {
    final percent = band.targetAttainmentPercent;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.indigo,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trình độ hiện tại',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    band.hasEstimate ? band.estimatedCode! : 'Chưa đủ dữ liệu',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'mục tiêu ${band.targetLabel}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ),
            ],
          ),
          if (!band.hasEstimate) ...[
            const SizedBox(height: 6),
            Text(
              'Cần khoảng 5 lượt chấm (thi hoặc luyện) để ước lượng được bậc.',
              style: TextStyle(
                fontSize: 11.5,
                height: 1.35,
                color: Colors.white.withValues(alpha: 0.65),
              ),
            ),
          ],
          if (percent != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: (percent / 100).clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: Colors.white.withValues(alpha: 0.22),
                valueColor: const AlwaysStoppedAnimation(Colors.white),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Đã đạt ${percent.toStringAsFixed(0)}% so với bậc mục tiêu',
              style: TextStyle(
                fontSize: 11.5,
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The black counters card — all 3 numbers real (`sessionsAnalysed` counts
/// distinct graded evaluations in the observation window; `nearlyFixed`/
/// `newlyFound` come from comparing the real long-window vs recent-window
/// frequency the backend already tracks per sub-attribute).
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.profile});
  final WeaknessProfile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.pzWeaknessFromSessions(profile.sessionsAnalysed),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Counter(
                  value: profile.tracked,
                  label: l10n.pzWeaknessTracked,
                ),
              ),
              Expanded(
                child: _Counter(
                  value: profile.nearlyFixed,
                  label: l10n.pzWeaknessNearlyFixed,
                  color: const Color(0xFF34D399),
                ),
              ),
              Expanded(
                child: _Counter(
                  value: profile.newlyFound,
                  label: l10n.pzWeaknessNewlyFound,
                  color: const Color(0xFFFDBA74),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Counter extends StatelessWidget {
  const _Counter({
    required this.value,
    required this.label,
    this.color = Colors.white,
  });

  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$value',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            height: 1.3,
            color: Colors.white.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}

/// One weakness row — used for both criterion-level and sub-attribute-level
/// entries, since both share the same real shape (title/severity/ratio/detail).
/// Mũi tên xu hướng: sai NHIỀU hơn cửa sổ trước là xấu (đỏ, ↑), ít hơn là tốt (xanh, ↓).
///
/// Chiều tốt/xấu ở đây ngược với trực giác thông thường về mũi tên lên: đây là đồ thị LỖI,
/// nên đi lên nghĩa là đang tệ đi.
class _TrendChip extends StatelessWidget {
  const _TrendChip({required this.percent});
  final double percent;

  @override
  Widget build(BuildContext context) {
    final worse = percent > 0;
    final color = worse ? AppColors.danger : AppColors.success;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          worse ? Icons.arrow_upward : Icons.arrow_downward,
          size: 12,
          color: color,
        ),
        const SizedBox(width: 2),
        Text(
          '${percent.abs().round()}%',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Tiêu đề một tiêu chí, gộp luôn mức nặng/nhẹ và số quan sát.
///
/// Gộp vào tiêu đề thay vì tách thành một thẻ riêng bên dưới: thẻ đó lặp lại đúng cái tên vừa
/// in ở tiêu đề nhóm, tốn một khoảng màn hình để không nói thêm điều gì.
class _CriterionHeader extends StatelessWidget {
  const _CriterionHeader({
    required this.name,
    required this.severity,
    required this.detail,
  });

  final String name;
  final WeaknessSeverity severity;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = severityColors(severity);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionLabel(name),
              const SizedBox(height: 2),
              Text(
                detail,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.textFaint,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        TagChip(severityLabel(l10n, severity), bg: colors.bg, fg: colors.fg),
      ],
    );
  }
}

/// Tiêu chí đã có điểm nhưng chưa suy được nhãn cụ thể nào.
///
/// Nói thẳng là chưa đủ dữ liệu, thay vì để một khoảng trống câm khiến học sinh tưởng màn
/// hình lỗi.
class _NoLabelYetNote extends StatelessWidget {
  const _NoLabelYetNote();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 2, bottom: 2),
      child: Text(
        'Chưa đủ dữ liệu để chỉ ra lỗi cụ thể ở tiêu chí này.',
        style: TextStyle(fontSize: 12, color: AppColors.muted),
      ),
    );
  }
}

class _WeaknessRow extends StatefulWidget {
  const _WeaknessRow({
    required this.title,
    required this.severity,
    required this.ratio,
    required this.detail,
    this.trendPercent,
    this.examples = const [],
    this.nearlyFixed = false,
  });

  final String title;
  final WeaknessSeverity severity;
  final double ratio;
  final String detail;

  /// null = không đủ cơ sở để nói xu hướng; lúc đó không vẽ gì cả thay vì vẽ mũi tên phẳng.
  final double? trendPercent;

  /// Bằng chứng thật kèm số lần. Rỗng với nhãn suy từ số đo.
  final List<WeaknessExample> examples;

  /// Đang trên đà khỏi -- hiện nhạt đi và gắn nhãn, thay vì trông như lỗi đang hoạt động.
  final bool nearlyFixed;

  @override
  State<_WeaknessRow> createState() => _WeaknessRowState();
}

class _WeaknessRowState extends State<_WeaknessRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = widget.title;
    final severity = widget.severity;
    final ratio = widget.ratio;
    final detail = widget.detail;
    final trendPercent = widget.trendPercent;
    final examples = widget.examples;
    final nearlyFixed = widget.nearlyFixed;
    final colors = severityColors(severity);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: rowDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: examples.isEmpty
                ? null
                : () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                if (examples.isNotEmpty)
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 19,
                    color: AppColors.textMuted,
                  ),
                const SizedBox(width: 6),
                TagChip(
                  nearlyFixed ? 'SẮP KHẮC PHỤC' : severityLabel(l10n, severity),
                  bg: nearlyFixed ? AppColors.chipGreenBg : colors.bg,
                  fg: nearlyFixed ? AppColors.chipGreenFg : colors.fg,
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            detail,
            style: const TextStyle(fontSize: 11.5, color: AppColors.textFaint),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: MeterBar(
                  ratio: ratio,
                  color: severityBarColor(severity),
                  height: 6,
                  track: AppColors.borderSoft,
                ),
              ),
              if (trendPercent != null) ...[
                const SizedBox(width: 8),
                _TrendChip(percent: trendPercent),
              ],
            ],
          ),
          if (_expanded && examples.isNotEmpty) ...[
            const SizedBox(height: 10),
            // Cùng ngôn ngữ hình ảnh với "từ phát âm chưa đạt" ở màn tổng kết: chữ đỏ trên
            // nền đỏ nhạt, số lần ở bên phải. Học sinh gặp cùng một lỗi ở hai màn thì nên
            // nhận ra nó là cùng một thứ.
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final example in examples)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.dangerBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      example.label,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.danger,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
