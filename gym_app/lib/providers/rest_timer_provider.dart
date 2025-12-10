import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/haptic_service.dart';
import '../services/workout_persistence_service.dart';
import '../services/notification_service.dart';

class RestTimerState {
  final int remainingSeconds;
  final int totalSeconds;
  final bool isRunning;
  final DateTime? startTime;

  RestTimerState({
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.isRunning,
    this.startTime,
  });

  RestTimerState copyWith({
    int? remainingSeconds,
    int? totalSeconds,
    bool? isRunning,
    DateTime? startTime,
  }) {
    return RestTimerState(
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      isRunning: isRunning ?? this.isRunning,
      startTime: startTime ?? this.startTime,
    );
  }

  double get progress {
    if (totalSeconds == 0) return 0;
    return (totalSeconds - remainingSeconds) / totalSeconds;
  }

  bool get isComplete => remainingSeconds <= 0 && totalSeconds > 0;
}

class RestTimerNotifier extends StateNotifier<RestTimerState> {
  Timer? _timer;

  RestTimerNotifier()
      : super(RestTimerState(
          remainingSeconds: 0,
          totalSeconds: 0,
          isRunning: false,
        )) {
    _restoreTimerState();
  }

  Future<void> _restoreTimerState() async {
    final saved = await WorkoutPersistenceService.loadTimerState();
    if (saved == null) return;

    final wasRunning = saved['isRunning'] as bool;
    if (!wasRunning) return;

    final startTimeStr = saved['startTime'] as String?;
    if (startTimeStr == null) return;

    final startTime = DateTime.parse(startTimeStr);
    final elapsed = DateTime.now().difference(startTime).inSeconds;
    final totalSeconds = saved['totalSeconds'] as int;
    final remainingSeconds = (totalSeconds - elapsed).clamp(0, totalSeconds);

    if (remainingSeconds > 0) {
      startTimer(remainingSeconds);
    } else {
      // Timer already completed while backgrounded - notification already fired
      state = RestTimerState(
        remainingSeconds: 0,
        totalSeconds: totalSeconds,
        isRunning: false,
      );
      await WorkoutPersistenceService.clearTimerState();
      // Clear the notification that already fired
      NotificationService().cancelRestTimerNotification();
    }
  }

  void startTimer(int seconds) {
    _timer?.cancel();

    final startTime = DateTime.now();
    state = RestTimerState(
      remainingSeconds: seconds,
      totalSeconds: seconds,
      isRunning: true,
      startTime: startTime,
    );

    // Save state for background restoration
    _saveTimerState();

    // Schedule background notification
    NotificationService().scheduleRestTimerNotification(seconds: seconds);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingSeconds > 0) {
        state = state.copyWith(
          remainingSeconds: state.remainingSeconds - 1,
        );
        _saveTimerState();
      } else {
        // Haptic feedback when timer completes
        HapticService.instance.success();
        state = state.copyWith(isRunning: false);
        _timer?.cancel();
        WorkoutPersistenceService.clearTimerState();
        // Cancel notification since timer completed in foreground
        NotificationService().cancelRestTimerNotification();
      }
    });
  }

  Future<void> _saveTimerState() async {
    await WorkoutPersistenceService.saveTimerState(
      remainingSeconds: state.remainingSeconds,
      totalSeconds: state.totalSeconds,
      isRunning: state.isRunning,
      startTime: state.startTime,
    );
  }

  void pause() {
    _timer?.cancel();
    state = state.copyWith(isRunning: false);
    // Cancel notification when paused
    NotificationService().cancelRestTimerNotification();
  }

  void resume() {
    if (state.remainingSeconds > 0) {
      startTimer(state.remainingSeconds);
    }
  }

  void stop() {
    _timer?.cancel();
    state = RestTimerState(
      remainingSeconds: 0,
      totalSeconds: 0,
      isRunning: false,
    );
    WorkoutPersistenceService.clearTimerState();
    // Cancel notification when stopped
    NotificationService().cancelRestTimerNotification();
  }

  void addTime(int seconds) {
    state = state.copyWith(
      remainingSeconds: state.remainingSeconds + seconds,
      totalSeconds: state.totalSeconds + seconds,
    );
    // Reschedule notification with updated time if timer is running
    if (state.isRunning) {
      NotificationService().scheduleRestTimerNotification(
        seconds: state.remainingSeconds,
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final restTimerProvider = StateNotifierProvider<RestTimerNotifier, RestTimerState>((ref) {
  return RestTimerNotifier();
});
