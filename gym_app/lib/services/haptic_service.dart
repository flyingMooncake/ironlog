import 'package:vibration/vibration.dart';

class HapticService {
  static final HapticService instance = HapticService._();
  HapticService._();

  bool _hasVibrator = false;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _hasVibrator = await Vibration.hasVibrator() ?? false;
    _isInitialized = true;
  }

  /// Light tap feedback for normal button presses
  Future<void> light() async {
    await initialize();
    if (_hasVibrator) {
      await Vibration.vibrate(duration: 10, amplitude: 50);
    }
  }

  /// Medium feedback for important actions (adding sets, starting timer)
  Future<void> medium() async {
    await initialize();
    if (_hasVibrator) {
      await Vibration.vibrate(duration: 20, amplitude: 100);
    }
  }

  /// Heavy feedback for major actions (completing workout)
  Future<void> heavy() async {
    await initialize();
    if (_hasVibrator) {
      await Vibration.vibrate(duration: 50, amplitude: 150);
    }
  }

  /// Success pattern for achievements (PRs, goals completed)
  Future<void> success() async {
    await initialize();
    if (_hasVibrator) {
      await Vibration.vibrate(duration: 100, amplitude: 200);
      await Future.delayed(const Duration(milliseconds: 100));
      await Vibration.vibrate(duration: 100, amplitude: 200);
    }
  }

  /// Error/warning feedback
  Future<void> error() async {
    await initialize();
    if (_hasVibrator) {
      await Vibration.vibrate(duration: 200, amplitude: 255);
    }
  }

  /// Selection feedback (choosing options)
  Future<void> selection() async {
    await initialize();
    if (_hasVibrator) {
      await Vibration.vibrate(duration: 5, amplitude: 30);
    }
  }
}
