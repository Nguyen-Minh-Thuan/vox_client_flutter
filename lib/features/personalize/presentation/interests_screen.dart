import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../app/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../data/models/interest.dart';
import '../data/personalize_repository.dart';
import 'personalize_widgets.dart';

/// Design `1f`, screen 3 — the self-updating interest profile.
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
  bool _autoUpdate = true;

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
      setState(() => _interests = interests);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Accepts a discovered interest — it moves into the active list.
  void _acceptDiscovery(Interest interest) {
    setState(() {
      _interests = [
        for (final i in _interests)
          if (i.id == interest.id)
            i.copyWith(status: InterestStatus.active)
          else
            i,
      ];
    });
  }

  /// Rejects a discovered interest — it disappears from the list entirely.
  void _dismissDiscovery(Interest interest) {
    setState(() {
      _interests = _interests.where((i) => i.id != interest.id).toList();
    });
  }

  /// Keeps a cooling interest alive by promoting it back to active.
  void _keepCooling(Interest interest) {
    setState(() {
      _interests = [
        for (final i in _interests)
          if (i.id == interest.id)
            i.copyWith(status: InterestStatus.active)
          else
            i,
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.pzInterestsTitle)),
      body: switch ((_loading, _error)) {
        (true, _) => const Center(child: CircularProgressIndicator()),
        (_, final String error) =>
          PersonalizeErrorView(detail: error, onRetry: _load),
        _ => _buildBody(l10n),
      },
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    final discovered = _interests
        .where((i) => i.status == InterestStatus.discovered)
        .toList();
    final active =
        _interests.where((i) => i.status == InterestStatus.active).toList();
    final cooling =
        _interests.where((i) => i.status == InterestStatus.cooling).toList();

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(child: SectionLabel(l10n.pzInterestsActive)),
              Text(
                l10n.pzInterestsEdit,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.indigo,
                ),
              ),
            ],
          ),
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
            _CoolingRow(
              interest: interest,
              onKeep: () => _keepCooling(interest),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 8),
        ],
        _AutoUpdateTile(
          value: _autoUpdate,
          onChanged: (v) => setState(() => _autoUpdate = v),
        ),
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
            '${interest.emoji} ${interest.label}',
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
    // Below this the topic is barely mentioned — render it in a muted indigo.
    final faded = interest.ratio < 0.4;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${interest.emoji} ${interest.label}',
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
  const _CoolingRow({required this.interest, required this.onKeep});

  final Interest interest;
  final VoidCallback onKeep;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${interest.emoji} ${interest.label}',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF666666),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  interest.detail,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textGhost,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Material(
            color: AppColors.fieldBg,
            borderRadius: BorderRadius.circular(99),
            child: InkWell(
              onTap: onKeep,
              borderRadius: BorderRadius.circular(99),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                child: Text(
                  l10n.pzInterestsKeep,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.chipNeutralFg,
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

class _AutoUpdateTile extends StatelessWidget {
  const _AutoUpdateTile({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: AppColors.headerBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.pzInterestsAutoUpdate,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  l10n.pzInterestsAutoUpdateBody,
                  style: const TextStyle(
                    fontSize: 11.5,
                    height: 1.45,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
