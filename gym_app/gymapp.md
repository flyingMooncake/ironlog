# IronLog - Free Gym Tracker (Flutter)

## Project Overview

Build an **offline-first** native gym tracking app using Flutter with local SQLite storage. Zero backend, zero internet required. Develop on Ubuntu, deploy directly to your iPhone via USB.

**Stack:**
- **Framework:** Flutter 3.19+
- **Language:** Dart
- **Database:** sqflite (SQLite, offline-first)
- **State:** Riverpod 2.0
- **Navigation:** go_router
- **Charts:** fl_chart

---

## Setup on Ubuntu

### 1. Install Flutter

```bash
# Install dependencies
sudo apt update
sudo apt install -y curl git unzip xz-utils zip libglu1-mesa clang cmake ninja-build pkg-config libgtk-3-dev

# Download Flutter
cd ~
git clone https://github.com/flutter/flutter.git -b stable
echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.bashrc
source ~/.bashrc

# Verify installation
flutter doctor
```

### 2. iOS Development Setup (No Mac Needed for Dev!)

```bash
# Install ideviceinstaller and related tools
sudo apt install -y ideviceinstaller libimobiledevice-utils ifuse usbmuxd

# Start usbmuxd service
sudo systemctl start usbmuxd
sudo systemctl enable usbmuxd
```

### 3. Connect Your iPhone

1. Plug iPhone into Ubuntu via USB
2. Trust the computer on your iPhone when prompted
3. Verify connection:
```bash
idevice_id -l  # Should show your device ID
flutter devices  # Should list your iPhone
```

### 4. Create Project

```bash
flutter create ironlog --org com.ironlog --platforms=ios,android
cd ironlog

# Add dependencies to pubspec.yaml (see below)
flutter pub get
```

### 5. Run on iPhone

```bash
# First run takes longer (builds iOS app)
flutter run -d <your-iphone-id>

# Or just
flutter run  # If iPhone is the only device connected
```

**Note:** First iOS build requires signing. Flutter will guide you through creating a free development certificate using your Apple ID.

---

## pubspec.yaml

```yaml
name: ironlog
description: Free gym tracker. No ads. No subscriptions. Ever.
version: 1.0.0+1

environment:
  sdk: '>=3.2.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  flutter_riverpod: ^2.4.9
  riverpod_annotation: ^2.3.3
  
  # Database
  sqflite: ^2.3.2
  path: ^1.8.3
  
  # Navigation
  go_router: ^13.2.0
  
  # UI
  fl_chart: ^0.66.2
  flutter_slidable: ^3.0.1
  vibration: ^1.8.4
  
  # Utils
  uuid: ^4.3.3
  intl: ^0.19.0
  collection: ^1.18.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1
  riverpod_generator: ^2.3.9
  build_runner: ^2.4.8

flutter:
  uses-material-design: true
  
  fonts:
    - family: Inter
      fonts:
        - asset: assets/fonts/Inter-Regular.ttf
        - asset: assets/fonts/Inter-Medium.ttf
          weight: 500
        - asset: assets/fonts/Inter-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Inter-Bold.ttf
          weight: 700
```

---

## Project Structure

```
ironlog/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   │
│   ├── core/
│   │   ├── database/
│   │   │   ├── database_helper.dart
│   │   │   ├── schema.dart
│   │   │   └── seed_data.dart
│   │   ├── theme/
│   │   │   ├── app_theme.dart
│   │   │   ├── colors.dart
│   │   │   └── typography.dart
│   │   ├── utils/
│   │   │   ├── calculations.dart
│   │   │   ├── formatters.dart
│   │   │   └── constants.dart
│   │   └── router/
│   │       └── app_router.dart
│   │
│   ├── models/
│   │   ├── exercise.dart
│   │   ├── workout_session.dart
│   │   ├── workout_set.dart
│   │   ├── user_profile.dart
│   │   ├── exercise_target.dart
│   │   └── personal_record.dart
│   │
│   ├── repositories/
│   │   ├── exercise_repository.dart
│   │   ├── workout_repository.dart
│   │   ├── set_repository.dart
│   │   ├── user_repository.dart
│   │   └── target_repository.dart
│   │
│   ├── providers/
│   │   ├── database_provider.dart
│   │   ├── exercise_provider.dart
│   │   ├── workout_provider.dart
│   │   ├── active_workout_provider.dart
│   │   ├── user_provider.dart
│   │   ├── timer_provider.dart
│   │   └── stats_provider.dart
│   │
│   ├── screens/
│   │   ├── home/
│   │   │   ├── home_screen.dart
│   │   │   └── widgets/
│   │   ├── workout/
│   │   │   ├── active_workout_screen.dart
│   │   │   ├── exercise_picker_screen.dart
│   │   │   └── widgets/
│   │   ├── history/
│   │   │   ├── history_screen.dart
│   │   │   ├── workout_detail_screen.dart
│   │   │   └── widgets/
│   │   ├── exercises/
│   │   │   ├── exercises_screen.dart
│   │   │   ├── exercise_detail_screen.dart
│   │   │   ├── create_exercise_screen.dart
│   │   │   └── widgets/
│   │   ├── progress/
│   │   │   ├── progress_screen.dart
│   │   │   ├── exercise_progress_screen.dart
│   │   │   └── widgets/
│   │   ├── profile/
│   │   │   ├── profile_screen.dart
│   │   │   ├── settings_screen.dart
│   │   │   └── widgets/
│   │   └── targets/
│   │       ├── targets_screen.dart
│   │       └── widgets/
│   │
│   └── widgets/
│       ├── common/
│       │   ├── app_button.dart
│       │   ├── app_card.dart
│       │   ├── app_input.dart
│       │   ├── numpad.dart
│       │   └── loading_indicator.dart
│       ├── workout/
│       │   ├── set_row.dart
│       │   ├── exercise_card.dart
│       │   ├── rest_timer.dart
│       │   └── superset_badge.dart
│       └── charts/
│           ├── progress_chart.dart
│           ├── volume_chart.dart
│           └── workout_calendar.dart
│
├── assets/
│   └── fonts/
│
├── ios/
├── android/
├── pubspec.yaml
└── README.md
```

---

## Database Layer

### Database Helper

```dart
// lib/core/database/database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'schema.dart';
import 'seed_data.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('ironlog.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onOpen: _onOpen,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute(Schema.createUserProfile);
    await db.execute(Schema.createWeightHistory);
    await db.execute(Schema.createExercises);
    await db.execute(Schema.createWorkoutSessions);
    await db.execute(Schema.createWorkoutSets);
    await db.execute(Schema.createExerciseTargets);
    await db.execute(Schema.createPersonalRecords);
    await db.execute(Schema.createAppMeta);

    // Create indexes
    await db.execute(Schema.indexSetsSession);
    await db.execute(Schema.indexSetsExercise);
    await db.execute(Schema.indexSessionsDate);
    await db.execute(Schema.indexExercisesMuscle);

    // Seed exercises
    await SeedData.seedExercises(db);
  }

  Future<void> _onOpen(Database db) async {
    // Check if seeded, seed if not
    final result = await db.query(
      'app_meta',
      where: 'key = ?',
      whereArgs: ['exercises_seeded'],
    );
    if (result.isEmpty) {
      await SeedData.seedExercises(db);
    }
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
```

### Schema

```dart
// lib/core/database/schema.dart
class Schema {
  static const String createUserProfile = '''
    CREATE TABLE IF NOT EXISTS user_profile (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      weight REAL,
      height REAL,
      age INTEGER,
      unit_system TEXT DEFAULT 'metric',
      rest_timer_default INTEGER DEFAULT 90,
      created_at TEXT DEFAULT (datetime('now')),
      updated_at TEXT DEFAULT (datetime('now'))
    )
  ''';

  static const String createWeightHistory = '''
    CREATE TABLE IF NOT EXISTS weight_history (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      weight REAL NOT NULL,
      recorded_at TEXT DEFAULT (datetime('now'))
    )
  ''';

  static const String createExercises = '''
    CREATE TABLE IF NOT EXISTS exercises (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL UNIQUE,
      primary_muscle TEXT NOT NULL,
      secondary_muscles TEXT,
      tracking_type TEXT DEFAULT 'weight_reps',
      equipment TEXT,
      is_custom INTEGER DEFAULT 0,
      notes TEXT,
      created_at TEXT DEFAULT (datetime('now'))
    )
  ''';

  static const String createWorkoutSessions = '''
    CREATE TABLE IF NOT EXISTS workout_sessions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT,
      started_at TEXT NOT NULL,
      finished_at TEXT,
      duration_minutes INTEGER,
      total_volume REAL,
      notes TEXT,
      bodyweight REAL
    )
  ''';

  static const String createWorkoutSets = '''
    CREATE TABLE IF NOT EXISTS workout_sets (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      session_id INTEGER NOT NULL,
      exercise_id INTEGER NOT NULL,
      set_order INTEGER NOT NULL,
      weight REAL,
      reps INTEGER,
      duration_seconds INTEGER,
      rpe INTEGER,
      is_warmup INTEGER DEFAULT 0,
      superset_id TEXT,
      notes TEXT,
      completed_at TEXT DEFAULT (datetime('now')),
      FOREIGN KEY (session_id) REFERENCES workout_sessions(id) ON DELETE CASCADE,
      FOREIGN KEY (exercise_id) REFERENCES exercises(id)
    )
  ''';

  static const String createExerciseTargets = '''
    CREATE TABLE IF NOT EXISTS exercise_targets (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      exercise_id INTEGER NOT NULL,
      target_type TEXT NOT NULL,
      target_value REAL NOT NULL,
      current_value REAL DEFAULT 0,
      deadline TEXT,
      achieved_at TEXT,
      created_at TEXT DEFAULT (datetime('now')),
      FOREIGN KEY (exercise_id) REFERENCES exercises(id) ON DELETE CASCADE
    )
  ''';

  static const String createPersonalRecords = '''
    CREATE TABLE IF NOT EXISTS personal_records (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      exercise_id INTEGER NOT NULL,
      record_type TEXT NOT NULL,
      value REAL NOT NULL,
      weight REAL,
      reps INTEGER,
      set_id INTEGER,
      achieved_at TEXT DEFAULT (datetime('now')),
      FOREIGN KEY (exercise_id) REFERENCES exercises(id) ON DELETE CASCADE
    )
  ''';

  static const String createAppMeta = '''
    CREATE TABLE IF NOT EXISTS app_meta (
      key TEXT PRIMARY KEY,
      value TEXT
    )
  ''';

  // Indexes
  static const String indexSetsSession = 
    'CREATE INDEX IF NOT EXISTS idx_sets_session ON workout_sets(session_id)';
  static const String indexSetsExercise = 
    'CREATE INDEX IF NOT EXISTS idx_sets_exercise ON workout_sets(exercise_id)';
  static const String indexSessionsDate = 
    'CREATE INDEX IF NOT EXISTS idx_sessions_date ON workout_sessions(started_at)';
  static const String indexExercisesMuscle = 
    'CREATE INDEX IF NOT EXISTS idx_exercises_muscle ON exercises(primary_muscle)';
}
```

---

## Models

```dart
// lib/models/exercise.dart
enum MuscleGroup {
  chest, back, shoulders, biceps, triceps, forearms,
  quads, hamstrings, glutes, calves,
  abs, obliques, lowerBack,
  traps, lats,
  fullBody, cardio;

  String get displayName {
    switch (this) {
      case MuscleGroup.lowerBack: return 'Lower Back';
      case MuscleGroup.fullBody: return 'Full Body';
      default: return name[0].toUpperCase() + name.substring(1);
    }
  }
}

enum TrackingType {
  weightReps,    // Bench press, squat
  repsOnly,      // Pull-ups (bodyweight)
  time,          // Plank, wall sit
  weightTime;    // Farmer walks

  String get displayName {
    switch (this) {
      case TrackingType.weightReps: return 'Weight & Reps';
      case TrackingType.repsOnly: return 'Reps Only';
      case TrackingType.time: return 'Time';
      case TrackingType.weightTime: return 'Weight & Time';
    }
  }
}

enum Equipment {
  barbell, dumbbell, cable, machine, bodyweight, kettlebell, bands, other;

  String get displayName => name[0].toUpperCase() + name.substring(1);
}

class Exercise {
  final int? id;
  final String name;
  final MuscleGroup primaryMuscle;
  final List<MuscleGroup> secondaryMuscles;
  final TrackingType trackingType;
  final Equipment? equipment;
  final bool isCustom;
  final String? notes;
  final DateTime createdAt;

  Exercise({
    this.id,
    required this.name,
    required this.primaryMuscle,
    this.secondaryMuscles = const [],
    this.trackingType = TrackingType.weightReps,
    this.equipment,
    this.isCustom = false,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      id: map['id'] as int?,
      name: map['name'] as String,
      primaryMuscle: MuscleGroup.values.firstWhere(
        (e) => e.name == map['primary_muscle'],
        orElse: () => MuscleGroup.fullBody,
      ),
      secondaryMuscles: (map['secondary_muscles'] as String?)
          ?.split(',')
          .where((s) => s.isNotEmpty)
          .map((s) => MuscleGroup.values.firstWhere(
                (e) => e.name == s.trim(),
                orElse: () => MuscleGroup.fullBody,
              ))
          .toList() ?? [],
      trackingType: TrackingType.values.firstWhere(
        (e) => e.name == _snakeToCamel(map['tracking_type'] ?? 'weight_reps'),
        orElse: () => TrackingType.weightReps,
      ),
      equipment: map['equipment'] != null
          ? Equipment.values.firstWhere(
              (e) => e.name == map['equipment'],
              orElse: () => Equipment.other,
            )
          : null,
      isCustom: map['is_custom'] == 1,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'primary_muscle': primaryMuscle.name,
      'secondary_muscles': secondaryMuscles.map((e) => e.name).join(','),
      'tracking_type': _camelToSnake(trackingType.name),
      'equipment': equipment?.name,
      'is_custom': isCustom ? 1 : 0,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  static String _snakeToCamel(String s) {
    return s.replaceAllMapped(
      RegExp(r'_([a-z])'),
      (m) => m.group(1)!.toUpperCase(),
    );
  }

  static String _camelToSnake(String s) {
    return s.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (m) => '_${m.group(0)!.toLowerCase()}',
    );
  }
}

// lib/models/workout_session.dart
class WorkoutSession {
  final int? id;
  final String? name;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final int? durationMinutes;
  final double? totalVolume;
  final String? notes;
  final double? bodyweight;

  WorkoutSession({
    this.id,
    this.name,
    required this.startedAt,
    this.finishedAt,
    this.durationMinutes,
    this.totalVolume,
    this.notes,
    this.bodyweight,
  });

  factory WorkoutSession.fromMap(Map<String, dynamic> map) {
    return WorkoutSession(
      id: map['id'] as int?,
      name: map['name'] as String?,
      startedAt: DateTime.parse(map['started_at'] as String),
      finishedAt: map['finished_at'] != null 
          ? DateTime.parse(map['finished_at'] as String) 
          : null,
      durationMinutes: map['duration_minutes'] as int?,
      totalVolume: map['total_volume'] as double?,
      notes: map['notes'] as String?,
      bodyweight: map['bodyweight'] as double?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'started_at': startedAt.toIso8601String(),
      'finished_at': finishedAt?.toIso8601String(),
      'duration_minutes': durationMinutes,
      'total_volume': totalVolume,
      'notes': notes,
      'bodyweight': bodyweight,
    };
  }

  WorkoutSession copyWith({
    int? id,
    String? name,
    DateTime? startedAt,
    DateTime? finishedAt,
    int? durationMinutes,
    double? totalVolume,
    String? notes,
    double? bodyweight,
  }) {
    return WorkoutSession(
      id: id ?? this.id,
      name: name ?? this.name,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      totalVolume: totalVolume ?? this.totalVolume,
      notes: notes ?? this.notes,
      bodyweight: bodyweight ?? this.bodyweight,
    );
  }
}

// lib/models/workout_set.dart
class WorkoutSet {
  final int? id;
  final int sessionId;
  final int exerciseId;
  final int setOrder;
  final double? weight;
  final int? reps;
  final int? durationSeconds;
  final int? rpe;
  final bool isWarmup;
  final String? supersetId;
  final String? notes;
  final DateTime completedAt;

  WorkoutSet({
    this.id,
    required this.sessionId,
    required this.exerciseId,
    required this.setOrder,
    this.weight,
    this.reps,
    this.durationSeconds,
    this.rpe,
    this.isWarmup = false,
    this.supersetId,
    this.notes,
    DateTime? completedAt,
  }) : completedAt = completedAt ?? DateTime.now();

  factory WorkoutSet.fromMap(Map<String, dynamic> map) {
    return WorkoutSet(
      id: map['id'] as int?,
      sessionId: map['session_id'] as int,
      exerciseId: map['exercise_id'] as int,
      setOrder: map['set_order'] as int,
      weight: map['weight'] as double?,
      reps: map['reps'] as int?,
      durationSeconds: map['duration_seconds'] as int?,
      rpe: map['rpe'] as int?,
      isWarmup: map['is_warmup'] == 1,
      supersetId: map['superset_id'] as String?,
      notes: map['notes'] as String?,
      completedAt: DateTime.parse(map['completed_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'session_id': sessionId,
      'exercise_id': exerciseId,
      'set_order': setOrder,
      'weight': weight,
      'reps': reps,
      'duration_seconds': durationSeconds,
      'rpe': rpe,
      'is_warmup': isWarmup ? 1 : 0,
      'superset_id': supersetId,
      'notes': notes,
      'completed_at': completedAt.toIso8601String(),
    };
  }

  double get volume => (weight ?? 0) * (reps ?? 0);
}

// lib/models/user_profile.dart
enum UnitSystem { metric, imperial }

class UserProfile {
  final int? id;
  final double? weight;
  final double? height;
  final int? age;
  final UnitSystem unitSystem;
  final int restTimerDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    this.id,
    this.weight,
    this.height,
    this.age,
    this.unitSystem = UnitSystem.metric,
    this.restTimerDefault = 90,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as int?,
      weight: map['weight'] as double?,
      height: map['height'] as double?,
      age: map['age'] as int?,
      unitSystem: map['unit_system'] == 'imperial' 
          ? UnitSystem.imperial 
          : UnitSystem.metric,
      restTimerDefault: map['rest_timer_default'] as int? ?? 90,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'weight': weight,
      'height': height,
      'age': age,
      'unit_system': unitSystem.name,
      'rest_timer_default': restTimerDefault,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get weightUnit => unitSystem == UnitSystem.metric ? 'kg' : 'lbs';
  String get heightUnit => unitSystem == UnitSystem.metric ? 'cm' : 'in';
}
```

---

## Calculations

```dart
// lib/core/utils/calculations.dart

/// Calculate volume for a single set
double calculateSetVolume(double? weight, int? reps) {
  if (weight == null || reps == null) return 0;
  return weight * reps;
}

/// Estimated 1RM using Epley formula: 1RM = weight × (1 + reps/30)
double calculateEpley1RM(double weight, int reps) {
  if (reps == 1) return weight;
  if (reps <= 0 || weight <= 0) return 0;
  return weight * (1 + reps / 30);
}

/// Estimated 1RM using Brzycki formula: 1RM = weight × (36 / (37 - reps))
double calculateBrzycki1RM(double weight, int reps) {
  if (reps == 1) return weight;
  if (reps >= 37 || reps <= 0 || weight <= 0) return 0;
  return weight * (36 / (37 - reps));
}

/// Calculate 1RM with selectable formula
double calculate1RM(double weight, int reps, {bool useBrzycki = false}) {
  if (useBrzycki) return calculateBrzycki1RM(weight, reps);
  return calculateEpley1RM(weight, reps);
}

/// Convert kg to lbs
double kgToLbs(double kg) => kg * 2.20462;

/// Convert lbs to kg
double lbsToKg(double lbs) => lbs / 2.20462;

/// Format duration in seconds to mm:ss
String formatDuration(int seconds) {
  final mins = seconds ~/ 60;
  final secs = seconds % 60;
  return '$mins:${secs.toString().padLeft(2, '0')}';
}

/// Format weight with unit
String formatWeight(double weight, String unit) {
  return '${weight.toStringAsFixed(weight.truncateToDouble() == weight ? 0 : 1)} $unit';
}
```

---

## Theme

```dart
// lib/core/theme/colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // Primary
  static const primary = Color(0xFFFF4444);
  static const primaryDark = Color(0xFFCC3636);

  // Backgrounds
  static const background = Color(0xFF0D0D0D);
  static const surface = Color(0xFF1A1A1A);
  static const surfaceElevated = Color(0xFF262626);
  static const surfaceHighlight = Color(0xFF333333);

  // Text
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF888888);
  static const textMuted = Color(0xFF555555);

  // Semantic
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);

  // Muscle groups (for charts)
  static const muscleColors = {
    'chest': Color(0xFFFF6B6B),
    'back': Color(0xFF4ECDC4),
    'shoulders': Color(0xFF45B7D1),
    'biceps': Color(0xFF96CEB4),
    'triceps': Color(0xFFFFEAA7),
    'forearms': Color(0xFFDDA0DD),
    'quads': Color(0xFF98D8C8),
    'hamstrings': Color(0xFFF7DC6F),
    'glutes': Color(0xFFBB8FCE),
    'calves': Color(0xFF85C1E9),
    'abs': Color(0xFFF8B500),
    'lowerBack': Color(0xFF58D68D),
    'fullBody': Color(0xFFAF7AC5),
    'cardio': Color(0xFFEC7063),
  };
}

// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'colors.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardTheme(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }
}
```

---

## Seed Data (150+ Exercises)

```dart
// lib/core/database/seed_data.dart
import 'package:sqflite/sqflite.dart';

class SeedData {
  static Future<void> seedExercises(Database db) async {
    final exercises = [
      // === CHEST (12) ===
      {'name': 'Barbell Bench Press', 'primary_muscle': 'chest', 'secondary_muscles': 'triceps,shoulders', 'tracking_type': 'weight_reps', 'equipment': 'barbell'},
      {'name': 'Incline Barbell Bench Press', 'primary_muscle': 'chest', 'secondary_muscles': 'triceps,shoulders', 'tracking_type': 'weight_reps', 'equipment': 'barbell'},
      {'name': 'Decline Barbell Bench Press', 'primary_muscle': 'chest', 'secondary_muscles': 'triceps', 'tracking_type': 'weight_reps', 'equipment': 'barbell'},
      {'name': 'Dumbbell Bench Press', 'primary_muscle': 'chest', 'secondary_muscles': 'triceps,shoulders', 'tracking_type': 'weight_reps', 'equipment': 'dumbbell'},
      {'name': 'Incline Dumbbell Press', 'primary_muscle': 'chest', 'secondary_muscles': 'triceps,shoulders', 'tracking_type': 'weight_reps', 'equipment': 'dumbbell'},
      {'name': 'Dumbbell Fly', 'primary_muscle': 'chest', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'dumbbell'},
      {'name': 'Cable Fly (Low to High)', 'primary_muscle': 'chest', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'cable'},
      {'name': 'Cable Fly (High to Low)', 'primary_muscle': 'chest', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'cable'},
      {'name': 'Machine Chest Press', 'primary_muscle': 'chest', 'secondary_muscles': 'triceps', 'tracking_type': 'weight_reps', 'equipment': 'machine'},
      {'name': 'Pec Deck Machine', 'primary_muscle': 'chest', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'machine'},
      {'name': 'Push-ups', 'primary_muscle': 'chest', 'secondary_muscles': 'triceps,shoulders', 'tracking_type': 'reps_only', 'equipment': 'bodyweight'},
      {'name': 'Dips (Chest Focus)', 'primary_muscle': 'chest', 'secondary_muscles': 'triceps,shoulders', 'tracking_type': 'weight_reps', 'equipment': 'bodyweight'},

      // === BACK (15) ===
      {'name': 'Conventional Deadlift', 'primary_muscle': 'back', 'secondary_muscles': 'hamstrings,glutes,lowerBack', 'tracking_type': 'weight_reps', 'equipment': 'barbell'},
      {'name': 'Barbell Row', 'primary_muscle': 'back', 'secondary_muscles': 'biceps,lats', 'tracking_type': 'weight_reps', 'equipment': 'barbell'},
      {'name': 'Pendlay Row', 'primary_muscle': 'back', 'secondary_muscles': 'biceps,lats', 'tracking_type': 'weight_reps', 'equipment': 'barbell'},
      {'name': 'Dumbbell Row', 'primary_muscle': 'back', 'secondary_muscles': 'biceps,lats', 'tracking_type': 'weight_reps', 'equipment': 'dumbbell'},
      {'name': 'T-Bar Row', 'primary_muscle': 'back', 'secondary_muscles': 'biceps,lats', 'tracking_type': 'weight_reps', 'equipment': 'barbell'},
      {'name': 'Seated Cable Row', 'primary_muscle': 'back', 'secondary_muscles': 'biceps,lats', 'tracking_type': 'weight_reps', 'equipment': 'cable'},
      {'name': 'Lat Pulldown (Wide Grip)', 'primary_muscle': 'lats', 'secondary_muscles': 'biceps,back', 'tracking_type': 'weight_reps', 'equipment': 'cable'},
      {'name': 'Lat Pulldown (Close Grip)', 'primary_muscle': 'lats', 'secondary_muscles': 'biceps,back', 'tracking_type': 'weight_reps', 'equipment': 'cable'},
      {'name': 'Pull-ups', 'primary_muscle': 'lats', 'secondary_muscles': 'biceps,back', 'tracking_type': 'reps_only', 'equipment': 'bodyweight'},
      {'name': 'Chin-ups', 'primary_muscle': 'lats', 'secondary_muscles': 'biceps,back', 'tracking_type': 'reps_only', 'equipment': 'bodyweight'},
      {'name': 'Face Pulls', 'primary_muscle': 'back', 'secondary_muscles': 'shoulders,traps', 'tracking_type': 'weight_reps', 'equipment': 'cable'},
      {'name': 'Straight Arm Pulldown', 'primary_muscle': 'lats', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'cable'},
      {'name': 'Machine Row', 'primary_muscle': 'back', 'secondary_muscles': 'biceps', 'tracking_type': 'weight_reps', 'equipment': 'machine'},
      {'name': 'Rack Pulls', 'primary_muscle': 'back', 'secondary_muscles': 'traps,lowerBack', 'tracking_type': 'weight_reps', 'equipment': 'barbell'},
      {'name': 'Good Mornings', 'primary_muscle': 'lowerBack', 'secondary_muscles': 'hamstrings,glutes', 'tracking_type': 'weight_reps', 'equipment': 'barbell'},

      // === SHOULDERS (12) ===
      {'name': 'Overhead Press (Barbell)', 'primary_muscle': 'shoulders', 'secondary_muscles': 'triceps', 'tracking_type': 'weight_reps', 'equipment': 'barbell'},
      {'name': 'Seated Dumbbell Press', 'primary_muscle': 'shoulders', 'secondary_muscles': 'triceps', 'tracking_type': 'weight_reps', 'equipment': 'dumbbell'},
      {'name': 'Arnold Press', 'primary_muscle': 'shoulders', 'secondary_muscles': 'triceps', 'tracking_type': 'weight_reps', 'equipment': 'dumbbell'},
      {'name': 'Lateral Raises', 'primary_muscle': 'shoulders', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'dumbbell'},
      {'name': 'Front Raises', 'primary_muscle': 'shoulders', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'dumbbell'},
      {'name': 'Rear Delt Fly', 'primary_muscle': 'shoulders', 'secondary_muscles': 'back', 'tracking_type': 'weight_reps', 'equipment': 'dumbbell'},
      {'name': 'Cable Lateral Raise', 'primary_muscle': 'shoulders', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'cable'},
      {'name': 'Upright Row', 'primary_muscle': 'shoulders', 'secondary_muscles': 'traps', 'tracking_type': 'weight_reps', 'equipment': 'barbell'},
      {'name': 'Machine Shoulder Press', 'primary_muscle': 'shoulders', 'secondary_muscles': 'triceps', 'tracking_type': 'weight_reps', 'equipment': 'machine'},
      {'name': 'Barbell Shrugs', 'primary_muscle': 'traps', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'barbell'},
      {'name': 'Dumbbell Shrugs', 'primary_muscle': 'traps', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'dumbbell'},
      {'name': 'Reverse Pec Deck', 'primary_muscle': 'shoulders', 'secondary_muscles': 'back', 'tracking_type': 'weight_reps', 'equipment': 'machine'},

      // === BICEPS (10) ===
      {'name': 'Barbell Curl', 'primary_muscle': 'biceps', 'secondary_muscles': 'forearms', 'tracking_type': 'weight_reps', 'equipment': 'barbell'},
      {'name': 'EZ Bar Curl', 'primary_muscle': 'biceps', 'secondary_muscles': 'forearms', 'tracking_type': 'weight_reps', 'equipment': 'barbell'},
      {'name': 'Dumbbell Curl', 'primary_muscle': 'biceps', 'secondary_muscles': 'forearms', 'tracking_type': 'weight_reps', 'equipment': 'dumbbell'},
      {'name': 'Hammer Curl', 'primary_muscle': 'biceps', 'secondary_muscles': 'forearms', 'tracking_type': 'weight_reps', 'equipment': 'dumbbell'},
      {'name': 'Preacher Curl', 'primary_muscle': 'biceps', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'barbell'},
      {'name': 'Concentration Curl', 'primary_muscle': 'biceps', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'dumbbell'},
      {'name': 'Cable Curl', 'primary_muscle': 'biceps', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'cable'},
      {'name': 'Incline Dumbbell Curl', 'primary_muscle': 'biceps', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'dumbbell'},
      {'name': 'Spider Curl', 'primary_muscle': 'biceps', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'dumbbell'},
      {'name': 'Reverse Curl', 'primary_muscle': 'biceps', 'secondary_muscles': 'forearms', 'tracking_type': 'weight_reps', 'equipment': 'barbell'},

      // === TRICEPS (10) ===
      {'name': 'Close Grip Bench Press', 'primary_muscle': 'triceps', 'secondary_muscles': 'chest', 'tracking_type': 'weight_reps', 'equipment': 'barbell'},
      {'name': 'Skull Crushers', 'primary_muscle': 'triceps', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'barbell'},
      {'name': 'Tricep Pushdown (Rope)', 'primary_muscle': 'triceps', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'cable'},
      {'name': 'Tricep Pushdown (Bar)', 'primary_muscle': 'triceps', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'cable'},
      {'name': 'Overhead Tricep Extension', 'primary_muscle': 'triceps', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'dumbbell'},
      {'name': 'Dumbbell Kickback', 'primary_muscle': 'triceps', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'dumbbell'},
      {'name': 'Diamond Push-ups', 'primary_muscle': 'triceps', 'secondary_muscles': 'chest', 'tracking_type': 'reps_only', 'equipment': 'bodyweight'},
      {'name': 'Dips (Tricep Focus)', 'primary_muscle': 'triceps', 'secondary_muscles': 'chest,shoulders', 'tracking_type': 'weight_reps', 'equipment': 'bodyweight'},
      {'name': 'Cable Overhead Extension', 'primary_muscle': 'triceps', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'cable'},
      {'name': 'Machine Tricep Extension', 'primary_muscle': 'triceps', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'machine'},

      // === FOREARMS (6) ===
      {'name': 'Wrist Curls', 'primary_muscle': 'forearms', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'barbell'},
      {'name': 'Reverse Wrist Curls', 'primary_muscle': 'forearms', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'barbell'},
      {'name': 'Farmer Walks', 'primary_muscle': 'forearms', 'secondary_muscles': 'traps,fullBody', 'tracking_type': 'weight_time', 'equipment': 'dumbbell'},
      {'name': 'Dead Hangs', 'primary_muscle': 'forearms', 'secondary_muscles': 'lats', 'tracking_type': 'time', 'equipment': 'bodyweight'},
      {'name': 'Plate Pinch', 'primary_muscle': 'forearms', 'secondary_muscles': '', 'tracking_type': 'time', 'equipment': 'other'},
      {'name': 'Grip Crushers', 'primary_muscle': 'forearms', 'secondary_muscles': '', 'tracking_type': 'reps_only', 'equipment': 'other'},

      // === QUADS (12) ===
      {'name': 'Barbell Back Squat', 'primary_muscle': 'quads', 'secondary_muscles': 'glutes,hamstrings', 'tracking_type': 'weight_reps', 'equipment': 'barbell'},
      {'name': 'Front Squat', 'primary_muscle': 'quads', 'secondary_muscles': 'glutes,abs', 'tracking_type': 'weight_reps', 'equipment': 'barbell'},
      {'name': 'Goblet Squat', 'primary_muscle': 'quads', 'secondary_muscles': 'glutes', 'tracking_type': 'weight_reps', 'equipment': 'dumbbell'},
      {'name': 'Leg Press', 'primary_muscle': 'quads', 'secondary_muscles': 'glutes,hamstrings', 'tracking_type': 'weight_reps', 'equipment': 'machine'},
      {'name': 'Hack Squat', 'primary_muscle': 'quads', 'secondary_muscles': 'glutes', 'tracking_type': 'weight_reps', 'equipment': 'machine'},
      {'name': 'Bulgarian Split Squat', 'primary_muscle': 'quads', 'secondary_muscles': 'glutes,hamstrings', 'tracking_type': 'weight_reps', 'equipment': 'dumbbell'},
      {'name': 'Lunges', 'primary_muscle': 'quads', 'secondary_muscles': 'glutes,hamstrings', 'tracking_type': 'weight_reps', 'equipment': 'dumbbell'},
      {'name': 'Walking Lunges', 'primary_muscle': 'quads', 'secondary_muscles': 'glutes,hamstrings', 'tracking_type': 'weight_reps', 'equipment': 'dumbbell'},
      {'name': 'Leg Extension', 'primary_muscle': 'quads', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'machine'},
      {'name': 'Sissy Squat', 'primary_muscle': 'quads', 'secondary_muscles': '', 'tracking_type': 'reps_only', 'equipment': 'bodyweight'},
      {'name': 'Step-ups', 'primary_muscle': 'quads', 'secondary_muscles': 'glutes', 'tracking_type': 'weight_reps', 'equipment': 'dumbbell'},
      {'name': 'Box Squat', 'primary_muscle': 'quads', 'secondary_muscles': 'glutes,hamstrings', 'tracking_type': 'weight_reps', 'equipment': 'barbell'},

      // === HAMSTRINGS (8) ===
      {'name': 'Romanian Deadlift', 'primary_muscle': 'hamstrings', 'secondary_muscles': 'glutes,lowerBack', 'tracking_type': 'weight_reps', 'equipment': 'barbell'},
      {'name': 'Stiff Leg Deadlift', 'primary_muscle': 'hamstrings', 'secondary_muscles': 'glutes,lowerBack', 'tracking_type': 'weight_reps', 'equipment': 'barbell'},
      {'name': 'Lying Leg Curl', 'primary_muscle': 'hamstrings', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'machine'},
      {'name': 'Seated Leg Curl', 'primary_muscle': 'hamstrings', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'machine'},
      {'name': 'Nordic Curl', 'primary_muscle': 'hamstrings', 'secondary_muscles': '', 'tracking_type': 'reps_only', 'equipment': 'bodyweight'},
      {'name': 'Glute Ham Raise', 'primary_muscle': 'hamstrings', 'secondary_muscles': 'glutes', 'tracking_type': 'reps_only', 'equipment': 'machine'},
      {'name': 'Single Leg Deadlift', 'primary_muscle': 'hamstrings', 'secondary_muscles': 'glutes,lowerBack', 'tracking_type': 'weight_reps', 'equipment': 'dumbbell'},
      {'name': 'Cable Pull Through', 'primary_muscle': 'hamstrings', 'secondary_muscles': 'glutes', 'tracking_type': 'weight_reps', 'equipment': 'cable'},

      // === GLUTES (8) ===
      {'name': 'Barbell Hip Thrust', 'primary_muscle': 'glutes', 'secondary_muscles': 'hamstrings', 'tracking_type': 'weight_reps', 'equipment': 'barbell'},
      {'name': 'Machine Hip Thrust', 'primary_muscle': 'glutes', 'secondary_muscles': 'hamstrings', 'tracking_type': 'weight_reps', 'equipment': 'machine'},
      {'name': 'Glute Bridge', 'primary_muscle': 'glutes', 'secondary_muscles': 'hamstrings', 'tracking_type': 'weight_reps', 'equipment': 'bodyweight'},
      {'name': 'Cable Kickback', 'primary_muscle': 'glutes', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'cable'},
      {'name': 'Donkey Kicks', 'primary_muscle': 'glutes', 'secondary_muscles': '', 'tracking_type': 'reps_only', 'equipment': 'bodyweight'},
      {'name': 'Sumo Deadlift', 'primary_muscle': 'glutes', 'secondary_muscles': 'quads,hamstrings,back', 'tracking_type': 'weight_reps', 'equipment': 'barbell'},
      {'name': 'Sumo Squat', 'primary_muscle': 'glutes', 'secondary_muscles': 'quads', 'tracking_type': 'weight_reps', 'equipment': 'dumbbell'},
      {'name': 'Frog Pumps', 'primary_muscle': 'glutes', 'secondary_muscles': '', 'tracking_type': 'reps_only', 'equipment': 'bodyweight'},

      // === CALVES (6) ===
      {'name': 'Standing Calf Raise', 'primary_muscle': 'calves', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'machine'},
      {'name': 'Seated Calf Raise', 'primary_muscle': 'calves', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'machine'},
      {'name': 'Leg Press Calf Raise', 'primary_muscle': 'calves', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'machine'},
      {'name': 'Donkey Calf Raise', 'primary_muscle': 'calves', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'machine'},
      {'name': 'Single Leg Calf Raise', 'primary_muscle': 'calves', 'secondary_muscles': '', 'tracking_type': 'reps_only', 'equipment': 'bodyweight'},
      {'name': 'Jump Rope', 'primary_muscle': 'calves', 'secondary_muscles': 'cardio', 'tracking_type': 'time', 'equipment': 'other'},

      // === ABS (12) ===
      {'name': 'Crunches', 'primary_muscle': 'abs', 'secondary_muscles': '', 'tracking_type': 'reps_only', 'equipment': 'bodyweight'},
      {'name': 'Hanging Leg Raise', 'primary_muscle': 'abs', 'secondary_muscles': 'obliques', 'tracking_type': 'reps_only', 'equipment': 'bodyweight'},
      {'name': 'Cable Crunch', 'primary_muscle': 'abs', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'cable'},
      {'name': 'Ab Wheel Rollout', 'primary_muscle': 'abs', 'secondary_muscles': '', 'tracking_type': 'reps_only', 'equipment': 'other'},
      {'name': 'Plank', 'primary_muscle': 'abs', 'secondary_muscles': '', 'tracking_type': 'time', 'equipment': 'bodyweight'},
      {'name': 'Side Plank', 'primary_muscle': 'obliques', 'secondary_muscles': 'abs', 'tracking_type': 'time', 'equipment': 'bodyweight'},
      {'name': 'Russian Twists', 'primary_muscle': 'obliques', 'secondary_muscles': 'abs', 'tracking_type': 'reps_only', 'equipment': 'bodyweight'},
      {'name': 'Bicycle Crunches', 'primary_muscle': 'abs', 'secondary_muscles': 'obliques', 'tracking_type': 'reps_only', 'equipment': 'bodyweight'},
      {'name': 'Mountain Climbers', 'primary_muscle': 'abs', 'secondary_muscles': 'cardio', 'tracking_type': 'time', 'equipment': 'bodyweight'},
      {'name': 'Dead Bug', 'primary_muscle': 'abs', 'secondary_muscles': '', 'tracking_type': 'reps_only', 'equipment': 'bodyweight'},
      {'name': 'Hollow Hold', 'primary_muscle': 'abs', 'secondary_muscles': '', 'tracking_type': 'time', 'equipment': 'bodyweight'},
      {'name': 'V-ups', 'primary_muscle': 'abs', 'secondary_muscles': '', 'tracking_type': 'reps_only', 'equipment': 'bodyweight'},

      // === LOWER BACK (5) ===
      {'name': 'Back Extensions', 'primary_muscle': 'lowerBack', 'secondary_muscles': 'glutes,hamstrings', 'tracking_type': 'weight_reps', 'equipment': 'machine'},
      {'name': 'Reverse Hypers', 'primary_muscle': 'lowerBack', 'secondary_muscles': 'glutes', 'tracking_type': 'weight_reps', 'equipment': 'machine'},
      {'name': 'Superman Hold', 'primary_muscle': 'lowerBack', 'secondary_muscles': '', 'tracking_type': 'time', 'equipment': 'bodyweight'},
      {'name': 'Bird Dog', 'primary_muscle': 'lowerBack', 'secondary_muscles': 'abs', 'tracking_type': 'reps_only', 'equipment': 'bodyweight'},
      {'name': 'Jefferson Curl', 'primary_muscle': 'lowerBack', 'secondary_muscles': 'hamstrings', 'tracking_type': 'weight_reps', 'equipment': 'dumbbell'},

      // === FULL BODY / COMPOUND (10) ===
      {'name': 'Clean and Jerk', 'primary_muscle': 'fullBody', 'secondary_muscles': 'shoulders,quads,back', 'tracking_type': 'weight_reps', 'equipment': 'barbell'},
      {'name': 'Snatch', 'primary_muscle': 'fullBody', 'secondary_muscles': 'shoulders,back,quads', 'tracking_type': 'weight_reps', 'equipment': 'barbell'},
      {'name': 'Power Clean', 'primary_muscle': 'fullBody', 'secondary_muscles': 'back,traps,quads', 'tracking_type': 'weight_reps', 'equipment': 'barbell'},
      {'name': 'Clean Pull', 'primary_muscle': 'fullBody', 'secondary_muscles': 'back,traps', 'tracking_type': 'weight_reps', 'equipment': 'barbell'},
      {'name': 'Thrusters', 'primary_muscle': 'fullBody', 'secondary_muscles': 'quads,shoulders', 'tracking_type': 'weight_reps', 'equipment': 'barbell'},
      {'name': 'Man Makers', 'primary_muscle': 'fullBody', 'secondary_muscles': '', 'tracking_type': 'reps_only', 'equipment': 'dumbbell'},
      {'name': 'Turkish Get-up', 'primary_muscle': 'fullBody', 'secondary_muscles': 'abs,shoulders', 'tracking_type': 'weight_reps', 'equipment': 'kettlebell'},
      {'name': 'Kettlebell Swing', 'primary_muscle': 'fullBody', 'secondary_muscles': 'glutes,hamstrings', 'tracking_type': 'weight_reps', 'equipment': 'kettlebell'},
      {'name': 'Battle Ropes', 'primary_muscle': 'fullBody', 'secondary_muscles': 'cardio', 'tracking_type': 'time', 'equipment': 'other'},
      {'name': 'Burpees', 'primary_muscle': 'fullBody', 'secondary_muscles': 'cardio', 'tracking_type': 'reps_only', 'equipment': 'bodyweight'},

      // === MACHINES (15) ===
      {'name': 'Smith Machine Squat', 'primary_muscle': 'quads', 'secondary_muscles': 'glutes', 'tracking_type': 'weight_reps', 'equipment': 'machine'},
      {'name': 'Smith Machine Bench Press', 'primary_muscle': 'chest', 'secondary_muscles': 'triceps', 'tracking_type': 'weight_reps', 'equipment': 'machine'},
      {'name': 'Cable Crossover', 'primary_muscle': 'chest', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'cable'},
      {'name': 'Assisted Pull-up Machine', 'primary_muscle': 'lats', 'secondary_muscles': 'biceps', 'tracking_type': 'weight_reps', 'equipment': 'machine'},
      {'name': 'Chest Supported Row Machine', 'primary_muscle': 'back', 'secondary_muscles': 'biceps', 'tracking_type': 'weight_reps', 'equipment': 'machine'},
      {'name': 'Hip Abductor Machine', 'primary_muscle': 'glutes', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'machine'},
      {'name': 'Hip Adductor Machine', 'primary_muscle': 'quads', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'machine'},
      {'name': 'Preacher Curl Machine', 'primary_muscle': 'biceps', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'machine'},
      {'name': 'Abdominal Crunch Machine', 'primary_muscle': 'abs', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'machine'},
      {'name': 'Rotary Torso Machine', 'primary_muscle': 'obliques', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'machine'},
      {'name': 'Glute Kickback Machine', 'primary_muscle': 'glutes', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'machine'},
      {'name': 'Calf Raise Machine', 'primary_muscle': 'calves', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'machine'},
      {'name': 'Low Row Machine', 'primary_muscle': 'back', 'secondary_muscles': 'biceps,lats', 'tracking_type': 'weight_reps', 'equipment': 'machine'},
      {'name': 'Chest Fly Machine', 'primary_muscle': 'chest', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'machine'},
      {'name': 'Vertical Leg Press', 'primary_muscle': 'quads', 'secondary_muscles': 'glutes', 'tracking_type': 'weight_reps', 'equipment': 'machine'},

      // === CARDIO (10) ===
      {'name': 'Treadmill Running', 'primary_muscle': 'cardio', 'secondary_muscles': 'quads,calves', 'tracking_type': 'time', 'equipment': 'machine'},
      {'name': 'Rowing Machine', 'primary_muscle': 'cardio', 'secondary_muscles': 'back,biceps', 'tracking_type': 'time', 'equipment': 'machine'},
      {'name': 'Assault Bike', 'primary_muscle': 'cardio', 'secondary_muscles': 'fullBody', 'tracking_type': 'time', 'equipment': 'machine'},
      {'name': 'Stair Climber', 'primary_muscle': 'cardio', 'secondary_muscles': 'quads,glutes', 'tracking_type': 'time', 'equipment': 'machine'},
      {'name': 'Elliptical', 'primary_muscle': 'cardio', 'secondary_muscles': '', 'tracking_type': 'time', 'equipment': 'machine'},
      {'name': 'Sled Push', 'primary_muscle': 'cardio', 'secondary_muscles': 'quads,glutes', 'tracking_type': 'weight_time', 'equipment': 'other'},
      {'name': 'Sled Pull', 'primary_muscle': 'cardio', 'secondary_muscles': 'back,hamstrings', 'tracking_type': 'weight_time', 'equipment': 'other'},
      {'name': 'Box Jumps', 'primary_muscle': 'cardio', 'secondary_muscles': 'quads,calves', 'tracking_type': 'reps_only', 'equipment': 'other'},
      {'name': 'Sprints', 'primary_muscle': 'cardio', 'secondary_muscles': 'quads,hamstrings', 'tracking_type': 'time', 'equipment': 'bodyweight'},
      {'name': 'Incline Treadmill Walk', 'primary_muscle': 'cardio', 'secondary_muscles': 'glutes,calves', 'tracking_type': 'time', 'equipment': 'machine'},
    ];

    final batch = db.batch();
    for (final exercise in exercises) {
      batch.insert(
        'exercises',
        {...exercise, 'is_custom': 0},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);

    // Mark as seeded
    await db.insert(
      'app_meta',
      {'key': 'exercises_seeded', 'value': 'true'},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
```

---

## Implementation Phases

### Phase 1: Core MVP
- [ ] Flutter project setup
- [ ] SQLite database + schema
- [ ] Seed 150+ exercises
- [ ] Exercise library (list, search, filter by muscle)
- [ ] Basic workout logging (weight × reps)
- [ ] Workout history
- [ ] User profile (weight, height, age, units)
- [ ] Navigation (bottom tabs)

### Phase 2: Enhanced Logging
- [ ] Rest timer with notifications
- [ ] Show previous workout numbers
- [ ] Warmup set toggle
- [ ] RPE input (optional)
- [ ] Superset grouping
- [ ] Custom exercise creation
- [ ] Quick numpad input

### Phase 3: Progress & Analytics
- [ ] Per-exercise progress charts (fl_chart)
- [ ] Estimated 1RM tracking
- [ ] Volume graphs
- [ ] PR detection + celebration
- [ ] Workout calendar heatmap
- [ ] Muscle group volume breakdown

### Phase 4: Goals & Polish
- [ ] Exercise targets/goals
- [ ] Progress toward goals
- [ ] Bodyweight tracking graph
- [ ] Data export (JSON)
- [ ] Haptic feedback
- [ ] App icon + splash screen

---

## Deploying to iPhone from Ubuntu

### First Time Setup

1. **Connect iPhone via USB**
2. **Trust computer** on iPhone
3. **Enable Developer Mode** on iPhone:
   - Settings → Privacy & Security → Developer Mode → ON
   - Restart iPhone when prompted

4. **Run app:**
```bash
flutter run
```

5. **First build will ask for signing:**
   - Enter your Apple ID when prompted
   - Flutter creates a free development certificate
   - App will install on your iPhone

### Subsequent Runs

```bash
# Hot reload while developing
flutter run

# Or just rebuild
flutter run --release  # Faster app, no debug
```

### App Stays on Phone

Once installed, the app stays on your iPhone and works fully offline. You can unplug and use it at the gym immediately.

**Note:** Free Apple ID certificates expire after 7 days. Just re-run `flutter run` to reinstall. When you're ready for App Store (permanent install), you'll need the $99/year developer account.

---

## Building for App Store (When Ready)

### Prerequisites
- Mac with Xcode (required by Apple)
- Apple Developer Account ($99/year)

### Steps
1. Open project in Xcode on Mac
2. Set up signing with your paid dev account
3. Archive and upload to App Store Connect
4. Fill metadata, screenshots
5. Submit for review

---

## Notes for Claude Code

- Test on Android emulator first if iPhone not connected
- Use `const` constructors wherever possible
- Prefer `StatelessWidget` + Riverpod over `StatefulWidget`
- Use `FutureProvider` for async data loading
- All database calls should be in repositories
- Keep widgets small and composable
- Dark mode only - no theme switching needed

**Philosophy:** Launch in under 1 second. Log a set in 3 taps. No internet required. Ever.

---

*No ads. No subscriptions. No bullshit. Just gains. 🏋️*
