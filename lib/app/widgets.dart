import 'package:flutter/material.dart';

import 'theme.dart';

/// Rounded "chip" label (Intermediate, 15 min, Open, etc.).
class TagChip extends StatelessWidget {
  const TagChip(
    this.label, {
    super.key,
    this.bg = AppColors.chipNeutralBg,
    this.fg = AppColors.chipNeutralFg,
    this.dot = false,
  });

  final String label;
  final Color bg;
  final Color fg;
  final bool dot;

  const TagChip.blue(String label, {Key? key})
      : this(label, key: key, bg: AppColors.chipBlueBg, fg: AppColors.chipBlueFg);
  const TagChip.green(String label, {Key? key})
      : this(label, key: key, bg: AppColors.chipGreenBg, fg: AppColors.chipGreenFg);
  const TagChip.orange(String label, {Key? key})
      : this(label, key: key, bg: AppColors.chipOrangeBg, fg: AppColors.chipOrangeFg);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Text('● ', style: TextStyle(color: fg, fontSize: 11, height: 1)),
          ],
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Uppercase tracking-spaced section heading.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textMuted,
        letterSpacing: 0.8,
      ),
    );
  }
}

/// Circular outlined icon button used in the app bars.
class IconCircle extends StatelessWidget {
  const IconCircle(this.icon, {super.key, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE0E0E0), width: 1.5),
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF444444)),
      ),
    );
  }
}
