import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../../app/theme.dart';
import '../../../core/network/graphql_client.dart';
import '../../recordings/data/models/exam_recording.dart';
import '../../recordings/data/recordings_api.dart';
import '../../recordings/data/recordings_repository.dart';

/// My Recordings — archive of past speaking attempts with playback.
class RecordingsScreen extends StatefulWidget {
  const RecordingsScreen({super.key});

  @override
  State<RecordingsScreen> createState() => _RecordingsScreenState();
}

class _RecordingsScreenState extends State<RecordingsScreen> {
  final _repository = RecordingsRepository(RecordingsApi(GraphQLClient()));
  final _player = AudioPlayer();

  bool _loading = true;
  String? _error;
  List<ExamRecording> _recordings = const [];
  String? _playingId;

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
      final recordings = await _repository.getMyRecordings();
      if (!mounted) return;
      setState(() => _recordings = recordings);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not load recordings.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _togglePlay(ExamRecording rec) async {
    if (_playingId == rec.id) {
      await _player.pause();
      setState(() => _playingId = null);
      return;
    }
    setState(() => _playingId = rec.id);
    try {
      await _player.setUrl(rec.audioUrl);
      await _player.play();
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
        title: const Text(
          'My Recordings',
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
                      Text(_error!,
                          style: const TextStyle(color: AppColors.muted)),
                      const SizedBox(height: 8),
                      TextButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              : _recordings.isEmpty
                  ? const Center(
                      child: Text(
                        'No recordings yet.',
                        style: TextStyle(color: AppColors.muted),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                      itemCount: _recordings.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final rec = _recordings[i];
                        return _RecCard(
                          rec: rec,
                          playing: _playingId == rec.id,
                          player: _player,
                          onPlay: () => _togglePlay(rec),
                        );
                      },
                    ),
    );
  }
}

class _RecCard extends StatelessWidget {
  const _RecCard({
    required this.rec,
    required this.playing,
    required this.player,
    required this.onPlay,
  });

  final ExamRecording rec;
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
                        rec.examName ?? 'Speaking Item',
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.dark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDate(rec.submittedAt),
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  _formatDuration(rec.durationSeconds),
                  style: const TextStyle(
                      fontSize: 11.5, color: AppColors.textGhost),
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
                      Duration(seconds: rec.durationSeconds ?? 0);
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
          if (rec.transcript != null && rec.transcript!.isNotEmpty) ...[
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Text(
                rec.transcript!,
                style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  String _formatDuration(int? totalSeconds) {
    final seconds = totalSeconds ?? 0;
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
