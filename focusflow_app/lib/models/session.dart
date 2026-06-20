import 'task.dart';

class PomodoroSession {
  final int id;
  final int durationMs;
  final DateTime startTime;
  final DateTime endTime;
  final int? taskId;
  final Task? task;
  final String status;

  PomodoroSession({
    required this.id,
    required this.durationMs,
    required this.startTime,
    required this.endTime,
    this.taskId,
    this.task,
    this.status = 'completed',
  });

  factory PomodoroSession.fromJson(Map<String, dynamic> json) {
    return PomodoroSession(
      id: json['id'],
      durationMs: json['durationMs'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      taskId: json['taskId'],
      task: json['task'] != null ? Task.fromJson(json['task']) : null,
      status: json['status'] ?? 'completed',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'durationMs': durationMs,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'taskId': taskId,
      'status': status,
    };
  }
}
