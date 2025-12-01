import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/colors.dart';
import '../providers/rest_timer_provider.dart';
import '../services/haptic_service.dart';

class RestTimerWidget extends ConsumerWidget {
  const RestTimerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(restTimerProvider);

    if (!timerState.isRunning && timerState.remainingSeconds == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: timerState.isComplete ? AppColors.success : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      timerState.isComplete ? 'Rest Complete!' : 'Rest Timer',
                      style: TextStyle(
                        color: timerState.isComplete ? Colors.white : AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(timerState.remainingSeconds),
                      style: TextStyle(
                        color: timerState.isComplete ? Colors.white : AppColors.primary,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  if (timerState.isRunning && !timerState.isComplete)
                    IconButton(
                      onPressed: () => ref.read(restTimerProvider.notifier).pause(),
                      icon: const Icon(Icons.pause, color: AppColors.textPrimary),
                    ),
                  if (!timerState.isRunning && !timerState.isComplete)
                    IconButton(
                      onPressed: () => ref.read(restTimerProvider.notifier).resume(),
                      icon: const Icon(Icons.play_arrow, color: AppColors.primary),
                    ),
                  IconButton(
                    onPressed: () => ref.read(restTimerProvider.notifier).stop(),
                    icon: Icon(
                      Icons.close,
                      color: timerState.isComplete ? Colors.white : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!timerState.isComplete) ...[
            LinearProgressIndicator(
              value: timerState.progress,
              backgroundColor: AppColors.surfaceElevated,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuickButton(
                  context,
                  ref,
                  '-15s',
                  Icons.fast_rewind,
                  () {
                    HapticService.instance.light();
                    ref.read(restTimerProvider.notifier).addTime(-15);
                  },
                ),
                _buildQuickButton(
                  context,
                  ref,
                  '+15s',
                  Icons.fast_forward,
                  () {
                    HapticService.instance.light();
                    ref.read(restTimerProvider.notifier).addTime(15);
                  },
                ),
                _buildQuickButton(
                  context,
                  ref,
                  '+30s',
                  Icons.add,
                  () {
                    HapticService.instance.light();
                    ref.read(restTimerProvider.notifier).addTime(30);
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickButton(
    BuildContext context,
    WidgetRef ref,
    String label,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16, color: AppColors.primary),
      label: Text(label, style: const TextStyle(color: AppColors.primary)),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.primary, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }
}
