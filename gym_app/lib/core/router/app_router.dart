import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/exercises/exercises_screen.dart';
import '../../screens/exercises/exercise_progress_screen.dart';
import '../../screens/workout/active_workout_screen.dart';
import '../../screens/history/history_screen.dart';
import '../../screens/history/workout_detail_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/profile/bodyweight_screen.dart';
import '../../screens/profile/body_measurements_screen.dart';
import '../../screens/profile/export_screen.dart';
import '../../screens/profile/personal_records_screen.dart';
import '../../screens/profile/statistics_screen.dart';
import '../../screens/profile/progress_photos_screen.dart';
import '../../screens/profile/workout_calendar_screen.dart';
import '../../screens/templates/templates_screen.dart';
import '../../screens/templates/template_editor_screen.dart';
import '../../models/workout_template.dart';
import '../../models/exercise.dart';
import '../../repositories/template_repository.dart';
import '../../repositories/exercise_repository.dart';
import '../theme/colors.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

class AppRouter {
  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/workout',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return MaterialPage(
            child: ActiveWorkoutScreen(initialData: extra),
          );
        },
      ),
      GoRoute(
        path: '/workout-detail/:id',
        pageBuilder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return MaterialPage(
            child: WorkoutDetailScreen(workoutId: id),
          );
        },
      ),
      GoRoute(
        path: '/exercise-progress/:id',
        pageBuilder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return MaterialPage(
            child: _ExerciseProgressLoader(exerciseId: id),
          );
        },
      ),
      GoRoute(
        path: '/bodyweight',
        pageBuilder: (context, state) => const MaterialPage(
          child: BodyweightScreen(),
        ),
      ),
      GoRoute(
        path: '/body-measurements',
        pageBuilder: (context, state) => const MaterialPage(
          child: BodyMeasurementsScreen(),
        ),
      ),
      GoRoute(
        path: '/export',
        pageBuilder: (context, state) => const MaterialPage(
          child: ExportScreen(),
        ),
      ),
      GoRoute(
        path: '/personal-records',
        pageBuilder: (context, state) => const MaterialPage(
          child: PersonalRecordsScreen(),
        ),
      ),
      GoRoute(
        path: '/statistics',
        pageBuilder: (context, state) => const MaterialPage(
          child: StatisticsScreen(),
        ),
      ),
      GoRoute(
        path: '/progress-photos',
        pageBuilder: (context, state) => const MaterialPage(
          child: ProgressPhotosScreen(),
        ),
      ),
      GoRoute(
        path: '/workout-calendar',
        pageBuilder: (context, state) => const MaterialPage(
          child: WorkoutCalendarScreen(),
        ),
      ),
      GoRoute(
        path: '/templates',
        pageBuilder: (context, state) => const MaterialPage(
          child: TemplatesScreen(),
        ),
      ),
      GoRoute(
        path: '/template-editor/:id',
        pageBuilder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return MaterialPage(
            child: _TemplateEditorLoader(templateId: id),
          );
        },
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return ScaffoldWithNavBar(child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/workouts',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: TemplatesScreen(),
            ),
          ),
          GoRoute(
            path: '/exercises',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ExercisesScreen(),
            ),
          ),
          GoRoute(
            path: '/history',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HistoryScreen(),
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
        ],
      ),
    ],
  );
}

class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) => _onItemTapped(index, context),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.note_alt),
            label: 'Temp',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Exercises',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/workouts')) return 1;
    if (location.startsWith('/exercises')) return 2;
    if (location.startsWith('/history')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    // Get target route
    String targetRoute;
    switch (index) {
      case 0:
        targetRoute = '/home';
        break;
      case 1:
        targetRoute = '/workouts';
        break;
      case 2:
        targetRoute = '/exercises';
        break;
      case 3:
        targetRoute = '/history';
        break;
      case 4:
        targetRoute = '/profile';
        break;
      default:
        targetRoute = '/home';
    }

    // Check if we're already on this tab
    final currentLocation = GoRouterState.of(context).uri.path;
    if (currentLocation == targetRoute) {
      return; // Already on this tab
    }

    // Use go to navigate - this replaces the entire navigation stack
    context.go(targetRoute);
  }
}

class _TemplateEditorLoader extends ConsumerWidget {
  final int templateId;

  const _TemplateEditorLoader({required this.templateId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<WorkoutTemplate?>(
      future: TemplateRepository().getTemplate(templateId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(title: const Text('Error')),
            body: const Center(
              child: Text(
                'Template not found',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          );
        }

        return TemplateEditorScreen(template: snapshot.data!);
      },
    );
  }
}

class _ExerciseProgressLoader extends ConsumerWidget {
  final int exerciseId;

  const _ExerciseProgressLoader({required this.exerciseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<Exercise?>(
      future: ExerciseRepository().getExerciseById(exerciseId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(title: const Text('Error')),
            body: const Center(
              child: Text(
                'Exercise not found',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          );
        }

        return ExerciseProgressScreen(exercise: snapshot.data!);
      },
    );
  }
}
