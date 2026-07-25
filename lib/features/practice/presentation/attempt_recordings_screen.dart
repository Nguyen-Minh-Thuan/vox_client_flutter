import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../../app/theme.dart';
import '../../../core/network/graphql_client.dart';
import '../../recordings/data/models/exam_item_response.dart';
import '../../recordings/data/models/exam_response_item.dart';
import '../../recordings/data/recordings_api.dart';
import '../../recordings/data/recordings_repository.dart';

/// Item responses within one exam attempt, with lazy-loaded playback.
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

  String? _playingId;
  final Map<String, ExamItemResponse> _details = {};

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
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not load this attempt.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _togglePlay(ExamResponseItem item) async {
    if (_playingId == item.responseId) {
      await _player.pause();
      setState(() => _playingId = null);
      return;
    }
    setState(() => _playingId = item.responseId);
    try {
      var detail = _details[item.responseId];
      if (detail == null) {
        detail = await _repository.getItemResponse(item.responseId);
        if (!mounted) return;
        _details[item.responseId] = detail;
      }
      if (detail.audioUrl == null) {
        setState(() => _playingId = null);
        return;
      }
      await _player.setUrl(detail.audioUrl!);
      await _player.play();
      if (mounted) setState(() {});
    } catch (_) {
      if (!mounted) return;
      setState(() => _playingId = null);
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
                          playing: _playingId == item.responseId,
                          player: _player,
                          onPlay: () => _togglePlay(item),
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
    required this.playing,
    required this.player,
    required this.onPlay,
  });

  final int index;
  final ExamResponseItem item;
  final ExamItemResponse? detail;
  final bool playing;
  final AudioPlayer player;
  final VoidCallback onPlay;

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
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                GestureDetector(
                  onTap: onPlay,
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: playing ? AppColors.indigo : AppColors.chipBlueBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      playing ? Icons.pause : Icons.play_arrow,
                      color: playing ? Colors.white : AppColors.indigo,
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Item $index',
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.dark,
                        ),
                      ),
                      if (detail?.durationSeconds != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          _formatDuration(detail!.durationSeconds),
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.muted),
                        ),
                      ],
                    ],
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
              ],
            ),
          ),
          if (playing) ...[
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: StreamBuilder<Duration>(
                stream: player.positionStream,
                builder: (context, snapshot) {
                  final position = snapshot.data ?? Duration.zero;
                  final total = player.duration ??
                      Duration(seconds: detail?.durationSeconds ?? 0);
                  final progress = total.inMilliseconds == 0
                      ? 0.0
                      : (position.inMilliseconds / total.inMilliseconds)
                          .clamp(0.0, 1.0);
                  return Row(
                    children: [
                      Text(_formatDuration(position.inSeconds),
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.muted)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
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
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(_formatDuration(total.inSeconds),
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.muted)),
                    ],
                  );
                },
              ),
            ),
          ],
          if (detail?.transcript != null && detail!.transcript!.isNotEmpty) ...[
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Text(
                detail!.transcript!,
                style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDuration(int? seconds) {
    if (seconds == null) return '';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
