import 'practice_topic.dart';
import 'weakness.dart';

/// Everything the "Luyện nói" home tab renders in one shot.
class PracticeDashboard {
  final String learnerName;
  final int streakDays;

  /// The session proposed for today.
  final PracticeTopic todayTopic;
  final int sessionsDone;
  final double averageScore;
  final int weeklyGoalDone;
  final int weeklyGoalTarget;

  /// "TẬP TRUNG TUẦN NÀY" rows.
  final List<Weakness> weeklyFocus;

  /// "GỢI Ý CHO BẠN" cards.
  final List<PracticeTopic> suggestions;

  const PracticeDashboard({
    required this.learnerName,
    required this.streakDays,
    required this.todayTopic,
    required this.sessionsDone,
    required this.averageScore,
    required this.weeklyGoalDone,
    required this.weeklyGoalTarget,
    this.weeklyFocus = const [],
    this.suggestions = const [],
  });

  factory PracticeDashboard.fromJson(Map<String, dynamic> json) {
    return PracticeDashboard(
      learnerName: json['learnerName'] as String? ?? '',
      streakDays: (json['streakDays'] as num?)?.toInt() ?? 0,
      todayTopic: PracticeTopic.fromJson(
        json['todayTopic'] as Map<String, dynamic>,
      ),
      sessionsDone: (json['sessionsDone'] as num?)?.toInt() ?? 0,
      averageScore: (json['averageScore'] as num?)?.toDouble() ?? 0,
      weeklyGoalDone: (json['weeklyGoalDone'] as num?)?.toInt() ?? 0,
      weeklyGoalTarget: (json['weeklyGoalTarget'] as num?)?.toInt() ?? 0,
      weeklyFocus: (json['weeklyFocus'] as List<dynamic>? ?? const [])
          .map((e) => Weakness.fromJson(e as Map<String, dynamic>))
          .toList(),
      suggestions: (json['suggestions'] as List<dynamic>? ?? const [])
          .map((e) => PracticeTopic.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
