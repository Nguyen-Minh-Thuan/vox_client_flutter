import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../app/widgets.dart';
import '../../appeal/presentation/new_appeal_screen.dart';

/// Appeals & Re-evaluation list — formal requests for score re-checks.
class AppealsScreen extends StatelessWidget {
  const AppealsScreen({super.key});

  static const _appeals = [
    _Appeal(
      exam: 'Mid-term Speaking Exam',
      unit: 'Unit 3 · Class 10A2',
      submitted: 'Jun 22, 2026',
      status: _AppealStatus.adjusted,
      original: 6.5,
      revised: 7.5,
      note: 'Reviewed by Ms. Linh — pronunciation re-scored.',
    ),
    _Appeal(
      exam: 'Role-Play: At the Airport',
      unit: 'Unit 5 · Homework',
      submitted: 'Jun 24, 2026',
      status: _AppealStatus.underReview,
      original: 7.0,
      reason: 'The AI cut off my last sentence before I finished.',
    ),
    _Appeal(
      exam: 'Describing a Picture',
      unit: 'Unit 4 · Class 10A2',
      submitted: 'Jun 25, 2026',
      status: _AppealStatus.pending,
      original: 7.8,
      reason: 'I believe my fluency was scored too low.',
    ),
    _Appeal(
      exam: 'Unit 2 Pronunciation Drill',
      unit: 'Unit 2 · Practice',
      submitted: 'Jun 18, 2026',
      status: _AppealStatus.rejected,
      original: 8.0,
      note: 'Score upheld — original assessment was accurate.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.dark),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Appeals',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.dark,
          ),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const NewAppealScreen()),
        ),
        backgroundColor: AppColors.indigo,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add, size: 20),
        label: const Text(
          'New appeal',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
        children: [
          // Summary strip
          Row(
            children: const [
              Expanded(child: _SummaryBox(value: '1', label: 'Pending')),
              SizedBox(width: 10),
              Expanded(child: _SummaryBox(value: '1', label: 'In review')),
              SizedBox(width: 10),
              Expanded(child: _SummaryBox(value: '2', label: 'Resolved')),
            ],
          ),
          const SizedBox(height: 22),
          const SectionLabel('Your Requests'),
          const SizedBox(height: 14),
          for (int i = 0; i < _appeals.length; i++) ...[
            _AppealCard(_appeals[i]),
            if (i != _appeals.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _SummaryBox extends StatelessWidget {
  const _SummaryBox({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

enum _AppealStatus { pending, underReview, adjusted, rejected }

extension _StatusMeta on _AppealStatus {
  String get label => switch (this) {
        _AppealStatus.pending => 'Pending',
        _AppealStatus.underReview => 'Under review',
        _AppealStatus.adjusted => 'Score adjusted',
        _AppealStatus.rejected => 'Rejected',
      };
  Color get fg => switch (this) {
        _AppealStatus.pending => AppColors.warnFg,
        _AppealStatus.underReview => AppColors.indigo,
        _AppealStatus.adjusted => AppColors.success,
        _AppealStatus.rejected => AppColors.muted,
      };
  Color get bg => switch (this) {
        _AppealStatus.pending => AppColors.warnBg,
        _AppealStatus.underReview => AppColors.chipBlueBg,
        _AppealStatus.adjusted => const Color(0xFFECFDF5),
        _AppealStatus.rejected => AppColors.statusClosedBg,
      };
  IconData get icon => switch (this) {
        _AppealStatus.pending => Icons.hourglass_empty,
        _AppealStatus.underReview => Icons.search,
        _AppealStatus.adjusted => Icons.check_circle,
        _AppealStatus.rejected => Icons.cancel_outlined,
      };
}

class _Appeal {
  const _Appeal({
    required this.exam,
    required this.unit,
    required this.submitted,
    required this.status,
    required this.original,
    this.revised,
    this.reason,
    this.note,
  });

  final String exam;
  final String unit;
  final String submitted;
  final _AppealStatus status;
  final double original;
  final double? revised;
  final String? reason;
  final String? note;
}

class _AppealCard extends StatelessWidget {
  const _AppealCard(this.a);
  final _Appeal a;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.exam,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.dark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      a.unit,
                      style: const TextStyle(
                          fontSize: 12.5, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              _StatusPill(a.status),
            ],
          ),
          const SizedBox(height: 12),

          // Score row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Row(
              children: [
                _ScoreChip(label: 'Original', value: a.original),
                if (a.revised != null) ...[
                  const SizedBox(width: 10),
                  const Icon(Icons.arrow_forward,
                      size: 16, color: AppColors.muted),
                  const SizedBox(width: 10),
                  _ScoreChip(
                    label: 'Revised',
                    value: a.revised!,
                    highlight: true,
                  ),
                ],
                const Spacer(),
                Text(
                  a.submitted,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),

          if (a.reason != null) ...[
            const SizedBox(height: 12),
            Text(
              '“${a.reason}”',
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                fontStyle: FontStyle.italic,
                color: Color(0xFF475569),
              ),
            ),
          ],
          if (a.note != null) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(a.status.icon, size: 16, color: a.status.fg),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    a.note!,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                      color: a.status.fg,
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

class _StatusPill extends StatelessWidget {
  const _StatusPill(this.status);
  final _AppealStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: status.bg,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 13, color: status.fg),
          const SizedBox(width: 5),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: status.fg,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  const _ScoreChip({
    required this.label,
    required this.value,
    this.highlight = false,
  });
  final String label;
  final double value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          value.toStringAsFixed(1),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: highlight ? AppColors.success : AppColors.dark,
          ),
        ),
      ],
    );
  }
}