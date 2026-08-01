import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../core/storage/preference_storage.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/onboarding_question.dart';
import '../../data/personalize_repository.dart';
import '../personalize_widgets.dart';
import 'flas_quiz_step.dart';
import 'interest_quiz_step.dart';

/// Design `1a` — the questionnaire that builds the learner profile.
///
/// Two steps: the FLAS / learning-style quiz (still local-only, not yet wired
/// to `submitFlsaSelfReport`), then the REAL forced-choice interest quiz
/// (`interestQuizItems`/`submitInterestQuiz` -- NOT `PersonalizeDemoData`,
/// this is what actually seeds `dimension_interest_score`). The old fake
/// topic-chip/goal-tile step and the fabricated CEFR/roadmap profile summary
/// screen (`LearnerProfileStep`) had no real backend behind them and were
/// dropped rather than wired to fake data.
///
/// Pops `true` once the quiz has been submitted (or skipped because there was
/// nothing to answer).
class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final _repository = PersonalizeRepository();
  final _preferences = PreferenceStorage();

  bool _loading = true;
  String? _error;

  List<OnboardingQuestion> _questions = const [];
  List<InterestQuizItem> _quizItems = const [];

  /// Question id → chosen option index (FLSA step, local only for now).
  final Map<String, int> _answers = {};

  /// Quiz item id → chosen statement index.
  final Map<String, int> _mostByItem = {};
  final Map<String, int> _leastByItem = {};

  /// 0..questions.length-1 → FLSA quiz; questions.length..+quizItems.length-1
  /// → interest quiz, one triplet per step.
  int _step = 0;
  bool _submitting = false;

  int get _quizStartStep => _questions.length;
  int get _totalSteps => _questions.length + _quizItems.length;
  bool get _onQuizItem => _step >= _quizStartStep && _quizItems.isNotEmpty;

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
      final questions = await _repository.getOnboardingQuestions();
      final quizItems = await _repository.getInterestQuizItems();
      if (!mounted) return;
      setState(() {
        _questions = questions;
        _quizItems = quizItems;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _back() {
    if (_step == 0) {
      Navigator.of(context).pop(false);
      return;
    }
    setState(() => _step--);
  }

  Future<void> _next() async {
    final leavingFlsa = _questions.isNotEmpty && _step == _questions.length - 1;
    if (leavingFlsa && !await _submitFlsa()) {
      return;
    }
    if (_step < _totalSteps - 1) {
      setState(() => _step++);
      return;
    }
    if (_quizItems.isEmpty) {
      await _finish();
      return;
    }
    await _submitQuiz();
  }

  /// Maps to `submitFlsaSelfReport` -- option index (0..4) shown by
  /// `FlasQuizStep` becomes a 1..5 Likert value. Returns `false` (and shows
  /// the error state) if the real submission failed, so `_next()` doesn't
  /// advance past unsent answers.
  Future<bool> _submitFlsa() async {
    setState(() => _submitting = true);
    try {
      final answers = [
        for (final question in _questions) (_answers[question.id] ?? 0) + 1,
      ];
      await _repository.submitFlsaSelfReport(answers);
      return true;
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
      return false;
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _submitQuiz() async {
    setState(() => _submitting = true);
    try {
      final answers = [
        for (final item in _quizItems)
          InterestQuizAnswer(
            itemId: item.id,
            mostStatementIndex: _mostByItem[item.id]!,
            leastStatementIndex: _leastByItem[item.id]!,
          ),
      ];
      await _repository.submitInterestQuiz(answers);
      await _finish();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _finish() async {
    await _preferences.savePracticeOnboardingDone(true);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_loading || _submitting) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(),
        body: PersonalizeErrorView(detail: _error, onRetry: _load),
      );
    }
    if (_totalSteps == 0) {
      // Nothing to answer at all (no FLSA questions, no quiz items) -- don't
      // show an empty questionnaire, just finish immediately.
      _finish();
      return const Scaffold(body: SizedBox.shrink());
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _OnboardingHeader(
              title: _onQuizItem
                  ? l10n.pzInterestQuizTitle
                  : l10n.pzOnboardingQuizTitle,
              counter: l10n.pzOnboardingProgress(_step + 1, _totalSteps),
              progress: (_step + 1) / _totalSteps,
              onBack: _back,
            ),
            Expanded(
              child: _onQuizItem
                  ? Builder(builder: (context) {
                      final item = _quizItems[_step - _quizStartStep];
                      return InterestQuizStep(
                        item: item,
                        mostIndex: _mostByItem[item.id],
                        leastIndex: _leastByItem[item.id],
                        canGoBack: _step > 0,
                        onPickMost: (index) => setState(() {
                          _mostByItem[item.id] = index;
                          if (_leastByItem[item.id] == index) {
                            _leastByItem.remove(item.id);
                          }
                        }),
                        onPickLeast: (index) => setState(() {
                          _leastByItem[item.id] = index;
                          if (_mostByItem[item.id] == index) {
                            _mostByItem.remove(item.id);
                          }
                        }),
                        onBack: _back,
                        onContinue: _next,
                      );
                    })
                  : FlasQuizStep(
                      question: _questions[_step],
                      selectedIndex: _answers[_questions[_step].id],
                      canGoBack: _step > 0,
                      onSelect: (index) => setState(
                        () => _answers[_questions[_step].id] = index,
                      ),
                      onBack: _back,
                      onContinue: _next,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shared header: back button, title, counter and the gradient progress bar.
class _OnboardingHeader extends StatelessWidget {
  const _OnboardingHeader({
    required this.title,
    required this.counter,
    required this.progress,
    required this.onBack,
  });

  final String title;
  final String? counter;
  final double progress;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              InkWell(
                onTap: onBack,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFE0E0E0),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(Icons.arrow_back,
                      size: 20, color: Color(0xFF444444)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ),
              if (counter != null)
                Text(
                  counter!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: Container(
              height: 5,
              color: AppColors.borderSoft,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress.clamp(0.0, 1.0),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.indigo, AppColors.secondary],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
