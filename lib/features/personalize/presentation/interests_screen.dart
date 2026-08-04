import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../app/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../data/models/interest.dart';
import '../data/personalize_repository.dart';
import 'personalize_widgets.dart';

/// Design `1f`, screen 3 — the self-updating interest profile.
///
/// Real `myInterestProfile` (`topics` → active/cooling, PENDING
/// `suggestions` → discovered cards with real `respondToTopicSuggestion`).
class InterestsScreen extends StatefulWidget {
  const InterestsScreen({super.key});

  @override
  State<InterestsScreen> createState() => _InterestsScreenState();
}

class _InterestsScreenState extends State<InterestsScreen> {
  final _repository = PersonalizeRepository();

  bool _loading = true;
  String? _error;
  List<Interest> _interests = const [];

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
      final interests = await _repository.getInterests();
      if (!mounted) return;
      setState(() {
        _interests = interests;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _acceptDiscovery(Interest interest) async {
    setState(
      () => _interests = _interests.where((i) => i.id != interest.id).toList(),
    );
    try {
      await _repository.respondToTopicSuggestion(interest.id, true);
    } catch (_) {
      if (mounted) _load();
    }
  }

  Future<void> _dismissDiscovery(Interest interest) async {
    setState(
      () => _interests = _interests.where((i) => i.id != interest.id).toList(),
    );
    try {
      await _repository.respondToTopicSuggestion(interest.id, false);
    } catch (_) {
      if (mounted) _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.pzInterestsTitle)),
      body: switch ((_loading, _error)) {
        (true, _) => const Center(child: CircularProgressIndicator()),
        (_, final String error) => PersonalizeErrorView(
          detail: error,
          onRetry: _load,
        ),
        _ => _buildBody(l10n),
      },
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    final discovered = _interests
        .where((i) => i.status == InterestStatus.discovered)
        .toList();
    final active = _interests
        .where((i) => i.status == InterestStatus.active)
        .toList();
    final cooling = _interests
        .where((i) => i.status == InterestStatus.cooling)
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        for (final interest in discovered) ...[
          _DiscoveryCard(
            interest: interest,
            onAdd: () => _acceptDiscovery(interest),
            onDismiss: () => _dismissDiscovery(interest),
          ),
          const SizedBox(height: 16),
        ],
        if (active.isNotEmpty) ...[
          SectionLabel(l10n.pzInterestsActive),
          const SizedBox(height: 12),
          for (final interest in active) ...[
            _ActiveRow(interest: interest),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 8),
        ],
        if (cooling.isNotEmpty) ...[
          SectionLabel(l10n.pzInterestsCooling),
          const SizedBox(height: 10),
          for (final interest in cooling) ...[
            _CoolingRow(interest: interest),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 20),
        Text(
          l10n.pzInterestsFooter,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11.5,
            height: 1.5,
            color: AppColors.textGhost,
          ),
        ),
      ],
    );
  }
}

/// The "MÌNH PHÁT HIỆN THÊM" suggestion card.
class _DiscoveryCard extends StatelessWidget {
  const _DiscoveryCard({
    required this.interest,
    required this.onAdd,
    required this.onDismiss,
  });

  final Interest interest;
  final VoidCallback onAdd;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.chipBlueBg, Color(0xFFF5F3FF)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.indigo, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, size: 18, color: AppColors.indigo),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.pzInterestsDiscovered,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: AppColors.indigo,
                  ),
                ),
              ),
              if (interest.confidence != null)
                Text(
                  l10n.pzInterestsConfidence(interest.confidence!),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6366F1),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            interest.label,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          if (interest.evidence != null) ...[
            const SizedBox(height: 6),
            Text(
              interest.evidence!,
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.5,
                color: Color(0xFF4C4A75),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: FilledButton(
                    onPressed: onAdd,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.indigo,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(99),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: Text(l10n.pzInterestsAdd),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 44,
                child: OutlinedButton(
                  onPressed: onDismiss,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF555555),
                    side: const BorderSide(color: Color(0xFFE2E2E2)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(99),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: Text(l10n.pzInterestsDismiss),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActiveRow extends StatelessWidget {
  const _ActiveRow({required this.interest});
  final Interest interest;

  @override
  Widget build(BuildContext context) {
    final faded = interest.ratio < 0.4;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                interest.label,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              interest.detail,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: faded ? AppColors.textFaint : AppColors.chipGreenFg,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        MeterBar(
          ratio: interest.ratio,
          color: faded ? const Color(0xFFA5B4FC) : AppColors.indigo,
          height: 6,
          track: AppColors.borderSoft,
        ),
      ],
    );
  }
}

class _CoolingRow extends StatelessWidget {
  const _CoolingRow({required this.interest});

  final Interest interest;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE2E2E2),
          width: 1.5,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            interest.label,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            interest.detail,
            style: const TextStyle(fontSize: 11.5, color: AppColors.textGhost),
          ),
        ],
      ),
    );
  }
}
