import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../app/widgets.dart';
import '../../../core/network/graphql_client.dart';
import '../../appeal/presentation/new_appeal_screen.dart';
import '../../practice/presentation/attempt_recordings_screen.dart';
import '../data/models/exam_candidate_result.dart';
import '../data/models/exam_result_summary.dart';
import '../data/result_api.dart';
import '../data/result_repository.dart';
import 'results_list_screen.dart' show ResultStatusMeta;

/// Results / Performance Review screen shown after a speaking exam attempt.
class ResultsScreen extends StatefulWidget {
  const ResultsScreen({
    super.key,
    required this.sessionId,
    required this.examName,
    this.pageTitle = 'Kết quả bài kiểm tra',
  });

  final String sessionId;
  final String examName;
  final String pageTitle;

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final _repository = ResultRepository(ResultApi(GraphQLClient()));

  bool _loading = true;
  String? _error;
  ExamCandidateResult? _result;

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
      final result = await _repository.getSessionResult(widget.sessionId);
      if (!mounted) return;
      setState(() => _result = result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Could not load this result.\n$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
          icon: const Icon(Icons.arrow_back, color: AppColors.dark),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          widget.pageTitle,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.dark,
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!,
                          style: const TextStyle(color: AppColors.muted)),
                      const SizedBox(height: 8),
                      TextButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              : _buildBody(context, _result!),
    );
  }

  Widget _buildBody(BuildContext context, ExamCandidateResult result) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        _ScoreHero(examName: widget.examName, result: result),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AttemptRecordingsScreen(
                sessionId: widget.sessionId,
                examName: widget.examName,
              ),
            ),
          ),
          icon: const Icon(Icons.mic, size: 18),
          label: const Text('View recordings'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.indigo,
            side: const BorderSide(color: Color(0xFFE2E8F0)),
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(99),
            ),
            textStyle:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        if (result.sections.isNotEmpty) ...[
          const SizedBox(height: 24),
          const SectionLabel('Section Breakdown'),
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
                for (int i = 0; i < result.sections.length; i++) ...[
                  _SectionRow(result.sections[i]),
                  if (i != result.sections.length - 1)
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                ],
              ],
            ),
          ),
        ],
        if (result.status == ExamResultStatus.released) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => NewAppealScreen(
                  candidateResultId: result.id,
                  examName: widget.examName,
                  parts: [
                    for (final item in result.items)
                      AppealablePart(
                        paperItemId: item.paperItemId,
                        label: result.sections
                            .firstWhere(
                              (s) => s.sectionId == item.sectionId,
                              orElse: () => const ExamCandidateResultSection(
                                sectionId: '',
                                title: null,
                                score: 0,
                              ),
                            )
                            .title ??
                            'Part',
                        score: item.itemScore,
                      ),
                  ],
                ),
              ),
            ),
            icon: const Icon(Icons.flag_outlined, size: 18),
            label: const Text('Appeal this result'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: const BorderSide(color: Color(0xFFE2E8F0)),
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(99),
              ),
              textStyle:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
        const SizedBox(height: 28),
        FilledButton(
          onPressed: () => Navigator.of(context).maybePop(),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.indigo,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(99),
            ),
            textStyle:
                const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          child: const Text('Done'),
        ),
      ],
    );
  }
}

class ExamResultScreen extends StatelessWidget {
  const ExamResultScreen({super.key, required this.sessionId, required this.examName});
  final String sessionId;
  final String examName;

  @override
  Widget build(BuildContext context) => ResultsScreen(
        sessionId: sessionId,
        examName: examName,
        pageTitle: 'Kết quả bài kiểm tra',
      );
}

class ClassTestResultScreen extends StatelessWidget {
  const ClassTestResultScreen({super.key, required this.sessionId, required this.examName});
  final String sessionId;
  final String examName;

  @override
  Widget build(BuildContext context) => ResultsScreen(
        sessionId: sessionId,
        examName: examName,
        pageTitle: 'Kết quả bài tập',
      );
}

class _ScoreHero extends StatelessWidget {
  const _ScoreHero({required this.examName, required this.result});

  final String examName;
  final ExamCandidateResult result;

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
            examName.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 18),
          if (result.scoreVisible && result.totalScore != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  result.totalScore!.toStringAsFixed(1),
                  style: const TextStyle(
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
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            )
          else
            const Text(
              'Score not released yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              result.status.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: result.status.fg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionRow extends StatelessWidget {
  const _SectionRow(this.section);
  final ExamCandidateResultSection section;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              section.title ?? 'Section',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.dark,
              ),
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
                  widthFactor: (section.score / 10).clamp(0.0, 1.0),
                  child: Container(color: AppColors.indigo),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 42,
            child: Text(
              section.score.toStringAsFixed(1),
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
