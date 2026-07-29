import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../app/widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/onboarding_question.dart';

/// Design `1a`, screen 1 — one single-choice question of the questionnaire.
class FlasQuizStep extends StatelessWidget {
  const FlasQuizStep({
    super.key,
    required this.question,
    required this.selectedIndex,
    required this.canGoBack,
    required this.onSelect,
    required this.onBack,
    required this.onContinue,
  });

  final OnboardingQuestion question;
  final int? selectedIndex;
  final bool canGoBack;
  final ValueChanged<int> onSelect;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.chipBlueBg,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.psychology_outlined,
                          size: 14, color: AppColors.indigo),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          question.categoryLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.indigo,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                question.prompt,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  height: 1.35,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 18),
              for (int i = 0; i < question.options.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                _OptionTile(
                  label: question.options[i],
                  selected: selectedIndex == i,
                  onTap: () => onSelect(i),
                ),
              ],
              const SizedBox(height: 20),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.warnBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_outline,
                        size: 18, color: AppColors.warnFg),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.pzOnboardingQuizTip,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.45,
                          color: AppColors.warnFg,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              if (canGoBack) ...[
                Expanded(
                  child: SizedBox(
                    height: 54,
                    child: OutlinedButton(
                      onPressed: onBack,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF555555),
                        side: const BorderSide(
                            color: Color(0xFFE6E6E6), width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(99),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: Text(l10n.pzOnboardingBack),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                flex: 2,
                child: GradientButton(
                  label: l10n.pzOnboardingContinue,
                  icon: Icons.arrow_forward,
                  // Answering is required before moving on.
                  onTap: selectedIndex == null ? null : onContinue,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.chipBlueBg : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.indigo : AppColors.border,
            width: 1.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.indigo.withValues(alpha: 0.13),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(
                  color: selected ? AppColors.indigo : const Color(0xFFDDDDDD),
                  width: selected ? 6 : 2,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: selected ? const Color(0xFF312E81) : const Color(0xFF222222),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
