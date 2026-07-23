import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../app/widgets.dart';
import '../../appeal/presentation/appeals_screen.dart';

/// Results / Performance Review screen shown after a speaking practice or exam.
class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  // Per-criterion scores (0–10) with the school's default weights.
  static const _criteria = [
    _Criterion('Pronunciation', 8.0, 0.25, AppColors.indigo),
    _Criterion('Fluency', 7.5, 0.20, AppColors.secondary),
    _Criterion('Grammar', 7.0, 0.20, AppColors.accent),
    _Criterion('Vocabulary', 8.5, 0.20, AppColors.success),
    _Criterion('Content', 7.5, 0.15, AppColors.warning),
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
          'Your Results',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.dark,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share, size: 20, color: AppColors.dark),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const _ScoreHero(),
          const SizedBox(height: 20),

          // ── Recording playback ──
          const _RecordingBar(),
          const SizedBox(height: 24),

          const SectionLabel('Criteria Breakdown'),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                for (int i = 0; i < _criteria.length; i++) ...[
                  _CriterionRow(_criteria[i]),
                  if (i != _criteria.length - 1)
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── AI feedback ──
          const SectionLabel('AI Feedback'),
          const SizedBox(height: 14),
          const _FeedbackCard(
            tone: _FeedbackTone.good,
            title: 'Strong vocabulary range',
            body: 'You used varied, topic-appropriate words like '
                '"algorithm" and "misinformation" naturally.',
          ),
          const SizedBox(height: 10),
          const _FeedbackCard(
            tone: _FeedbackTone.improve,
            title: 'Watch your pacing',
            body: 'A few long pauses between ideas lowered your fluency '
                'score. Try linking phrases with "because" or "so".',
          ),
          const SizedBox(height: 28),

          // ── Actions ──
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.indigo,
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    minimumSize: const Size(0, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(99),
                    ),
                    textStyle: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  child: const Text('Try again'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.indigo,
                    minimumSize: const Size(0, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(99),
                    ),
                    textStyle: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
          // const SizedBox(height: 14),
          // Center(
          //   child: TextButton.icon(
          //     onPressed: () => Navigator.of(context).push(
          //       MaterialPageRoute(builder: (_) => const AppealsScreen()),
          //     ),
          //     icon: const Icon(Icons.gavel_outlined, size: 17),
          //     label: const Text('Disagree with this score? Request re-evaluation'),
          //     style: TextButton.styleFrom(
          //       foregroundColor: AppColors.muted,
          //       textStyle:
          //           const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
}

class _ScoreHero extends StatelessWidget {
  const _ScoreHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.indigo, AppColors.secondary],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Text(
            'TALKING ABOUT SOCIAL MEDIA · UNIT 3',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: Colors.white.withOpacity(0.75),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Text(
                '7.7',
                style: TextStyle(
                  fontSize: 60,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1,
                ),
              ),
              Text(
                ' / 10',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(99),
            ),
            child: const Text(
              'Good · Above class average',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.indigo,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordingBar extends StatelessWidget {
  const _RecordingBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.indigo,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.play_arrow, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your recording',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: Container(
                    height: 4,
                    color: const Color(0xFFE2E8F0),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: 0.0,
                      child: Container(color: AppColors.indigo),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            '0:48',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _Criterion {
  const _Criterion(this.name, this.score, this.weight, this.color);
  final String name;
  final double score;
  final double weight;
  final Color color;
}

class _CriterionRow extends StatelessWidget {
  const _CriterionRow(this.c);
  final _Criterion c;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          SizedBox(
            width: 116,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.dark,
                  ),
                ),
                Text(
                  '${(c.weight * 100).round()}% weight',
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                ),
              ],
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: Container(
                height: 8,
                color: const Color(0xFFF1F5F9),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: c.score / 10,
                  child: Container(color: c.color),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 42,
            child: Text(
              c.score.toStringAsFixed(1),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.dark,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _FeedbackTone { good, improve }

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({
    required this.tone,
    required this.title,
    required this.body,
  });

  final _FeedbackTone tone;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final good = tone == _FeedbackTone.good;
    final color = good ? AppColors.success : AppColors.warning;
    final bg = good ? const Color(0xFFECFDF5) : AppColors.warnBg;
    final icon = good ? Icons.check_circle : Icons.lightbulb_outline;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
