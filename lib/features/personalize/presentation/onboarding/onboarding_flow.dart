import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../core/storage/preference_storage.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/learner_profile.dart';
import '../../data/models/onboarding_question.dart';
import '../../data/personalize_repository.dart';
import '../personalize_widgets.dart';
import 'flas_quiz_step.dart';
import 'interests_goals_step.dart';
import 'learner_profile_step.dart';

/// Design `1a` — the questionnaire that builds the learner profile.
///
/// Three steps: the FLAS / learning-style quiz, interests & goals, then the
/// derived profile. The entrance speaking assessment from the design is out of
/// scope for now.
///
/// Pops `true` once the profile has been accepted.
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
  List<InterestChoice> _interestChoices = const [];
  List<LearningGoal> _goals = const [];

  /// Question id → chosen option index.
  final Map<String, int> _answers = {};
  final Set<String> _selectedInterests = {};
  String? _selectedGoalId;

  /// 0..questions.length-1 → quiz; then interests; then profile.
  int _step = 0;
  bool _submitting = false;
  LearnerProfile? _profile;

  int get _interestsStep => _questions.length;
  int get _profileStep => _questions.length + 1;

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
      final interests = await _repository.getInterestChoices();
      final goals = await _repository.getLearningGoals();
      if (!mounted) return;
      setState(() {
        _questions = questions;
        _interestChoices = interests;
        _goals = goals;
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
    if (_step < _interestsStep) {
      setState(() => _step++);
      return;
    }
    if (_step == _interestsStep) {
      await _submit();
      return;
    }
    await _finish();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final profile = await _repository.submitOnboarding(
        answers: _answers,
        interestIds: _selectedInterests,
        goalId: _selectedGoalId,
      );
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _step = _profileStep;
      });
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

  /// Skips straight to the profile with whatever has been answered so far.
  Future<void> _skip() => _submit();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_loading) {
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

    // The profile step owns its whole screen, header included.
    if (_step == _profileStep && _profile != null) {
      return LearnerProfileStep(
        profile: _profile!,
        onStart: _finish,
      );
    }

    final onInterests = _step == _interestsStep;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _OnboardingHeader(
              title: onInterests
                  ? l10n.pzOnboardingInterestsTitle
                  : l10n.pzOnboardingQuizTitle,
              // The interests step replaces the counter with a Skip action.
              counter: onInterests
                  ? null
                  : l10n.pzOnboardingProgress(_step + 1, _questions.length),
              progress: onInterests
                  ? 1
                  : (_step + 1) / (_questions.length + 1),
              onBack: _back,
              onSkip: onInterests ? _skip : null,
            ),
            Expanded(
              child: onInterests
                  ? InterestsGoalsStep(
                      choices: _interestChoices,
                      goals: _goals,
                      selectedInterests: _selectedInterests,
                      selectedGoalId: _selectedGoalId,
                      submitting: _submitting,
                      onToggleInterest: (id) => setState(() {
                        _selectedInterests.contains(id)
                            ? _selectedInterests.remove(id)
                            : _selectedInterests.add(id);
                      }),
                      onSelectGoal: (id) =>
                          setState(() => _selectedGoalId = id),
                      onContinue: _next,
                    )
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
    this.onSkip,
  });

  final String title;
  final String? counter;
  final double progress;
  final VoidCallback onBack;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
              if (onSkip != null)
                TextButton(
                  onPressed: onSkip,
                  child: Text(
                    l10n.pzOnboardingSkip,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.indigo,
                    ),
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
