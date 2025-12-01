class Schema {
  static const String createUserProfile = '''
    CREATE TABLE IF NOT EXISTS user_profile (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      weight REAL,
      height REAL,
      age INTEGER,
      unit_system TEXT DEFAULT 'metric',
      rest_timer_default INTEGER DEFAULT 90,
      auto_start_rest_timer INTEGER DEFAULT 1,
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
      is_drop_set INTEGER DEFAULT 0,
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

  static const String createTemplateGroups = '''
    CREATE TABLE IF NOT EXISTS template_groups (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      order_index INTEGER NOT NULL DEFAULT 0,
      created_at TEXT DEFAULT (datetime('now'))
    )
  ''';

  static const String createWorkoutTemplates = '''
    CREATE TABLE IF NOT EXISTS workout_templates (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      description TEXT,
      group_id INTEGER,
      order_in_group INTEGER DEFAULT 0,
      created_at TEXT DEFAULT (datetime('now')),
      last_used TEXT,
      FOREIGN KEY (group_id) REFERENCES template_groups(id) ON DELETE SET NULL
    )
  ''';

  static const String createTemplateExercises = '''
    CREATE TABLE IF NOT EXISTS template_exercises (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      template_id INTEGER NOT NULL,
      exercise_id INTEGER NOT NULL,
      order_index INTEGER NOT NULL,
      sets INTEGER NOT NULL DEFAULT 3,
      target_reps INTEGER,
      target_weight REAL,
      rest_seconds INTEGER,
      notes TEXT,
      FOREIGN KEY (template_id) REFERENCES workout_templates(id) ON DELETE CASCADE,
      FOREIGN KEY (exercise_id) REFERENCES exercises(id)
    )
  ''';

  static const String createBodyMeasurements = '''
    CREATE TABLE IF NOT EXISTS body_measurements (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      chest REAL,
      waist REAL,
      hips REAL,
      left_arm REAL,
      right_arm REAL,
      left_thigh REAL,
      right_thigh REAL,
      left_calf REAL,
      right_calf REAL,
      shoulders REAL,
      neck REAL,
      notes TEXT,
      recorded_at TEXT DEFAULT (datetime('now'))
    )
  ''';

  static const String createProgressPhotos = '''
    CREATE TABLE IF NOT EXISTS progress_photos (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      file_path TEXT NOT NULL,
      weight REAL,
      notes TEXT,
      photo_type TEXT DEFAULT 'front',
      taken_at TEXT DEFAULT (datetime('now'))
    )
  ''';

  static const String createScheduledWorkouts = '''
    CREATE TABLE IF NOT EXISTS scheduled_workouts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      template_id INTEGER,
      scheduled_date TEXT NOT NULL,
      completed INTEGER DEFAULT 0,
      completed_session_id INTEGER,
      notes TEXT,
      created_at TEXT DEFAULT (datetime('now')),
      FOREIGN KEY (template_id) REFERENCES workout_templates(id) ON DELETE SET NULL,
      FOREIGN KEY (completed_session_id) REFERENCES workout_sessions(id) ON DELETE SET NULL
    )
  ''';

  static const String createRestDays = '''
    CREATE TABLE IF NOT EXISTS rest_days (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      rest_date TEXT NOT NULL UNIQUE,
      is_planned INTEGER DEFAULT 1,
      notes TEXT,
      created_at TEXT DEFAULT (datetime('now'))
    )
  ''';

  // Indexes for better query performance
  static const String indexSetsSession =
      'CREATE INDEX IF NOT EXISTS idx_sets_session ON workout_sets(session_id)';
  static const String indexSetsExercise =
      'CREATE INDEX IF NOT EXISTS idx_sets_exercise ON workout_sets(exercise_id)';
  static const String indexSessionsDate =
      'CREATE INDEX IF NOT EXISTS idx_sessions_date ON workout_sessions(started_at)';
  static const String indexExercisesMuscle =
      'CREATE INDEX IF NOT EXISTS idx_exercises_muscle ON exercises(primary_muscle)';
  static const String indexSetsCompletedAt =
      'CREATE INDEX IF NOT EXISTS idx_sets_completed_at ON workout_sets(completed_at)';
  static const String indexSetsWarmup =
      'CREATE INDEX IF NOT EXISTS idx_sets_warmup ON workout_sets(is_warmup)';
  static const String indexSetsExerciseDate =
      'CREATE INDEX IF NOT EXISTS idx_sets_exercise_date ON workout_sets(exercise_id, completed_at)';
  static const String indexProgressPhotosTakenAt =
      'CREATE INDEX IF NOT EXISTS idx_progress_photos_taken_at ON progress_photos(taken_at)';
  static const String indexScheduledWorkoutsDate =
      'CREATE INDEX IF NOT EXISTS idx_scheduled_workouts_date ON scheduled_workouts(scheduled_date)';
  static const String indexRestDaysDate =
      'CREATE INDEX IF NOT EXISTS idx_rest_days_date ON rest_days(rest_date)';
}
