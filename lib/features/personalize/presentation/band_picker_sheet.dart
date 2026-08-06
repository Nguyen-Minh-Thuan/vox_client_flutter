import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../data/models/practice_band_option.dart';
import '../data/personalize_repository.dart';

/// Ô chọn ĐỘ KHÓ trước khi vào phiên luyện.
///
/// Vì sao có màn này: trước đây hệ thống tự suy ra bậc của học sinh (bậc đo được từ bài
/// chấm + EMA hiệu năng luyện gần đây + lần bỏ dở gần nhất theo chủ đề) rồi ra đề theo bậc
/// đó. Suy như vậy là lấy độ khó của CÂU HỎI gán thành trình độ của NGƯỜI HỌC -- và học
/// sinh thì không nhìn thấy bậc mình đang bị xếp, nên điểm số trôi theo một hệ quy chiếu
/// ẩn. Giờ độ khó là lựa chọn hiển nhiên của người học, chọn lại mỗi phiên.
///
/// Chọn MỘT lần cho cả phiên chứ không theo từng chủ đề: nếu mỗi thẻ chủ đề mang một mức
/// riêng thì học sinh bấm thẻ dễ hơn, còn hệ thống ghi nhận đó là sở thích -- tín hiệu
/// sở thích bị nhiễm bởi độ khó.
Future<PracticeBandOption?> showBandPickerSheet(BuildContext context) {
  return showModalBottomSheet<PracticeBandOption>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _BandPickerSheet(),
  );
}

class _BandPickerSheet extends StatefulWidget {
  const _BandPickerSheet();

  @override
  State<_BandPickerSheet> createState() => _BandPickerSheetState();
}

class _BandPickerSheetState extends State<_BandPickerSheet> {
  final _repository = PersonalizeRepository();

  bool _loading = true;
  String? _error;
  List<PracticeBandOption> _options = const [];
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await _repository.getPracticeBandOptions();
      if (!mounted) return;
      setState(() {
        _options = result.options;
        // Chọn sẵn bậc mục tiêu của trường -- một điểm khởi đầu có cơ sở, không phải
        // tuyên bố "đây là trình độ của em". Học sinh đổi thoải mái.
        _selectedId = _options
            .where((o) => o.code == result.defaultCode)
            .map((o) => o.id)
            .firstOrNull;
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
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderSoft,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Chọn độ khó cho buổi luyện',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            const Text(
              'Câu hỏi sẽ được chọn quanh mức em chọn. Buổi sau đổi lại được.',
              style: TextStyle(fontSize: 13, color: AppColors.textFaint),
            ),
            const SizedBox(height: 14),
            Expanded(child: _body(scrollController)),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: _selectedId == null
                    ? null
                    : () => Navigator.of(context).pop(
                        _options.firstWhere((o) => o.id == _selectedId),
                      ),
                child: const Text('Bắt đầu'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(ScrollController scrollController) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Text(_error!, textAlign: TextAlign.center),
      );
    }
    if (_options.isEmpty) {
      return const Center(
        child: Text(
          'Trường chưa cấu hình thang bậc nào cho khung đánh giá đang dùng.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textFaint),
        ),
      );
    }
    return ListView.separated(
      controller: scrollController,
      itemCount: _options.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, index) {
        final option = _options[index];
        final selected = option.id == _selectedId;
        return InkWell(
          onTap: () => setState(() => _selectedId = option.id),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? AppColors.indigo : AppColors.borderSoft,
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 20,
                  color: selected ? AppColors.indigo : AppColors.muted,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.label,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if ((option.description ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          option.description!,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textFaint,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
