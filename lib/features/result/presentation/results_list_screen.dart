import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/network/graphql_client.dart';
import '../data/models/exam_result_summary.dart';
import '../data/result_api.dart';
import '../data/result_repository.dart';
import 'results_screen.dart';

/// My Results — list of the student's real exam results.
class ResultsListScreen extends StatefulWidget {
  const ResultsListScreen({super.key});

  @override
  State<ResultsListScreen> createState() => _ResultsListScreenState();
}

class _ResultsListScreenState extends State<ResultsListScreen> {
  final _repository = ResultRepository(ResultApi(GraphQLClient()));

  bool _loading = true;
  String? _error;
  List<ExamResultSummary> _results = const [];

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
      final results = await _repository.getMyExamResults();
      if (!mounted) return;
      setState(() => _results = results);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not load results.');
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
        title: const Text(
          'My Results',
          style: TextStyle(
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
                      Text(_error!, style: const TextStyle(color: AppColors.muted)),
                      const SizedBox(height: 8),
                      TextButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              : _results.isEmpty
                  ? const Center(
                      child: Text(
                        'No exam results yet.',
                        style: TextStyle(color: AppColors.muted),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
                      itemCount: _results.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) => _ResultCard(_results[index]),
                    ),
    );
  }
}

extension ResultStatusMeta on ExamResultStatus {
  String get label => switch (this) {
        ExamResultStatus.pendingReview => 'Pending review',
        ExamResultStatus.released => 'Released',
        ExamResultStatus.appealed => 'Appealed',
        ExamResultStatus.reGrading => 'Re-grading',
        ExamResultStatus.final_ => 'Final',
        ExamResultStatus.invalid => 'Invalid',
        ExamResultStatus.retakeRequired => 'Retake required',
        ExamResultStatus.passed => 'Passed',
        ExamResultStatus.failed => 'Failed',
      };
  Color get fg => switch (this) {
        ExamResultStatus.pendingReview => AppColors.warnFg,
        ExamResultStatus.released => AppColors.success,
        ExamResultStatus.appealed => AppColors.indigo,
        ExamResultStatus.reGrading => AppColors.indigo,
        ExamResultStatus.final_ => AppColors.success,
        ExamResultStatus.invalid => AppColors.muted,
        ExamResultStatus.retakeRequired => AppColors.warnFg,
        ExamResultStatus.passed => AppColors.success,
        ExamResultStatus.failed => AppColors.warnFg,
      };
  Color get bg => switch (this) {
        ExamResultStatus.pendingReview => AppColors.warnBg,
        ExamResultStatus.released => const Color(0xFFECFDF5),
        ExamResultStatus.appealed => AppColors.chipBlueBg,
        ExamResultStatus.reGrading => AppColors.chipBlueBg,
        ExamResultStatus.final_ => const Color(0xFFECFDF5),
        ExamResultStatus.invalid => AppColors.chipNeutralBg,
        ExamResultStatus.retakeRequired => AppColors.warnBg,
        ExamResultStatus.passed => const Color(0xFFECFDF5),
        ExamResultStatus.failed => AppColors.warnBg,
      };
  IconData get icon => switch (this) {
        ExamResultStatus.pendingReview => Icons.hourglass_empty,
        ExamResultStatus.released => Icons.check_circle,
        ExamResultStatus.appealed => Icons.search,
        ExamResultStatus.reGrading => Icons.autorenew,
        ExamResultStatus.final_ => Icons.check_circle,
        ExamResultStatus.invalid => Icons.cancel_outlined,
        ExamResultStatus.retakeRequired => Icons.replay,
        ExamResultStatus.passed => Icons.check_circle,
        ExamResultStatus.failed => Icons.cancel_outlined,
      };
}

class _ResultCard extends StatelessWidget {
  const _ResultCard(this.result);
  final ExamResultSummary result;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ResultsScreen(
            sessionId: result.sessionId,
            examName: result.examName,
          ),
        ),
      ),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.examName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.dark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _StatusPill(result.status),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(result.submittedAt),
                        style: const TextStyle(fontSize: 12, color: AppColors.muted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (result.totalScore != null) ...[
              const SizedBox(width: 12),
              Text(
                result.totalScore!.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.dark,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) => date == null
      ? ''
      : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class _StatusPill extends StatelessWidget {
  const _StatusPill(this.status);
  final ExamResultStatus status;

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
