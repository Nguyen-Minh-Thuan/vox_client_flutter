import 'package:flutter/material.dart';

import '../../../app/theme.dart';

/// New Appeal form — submit a request to re-evaluate a graded attempt.
class NewAppealScreen extends StatefulWidget {
  const NewAppealScreen({super.key});

  @override
  State<NewAppealScreen> createState() => _NewAppealScreenState();
}

class _NewAppealScreenState extends State<NewAppealScreen> {
  int? _exam = 0;
  final Set<int> _criteria = {};
  final _reason = TextEditingController();
  bool _agree = false;

  static const _exams = [
    ('Mid-term Speaking Exam', 'Unit 3 · Jun 22 · Score 6.5'),
    ('Role-Play: At the Airport', 'Unit 5 · Jun 24 · Score 7.0'),
    ('Describing a Picture', 'Unit 4 · Jun 25 · Score 7.8'),
  ];

  static const _criteriaLabels = [
    'Pronunciation',
    'Fluency',
    'Grammar',
    'Vocabulary',
    'Content',
  ];

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  bool get _valid =>
      _exam != null &&
      _criteria.isNotEmpty &&
      _reason.text.trim().length >= 10 &&
      _agree;

  void _submit() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _SubmittedSheet(),
    ).then((_) {
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.dark),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'New Appeal',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.dark,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: AppColors.chipBlueBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(Icons.info_outline, size: 18, color: AppColors.indigo),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'A teacher will manually re-check the criteria you select. '
                    'You can appeal within 7 days of a result.',
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.45,
                      color: Color(0xFF3730A3),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const _FieldLabel('Select attempt', required: true),
          const SizedBox(height: 10),
          for (int i = 0; i < _exams.length; i++) ...[
            _ExamOption(
              title: _exams[i].$1,
              meta: _exams[i].$2,
              selected: _exam == i,
              onTap: () => setState(() => _exam = i),
            ),
            if (i != _exams.length - 1) const SizedBox(height: 8),
          ],
          const SizedBox(height: 24),

          const _FieldLabel('Criteria to re-evaluate', required: true),
          const SizedBox(height: 4),
          const Text(
            'Select all that you think were scored unfairly.',
            style: TextStyle(fontSize: 12.5, color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (int i = 0; i < _criteriaLabels.length; i++)
                _ChoiceChip(
                  label: _criteriaLabels[i],
                  selected: _criteria.contains(i),
                  onTap: () => setState(() {
                    _criteria.contains(i)
                        ? _criteria.remove(i)
                        : _criteria.add(i);
                  }),
                ),
            ],
          ),
          const SizedBox(height: 24),

          const _FieldLabel('Reason for appeal', required: true),
          const SizedBox(height: 10),
          TextField(
            controller: _reason,
            onChanged: (_) => setState(() {}),
            maxLines: 5,
            maxLength: 400,
            style: const TextStyle(fontSize: 14, height: 1.5),
            decoration: InputDecoration(
              hintText:
                  'Explain why you believe the score should be reviewed…',
              hintStyle:
                  const TextStyle(fontSize: 14, color: AppColors.textGhost),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: AppColors.indigo, width: 1.6),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Agreement
          GestureDetector(
            onTap: () => setState(() => _agree = !_agree),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: _agree ? AppColors.indigo : Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _agree
                          ? AppColors.indigo
                          : const Color(0xFFCBD5E1),
                      width: 1.6,
                    ),
                  ),
                  child: _agree
                      ? const Icon(Icons.check, size: 15, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 11),
                const Expanded(
                  child: Text(
                    'I understand the re-evaluated score is final and may be '
                    'higher, lower, or unchanged.',
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.45,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          FilledButton(
            onPressed: _valid ? _submit : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.indigo,
              disabledBackgroundColor: const Color(0xFFCBD5E1),
              minimumSize: const Size(0, 54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(99),
              ),
              textStyle:
                  const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700),
            ),
            child: const Text('Submit appeal'),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text, {this.required = false});
  final String text;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: AppColors.dark,
          ),
        ),
        if (required)
          const Text(' *', style: TextStyle(color: AppColors.danger)),
      ],
    );
  }
}

class _ExamOption extends StatelessWidget {
  const _ExamOption({
    required this.title,
    required this.meta,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String meta;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.chipBlueBg : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.indigo : const Color(0xFFE2E8F0),
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.dark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    meta,
                    style:
                        const TextStyle(fontSize: 12.5, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.indigo : Colors.transparent,
                border: Border.all(
                  color: selected ? AppColors.indigo : const Color(0xFFCBD5E1),
                  width: 1.6,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.indigo : Colors.white,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: selected ? AppColors.indigo : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}

class _SubmittedSheet extends StatelessWidget {
  const _SubmittedSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          Container(
            width: 68,
            height: 68,
            decoration: const BoxDecoration(
              color: Color(0xFFECFDF5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle,
                size: 40, color: AppColors.success),
          ),
          const SizedBox(height: 18),
          const Text(
            'Appeal submitted',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your request is now pending. A teacher will review it within '
            '3 school days — you’ll get a notification when it’s resolved.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, height: 1.5, color: AppColors.muted),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).maybePop(),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.indigo,
                minimumSize: const Size(0, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(99),
                ),
                textStyle:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }
}
