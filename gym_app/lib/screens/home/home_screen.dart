import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../widgets/start_workout_dialog.dart';
import '../progress/progress_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    // Use smaller dimension to calculate padding (7% of smaller dimension)
    final smallerDimension = screenWidth < screenHeight ? screenWidth : screenHeight;
    final logoPadding = smallerDimension * 0.07;
    final borderRadius = smallerDimension * 0.03;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top section with logo - takes up remaining space
            Expanded(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(logoPadding),
                decoration: const BoxDecoration(
                  color: AppColors.background,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(borderRadius),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Use contain to ensure logo never overflows
                      return Image.asset(
                        'assets/ironlog.jpg',
                        fit: BoxFit.contain,
                        alignment: Alignment.center,
                      );
                    },
                  ),
                ),
              ),
            ),
            // Bottom section with buttons
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => const StartWorkoutDialog(),
                        );
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start Workout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProgressScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.trending_up, color: AppColors.primary),
                      label: const Text(
                        'View Progress',
                        style: TextStyle(color: AppColors.primary),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary, width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
