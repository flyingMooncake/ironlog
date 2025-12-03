import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class WorkoutPersistenceService {
  static const String _workoutKey = 'active_workout_draft';
  static const String _timerKey = 'rest_timer_state';

  static Future<void> saveWorkoutDraft(Map<String, dynamic> workoutData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_workoutKey, jsonEncode(workoutData));
  }

  static Future<Map<String, dynamic>?> loadWorkoutDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_workoutKey);
    if (data == null) return null;
    return jsonDecode(data) as Map<String, dynamic>;
  }

  static Future<void> clearWorkoutDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_workoutKey);
  }

  static Future<void> saveTimerState({
    required int remainingSeconds,
    required int totalSeconds,
    required bool isRunning,
    required DateTime? startTime,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'remainingSeconds': remainingSeconds,
      'totalSeconds': totalSeconds,
      'isRunning': isRunning,
      'startTime': startTime?.toIso8601String(),
    };
    await prefs.setString(_timerKey, jsonEncode(data));
  }

  static Future<Map<String, dynamic>?> loadTimerState() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_timerKey);
    if (data == null) return null;
    return jsonDecode(data) as Map<String, dynamic>;
  }

  static Future<void> clearTimerState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_timerKey);
  }
}
