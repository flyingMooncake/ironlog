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
    await db.execute(Schema.createTemplateGroups);
    await db.execute(Schema.createWorkoutTemplates);
    await db.execute(Schema.createTemplateExercises);
    await db.execute(Schema.createBodyMeasurements);
    await db.execute(Schema.createProgressPhotos);
    await db.execute(Schema.createScheduledWorkouts);
    await db.execute(Schema.createRestDays);

    // Create indexes
    await db.execute(Schema.indexSetsSession);
    await db.execute(Schema.indexSetsExercise);
    await db.execute(Schema.indexSessionsDate);
    await db.execute(Schema.indexExercisesMuscle);
    await db.execute(Schema.indexSetsCompletedAt);
    await db.execute(Schema.indexSetsWarmup);
    await db.execute(Schema.indexSetsExerciseDate);
    await db.execute(Schema.indexProgressPhotosTakenAt);
    await db.execute(Schema.indexScheduledWorkoutsDate);
    await db.execute(Schema.indexRestDaysDate);

    // Seed exercises
    await SeedData.seedExercises(db);
  }

  Future<void> _onOpen(Database db) async {
    // Migrations for existing databases - add missing columns
    try {
      await db.execute('ALTER TABLE user_profile ADD COLUMN auto_start_rest_timer INTEGER DEFAULT 1');
    } catch (e) {
      // Column already exists
    }

    try {
      await db.execute('ALTER TABLE user_profile ADD COLUMN bfp_percentage REAL');
    } catch (e) {
      // Column already exists
    }

    try {
      await db.execute('ALTER TABLE workout_sets ADD COLUMN is_drop_set INTEGER DEFAULT 0');
    } catch (e) {
      // Column already exists
    }

    // Create new tables for existing databases (must be done before indexes)
    try {
      await db.execute(Schema.createTemplateGroups);
    } catch (e) {
      // Table already exists
    }

    try {
      await db.execute(Schema.createProgressPhotos);
    } catch (e) {
      // Table already exists
    }

    try {
      await db.execute(Schema.createScheduledWorkouts);
    } catch (e) {
      // Table already exists
    }

    try {
      await db.execute(Schema.createRestDays);
    } catch (e) {
      // Table already exists
    }

    // Add new columns to workout_templates for grouping
    try {
      await db.execute('ALTER TABLE workout_templates ADD COLUMN group_id INTEGER');
    } catch (e) {
      // Column already exists
    }

    try {
      await db.execute('ALTER TABLE workout_templates ADD COLUMN order_in_group INTEGER DEFAULT 0');
    } catch (e) {
      // Column already exists
    }

    // Add template_id to workout_sessions
    try {
      await db.execute('ALTER TABLE workout_sessions ADD COLUMN template_id INTEGER');
    } catch (e) {
      // Column already exists
    }

    // Create indexes if they don't exist (for existing databases)
    // Must be done AFTER tables are created
    try {
      await db.execute(Schema.indexSetsSession);
      await db.execute(Schema.indexSetsExercise);
      await db.execute(Schema.indexSessionsDate);
      await db.execute(Schema.indexExercisesMuscle);
      await db.execute(Schema.indexSetsCompletedAt);
      await db.execute(Schema.indexSetsWarmup);
      await db.execute(Schema.indexSetsExerciseDate);
      await db.execute(Schema.indexProgressPhotosTakenAt);
      await db.execute(Schema.indexScheduledWorkoutsDate);
      await db.execute(Schema.indexRestDaysDate);
    } catch (e) {
      // Indexes might already exist or fail, ignore
    }

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
