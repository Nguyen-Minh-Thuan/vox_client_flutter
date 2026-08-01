import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../app/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../data/models/practice_topic.dart';
import '../data/personalize_repository.dart';
import 'personalize_styles.dart';
import 'personalize_widgets.dart';

/// Design `1b`, screen 2 — the browsable topic list.
///
/// Pops the [PracticeTopic] the learner picked so the caller decides how to
/// open the session.
class PracticeTopicsScreen extends StatefulWidget {
  const PracticeTopicsScreen({super.key, this.initialFilter = TopicFilter.forYou});

  final TopicFilter initialFilter;

  @override
  State<PracticeTopicsScreen> createState() => _PracticeTopicsScreenState();
}

class _PracticeTopicsScreenState extends State<PracticeTopicsScreen> {
  final _repository = PersonalizeRepository();
  final _searchController = TextEditingController();

  late TopicFilter _filter = widget.initialFilter;
  bool _loading = true;
  bool _pickingRandom = false;
  String? _error;
  List<PracticeTopic> _topics = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final query = _searchController.text;
      final topics = query.trim().isEmpty
          ? await _repository.getTopics(_filter)
          : (await _repository.searchTopics(query)).topics;
      if (!mounted) return;
      setState(() => _topics = topics);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _selectFilter(TopicFilter filter) {
    if (_filter == filter) return;
    setState(() => _filter = filter);
    _load();
  }

  void _pick(PracticeTopic topic) => Navigator.of(context).pop(topic);

  Future<void> _toggleSaved(PracticeTopic topic) async {
    final isSaved = topic.buckets.contains(TopicFilter.saved);
    // Optimistic: flip locally first, revert on failure.
    setState(() {
      _topics = [
        for (final t in _topics)
          if (t.id == topic.id)
            PracticeTopic(
              id: t.id,
              title: t.title,
              rationale: t.rationale,
              minutes: t.minutes,
              level: t.level,
              matchPercent: t.matchPercent,
              reasons: t.reasons,
              focusTags: t.focusTags,
              icon: t.icon,
              buckets: {
                ...t.buckets,
                if (!isSaved) TopicFilter.saved,
              }..removeWhere((b) => isSaved && b == TopicFilter.saved),
            )
          else
            t,
      ];
    });
    try {
      if (isSaved) {
        await _repository.unsaveTopic(topic.id);
      } else {
        await _repository.saveTopic(topic.id);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _topics = [
          for (final t in _topics)
            if (t.id == topic.id) topic else t,
        ];
      });
    }
  }

  Future<void> _pickRandom() async {
    if (_pickingRandom) return;
    setState(() => _pickingRandom = true);
    try {
      final topic = await _repository.pickRandomTopic();
      if (!mounted) return;
      _pick(topic);
    } catch (_) {
      if (mounted) setState(() => _pickingRandom = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.pzTopicsTitle),
        actions: [
          IconButton(
            onPressed: _pickingRandom ? null : _pickRandom,
            icon: _pickingRandom
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.shuffle),
            tooltip: l10n.pzTopicsRandom,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Column(
              children: [
                _SearchField(
                  controller: _searchController,
                  onSubmitted: (_) => _load(),
                  onClear: () {
                    _searchController.clear();
                    _load();
                  },
                ),
                const SizedBox(height: 12),
                _FilterPills(selected: _filter, onSelect: _selectFilter),
              ],
            ),
          ),
          Expanded(child: _buildBody(l10n)),
        ],
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return PersonalizeErrorView(detail: _error, onRetry: _load);
    }

    if (_topics.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l10n.pzTopicsEmpty,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.textFaint),
          ),
        ),
      );
    }

    // The best match is promoted into the highlighted "ƯU TIÊN #1" card.
    final priority = _topics.first;
    final rest = _topics.skip(1).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 24),
      children: [
        _PriorityCard(
          topic: priority,
          onSpeak: () => _pick(priority),
          onToggleSaved: () => _toggleSaved(priority),
        ),
        if (rest.isNotEmpty) ...[
          const SizedBox(height: 16),
          SectionLabel(l10n.pzTopicsOtherSuggestions),
          const SizedBox(height: 10),
          for (final topic in rest) ...[
            _TopicRow(
              topic: topic,
              onTap: () => _pick(topic),
              onToggleSaved: () => _toggleSaved(topic),
            ),
            const SizedBox(height: 8),
          ],
        ],
        const SizedBox(height: 12),
        const _FooterTip(),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onSubmitted,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.fieldBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 18, color: Color(0xFF999999)),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onSubmitted: onSubmitted,
              textInputAction: TextInputAction.search,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.ink,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: l10n.pzTopicsSearchHint,
                hintStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textGhost,
                ),
              ),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, value, _) => value.text.isEmpty
                ? const SizedBox.shrink()
                : InkWell(
                    onTap: onClear,
                    child: const Icon(Icons.close,
                        size: 18, color: Color(0xFF999999)),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterPills extends StatelessWidget {
  const _FilterPills({required this.selected, required this.onSelect});

  final TopicFilter selected;
  final ValueChanged<TopicFilter> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final labels = <TopicFilter, String>{
      TopicFilter.forYou: l10n.pzTopicsFilterForYou,
      TopicFilter.byGoal: l10n.pzTopicsFilterByGoal,
      TopicFilter.byWeakness: l10n.pzTopicsFilterByWeakness,
      TopicFilter.saved: l10n.pzTopicsFilterSaved,
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final entry in labels.entries) ...[
            SelectablePill(
              label: entry.value,
              active: entry.key == selected,
              onTap: () => onSelect(entry.key),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

/// The highlighted top match.
class _PriorityCard extends StatelessWidget {
  const _PriorityCard({
    required this.topic,
    required this.onSpeak,
    required this.onToggleSaved,
  });

  final PracticeTopic topic;
  final VoidCallback onSpeak;
  final VoidCallback onToggleSaved;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(14),
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
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.indigo,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  l10n.pzTopicsPriority,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    color: Colors.white,
                  ),
                ),
              ),
              if (topic.matchPercent != null) ...[
                const SizedBox(width: 8),
                Text(
                  l10n.pzTopicsMatch(topic.matchPercent!),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6366F1),
                  ),
                ),
              ],
              const Spacer(),
              _SaveButton(
                saved: topic.buckets.contains(TopicFilter.saved),
                onTap: onToggleSaved,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            topic.title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
              height: 1.32,
            ),
          ),
          if (topic.rationale != null) ...[
            const SizedBox(height: 6),
            Text(
              topic.rationale!,
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.5,
                color: Color(0xFF4C4A75),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _WhiteChip(l10n.pzMinutes(topic.minutes)),
              _WhiteChip(levelLabel(l10n, topic.level)),
              for (final tag in topic.focusTags)
                _WhiteChip(tag, color: AppColors.chipOrangeFg),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onSpeak,
              icon: const Icon(Icons.mic, size: 18),
              label: Text(l10n.pzTopicsSpeakThis),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.indigo,
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(99),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bookmark toggle shared by `_PriorityCard` and `_TopicRow`.
class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.saved, required this.onTap});

  final bool saved;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          saved ? Icons.bookmark : Icons.bookmark_border,
          size: 20,
          color: saved ? AppColors.indigo : const Color(0xFF999999),
          semanticLabel: saved ? l10n.pzTopicsUnsave : l10n.pzTopicsSave,
        ),
      ),
    );
  }
}

class _WhiteChip extends StatelessWidget {
  const _WhiteChip(this.label, {this.color = AppColors.indigo});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _TopicRow extends StatelessWidget {
  const _TopicRow({
    required this.topic,
    required this.onTap,
    required this.onToggleSaved,
  });

  final PracticeTopic topic;
  final VoidCallback onTap;
  final VoidCallback onToggleSaved;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: rowDecoration,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.fieldBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(iconForName(topic.icon),
                  size: 22, color: const Color(0xFF555555)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          topic.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      _SaveButton(
                        saved: topic.buckets.contains(TopicFilter.saved),
                        onTap: onToggleSaved,
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${l10n.pzMinutes(topic.minutes)} · '
                    '${levelLabel(l10n, topic.level)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textFaint,
                    ),
                  ),
                  if (topic.reasons.isNotEmpty ||
                      topic.focusTags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final reason in topic.reasons)
                          TagChip.blue(reason),
                        for (final tag in topic.focusTags) TagChip(tag),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FooterTip extends StatelessWidget {
  const _FooterTip();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.headerBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.tips_and_updates_outlined,
              size: 18, color: AppColors.indigo),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: '${l10n.pzTopicsFooterTip} ',
                children: [
                  TextSpan(
                    text: l10n.pzTopicsWhy,
                    style: const TextStyle(
                      color: AppColors.indigo,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              style: const TextStyle(
                fontSize: 12,
                height: 1.5,
                color: Color(0xFF666666),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
