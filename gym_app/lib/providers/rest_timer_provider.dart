import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/haptic_service.dart';

class RestTimerState {
  final int remainingSeconds;
  final int totalSeconds;
  final bool isRunning;

  RestTimerState({
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.isRunning,
  });

  RestTimerState copyWith({
    int? remainingSeconds,
    int? totalSeconds,
    bool? isRunning,
  }) {
    return RestTimerState(
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      isRunning: isRunning ?? this.isRunning,
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
        ));

  void startTimer(int seconds) {
    _timer?.cancel();

    state = RestTimerState(
      remainingSeconds: seconds,
      totalSeconds: seconds,
      isRunning: true,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingSeconds > 0) {
        state = state.copyWith(
          remainingSeconds: state.remainingSeconds - 1,
        );
      } else {
        // Haptic feedback when timer completes
        HapticService.instance.success();
        state = state.copyWith(isRunning: false);
        _timer?.cancel();
      }
    });
  }

  void pause() {
    _timer?.cancel();
    state = state.copyWith(isRunning: false);
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
  }

  void addTime(int seconds) {
    state = state.copyWith(
      remainingSeconds: state.remainingSeconds + seconds,
      totalSeconds: state.totalSeconds + seconds,
    );
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
