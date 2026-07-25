import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../../app/theme.dart';
import '../../../core/network/graphql_client.dart';
import '../../recordings/data/models/exam_item_response.dart';
import '../../recordings/data/models/exam_response_item.dart';
import '../../recordings/data/recordings_api.dart';
import '../../recordings/data/recordings_repository.dart';

/// Item responses within one exam attempt, with lazy-loaded playback.
/// Each item may itself be multiple turns (AI follow-up ↔ student reply).
class AttemptRecordingsScreen extends StatefulWidget {
  const AttemptRecordingsScreen({
    super.key,
    required this.sessionId,
    required this.examName,
  });

  final String sessionId;
  final String examName;

  @override
  State<AttemptRecordingsScreen> createState() =>
      _AttemptRecordingsScreenState();
}

class _AttemptRecordingsScreenState extends State<AttemptRecordingsScreen> {
  final _repository = RecordingsRepository(RecordingsApi(GraphQLClient()));
  final _player = AudioPlayer();

  bool _loading = true;
  String? _error;
  List<ExamResponseItem> _items = const [];

  String? _expandedId;
  final Map<String, ExamItemResponse> _details = {};

  String? _playingKey;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _repository.getSessionItems(widget.sessionId);
      if (!mounted) return;
      setState(() => _items = items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Could not load this attempt.\n$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleExpand(ExamResponseItem item) async {
    if (_expandedId == item.responseId) {
      setState(() => _expandedId = null);
      return;
    }
    setState(() => _expandedId = item.responseId);
    if (_details.containsKey(item.responseId)) return;
    try {
      final detail = await _repository.getItemResponse(item.responseId);
      if (!mounted) return;
      setState(() => _details[item.responseId] = detail);
    } catch (_) {
      if (!mounted) return;
      setState(() => _expandedId = null);
    }
  }

  Future<void> _togglePlay(String key, String? audioUrl) async {
    if (_playingKey == key) {
      await _player.pause();
      setState(() => _playingKey = null);
      return;
    }
    if (audioUrl == null) return;
    setState(() => _playingKey = key);
    try {
      await _player.setUrl(audioUrl);
      await _player.play();
      if (mounted) setState(() {});
    } catch (_) {
      if (!mounted) return;
      setState(() => _playingKey = null);
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
          widget.examName,
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
              : _items.isEmpty
                  ? const Center(
                      child: Text(
                        'No recorded items in this attempt.',
                        style: TextStyle(color: AppColors.muted),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                      itemCount: _items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final item = _items[i];
                        return _ItemCard(
                          index: i + 1,
                          item: item,
                          detail: _details[item.responseId],
                          expanded: _expandedId == item.responseId,
                          playingKey: _playingKey,
                          player: _player,
                          onExpand: () => _toggleExpand(item),
                          onPlay: _togglePlay,
                        );
                      },
                    ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.index,
    required this.item,
    required this.detail,
    required this.expanded,
    required this.playingKey,
    required this.player,
    required this.onExpand,
    required this.onPlay,
  });

  final int index;
  final ExamResponseItem item;
  final ExamItemResponse? detail;
  final bool expanded;
  final String? playingKey;
  final AudioPlayer player;
  final VoidCallback onExpand;
  final void Function(String key, String? audioUrl) onPlay;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onExpand,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.chipBlueBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.mic,
                        color: AppColors.indigo, size: 22),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Text(
                      'Item $index',
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.dark,
                      ),
                    ),
                  ),
                  if (item.itemScore != null)
                    Text(
                      item.itemScore!.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.dark,
                      ),
                    ),
                  const SizedBox(width: 4),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textGhost,
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            if (detail == null)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else if (detail!.turns.isNotEmpty)
              for (final turn in detail!.turns)
                _TurnRow(
                  turn: turn,
                  playing: playingKey == turn.id,
                  player: player,
                  onPlay: () => onPlay(turn.id, turn.audioUrl),
                )
            else
              _TurnRow(
                turn: ExamItemResponseTurn(
                  id: detail!.id,
                  turnOrder: 1,
                  audioUrl: detail!.audioUrl,
                  transcript: detail!.transcript,
                  durationSeconds: detail!.durationSeconds,
                ),
                playing: playingKey == detail!.id,
                player: player,
                onPlay: () => onPlay(detail!.id, detail!.audioUrl),
              ),
          ],
        ],
      ),
    );
  }
}

class _TurnRow extends StatelessWidget {
  const _TurnRow({
    required this.turn,
    required this.playing,
    required this.player,
    required this.onPlay,
  });

  final ExamItemResponseTurn turn;
  final bool playing;
  final AudioPlayer player;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: turn.audioUrl == null ? null : onPlay,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: playing ? AppColors.indigo : AppColors.chipBlueBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    playing ? Icons.pause : Icons.play_arrow,
                    color: playing ? Colors.white : AppColors.indigo,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (turn.promptText != null &&
                        turn.promptText!.isNotEmpty) ...[
                      Text(
                        turn.promptText!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    if (turn.durationSeconds != null)
                      Text(
                        _formatDuration(turn.durationSeconds),
                        style: const TextStyle(
                            fontSize: 11.5, color: AppColors.textGhost),
                      ),
                    if (playing) ...[
                      const SizedBox(height: 8),
                      StreamBuilder<Duration>(
                        stream: player.positionStream,
                        builder: (context, snapshot) {
                          final position = snapshot.data ?? Duration.zero;
                          final total = player.duration ??
                              Duration(seconds: turn.durationSeconds ?? 0);
                          final progress = total.inMilliseconds == 0
                              ? 0.0
                              : (position.inMilliseconds /
                                      total.inMilliseconds)
                                  .clamp(0.0, 1.0);
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: Container(
                              height: 4,
                              color: const Color(0xFFE2E8F0),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: progress,
                                child: Container(color: AppColors.indigo),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                    if (turn.transcript != null &&
                        turn.transcript!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        turn.transcript!,
                        style: const TextStyle(
                            fontSize: 12.5, color: AppColors.muted),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFF1F5F9)),
      ],
    );
  }

  String _formatDuration(int? seconds) {
    if (seconds == null) return '';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
