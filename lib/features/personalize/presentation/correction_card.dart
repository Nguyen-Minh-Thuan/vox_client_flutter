import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../app/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../data/models/practice_session.dart';
import 'personalize_styles.dart';

/// Design `1c` — the "SỬA NGAY" bubble that sits right under the learner's
/// turn, offset to the right so it reads as a reply to that turn.
class CorrectionCard extends StatelessWidget {
  const CorrectionCard({
    super.key,
    required this.turn,
    required this.onHearCorrect,
    required this.onSayAgain,
  });

  final PracticeTurn turn;
  final VoidCallback onHearCorrect;
  final VoidCallback onSayAgain;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final score = turn.score;

    return Align(
      alignment: Alignment.centerRight,
      child: FractionallySizedBox(
        widthFactor: 0.88,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(4),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            border: Border.all(color: AppColors.border, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.dark.withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ──
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                decoration: const BoxDecoration(
                  color: AppColors.headerBg,
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFF1F1F1)),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.edit_note, size: 16, color: AppColors.indigo),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        l10n.pzSessionCorrectNow(turn.corrections.length),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: Color(0xFF555555),
                        ),
                      ),
                    ),
                    if (score != null)
                      Text(
                        '${score.toStringAsFixed(1)}/10',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: score >= 8
                              ? AppColors.success
                              : AppColors.textGhost,
                        ),
                      ),
                  ],
                ),
              ),

              // ── Rows ──
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < turn.corrections.length; i++) ...[
                      if (i > 0) const SizedBox(height: 12),
                      _CorrectionRow(correction: turn.corrections[i]),
                    ],
                  ],
                ),
              ),

              // ── Footer actions ──
              const Divider(height: 1, color: Color(0xFFF1F1F1)),
              IntrinsicHeight(
                child: Row(
                  children: [
                    Expanded(
                      child: _FooterAction(
                        icon: Icons.volume_up,
                        label: l10n.pzSessionHearCorrect,
                        color: AppColors.indigo,
                        onTap: onHearCorrect,
                      ),
                    ),
                    const VerticalDivider(width: 1, color: Color(0xFFF1F1F1)),
                    Expanded(
                      child: _FooterAction(
                        icon: Icons.replay,
                        label: l10n.pzSessionSayAgain,
                        color: const Color(0xFF555555),
                        onTap: onSayAgain,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CorrectionRow extends StatelessWidget {
  const _CorrectionRow({required this.correction});
  final Correction correction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final style = styleForCorrection(correction.type);
    final hasDiff = correction.before != null && correction.after != null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: style.background,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(style.icon, size: 14, color: style.foreground),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasDiff)
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: correction.before,
                        style: TextStyle(
                          color: correction.type == CorrectionType.vocabulary
                              ? const Color(0xFF666666)
                              : AppColors.danger,
                          decoration:
                              correction.type == CorrectionType.vocabulary
                                  ? null
                                  : TextDecoration.lineThrough,
                        ),
                      ),
                      const TextSpan(
                        text: '  →  ',
                        style: TextStyle(color: AppColors.textGhost),
                      ),
                      TextSpan(
                        text: correction.after,
                        style: TextStyle(
                          color: correction.type == CorrectionType.vocabulary
                              ? const Color(0xFF7C3AED)
                              : AppColors.chipGreenFg,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  style: const TextStyle(fontSize: 13, height: 1.5),
                )
              else
                Text(
                  correction.headline ?? '',
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
              const SizedBox(height: 3),
              Text(
                correction.note,
                style: const TextStyle(
                  fontSize: 11.5,
                  height: 1.4,
                  color: AppColors.textMuted,
                ),
              ),
              if (correction.accuracy != null) ...[
                const SizedBox(height: 7),
                Row(
                  children: [
                    Expanded(
                      child: MeterBar(
                        ratio: correction.accuracy!,
                        color: AppColors.success,
                        height: 6,
                        track: AppColors.borderSoft,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(correction.accuracy! * 100).round()}%',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.chipGreenFg,
                      ),
                    ),
                  ],
                ),
              ],
              if (correction.repeatCount != null) ...[
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TagChip.orange(
                    l10n.pzSessionKnownWeakness(correction.repeatCount!),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _FooterAction extends StatelessWidget {
  const _FooterAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Renders a learner transcript with wavy underlines over the flagged ranges.
class TranscriptText extends StatelessWidget {
  const TranscriptText({
    super.key,
    required this.text,
    required this.spans,
    required this.baseStyle,
  });

  final String text;
  final List<ErrorSpan> spans;
  final TextStyle baseStyle;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(children: _buildSpans()),
      style: baseStyle,
    );
  }

  List<InlineSpan> _buildSpans() {
    if (spans.isEmpty) return [TextSpan(text: '“$text”')];

    // Sort by position and drop anything that overlaps what we already emitted
    // or runs past the end of the transcript — the ranges come from the model
    // and must never be trusted to line up.
    final ordered = [...spans]..sort((a, b) => a.start.compareTo(b.start));

    final result = <InlineSpan>[const TextSpan(text: '“')];
    var cursor = 0;
    for (final span in ordered) {
      final start = span.start;
      final end = span.end;
      if (start < cursor || start >= text.length || end > text.length) continue;
      if (start > cursor) {
        result.add(TextSpan(text: text.substring(cursor, start)));
      }
      result.add(
        TextSpan(
          text: text.substring(start, end),
          style: TextStyle(
            decoration: TextDecoration.underline,
            decorationStyle: TextDecorationStyle.wavy,
            decorationColor: styleForCorrection(span.type).underline,
            decorationThickness: 1.5,
          ),
        ),
      );
      cursor = end;
    }
    if (cursor < text.length) {
      result.add(TextSpan(text: text.substring(cursor)));
    }
    result.add(const TextSpan(text: '”'));
    return result;
  }
}
