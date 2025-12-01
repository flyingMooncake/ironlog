import 'package:sqflite/sqflite.dart';
import '../core/database/database_helper.dart';
import '../models/personal_record.dart';

class PersonalRecordRepository {
  Future<Database> get _db async => await DatabaseHelper.instance.database;

  // Get all PRs for an exercise
  Future<List<PersonalRecord>> getPRsForExercise(int exerciseId) async {
    final db = await _db;
    final results = await db.rawQuery('''
      SELECT pr.*, e.name as exercise_name
      FROM personal_records pr
      JOIN exercises e ON pr.exercise_id = e.id
      WHERE pr.exercise_id = ?
      ORDER BY pr.achieved_at DESC
    ''', [exerciseId]);

    return results.map((map) => PersonalRecord.fromMap(map)).toList();
  }

  // Get the latest PR for a specific record type
  Future<PersonalRecord?> getLatestPR(int exerciseId, String recordType) async {
    final db = await _db;
    final results = await db.rawQuery('''
      SELECT pr.*, e.name as exercise_name
      FROM personal_records pr
      JOIN exercises e ON pr.exercise_id = e.id
      WHERE pr.exercise_id = ? AND pr.record_type = ?
      ORDER BY pr.value DESC, pr.achieved_at DESC
      LIMIT 1
    ''', [exerciseId, recordType]);

    if (results.isEmpty) return null;
    return PersonalRecord.fromMap(results.first);
  }

  // Get all PRs across all exercises
  Future<List<PersonalRecord>> getAllPRs() async {
    final db = await _db;
    final results = await db.rawQuery('''
      SELECT pr.*, e.name as exercise_name
      FROM personal_records pr
      JOIN exercises e ON pr.exercise_id = e.id
      ORDER BY pr.achieved_at DESC
      LIMIT 50
    ''');

    return results.map((map) => PersonalRecord.fromMap(map)).toList();
  }

  // Check and update PRs after completing a set
  Future<List<PersonalRecord>> checkAndUpdatePRs(
    int exerciseId,
    double weight,
    int reps,
    int setId,
  ) async {
    final db = await _db;
    final newPRs = <PersonalRecord>[];

    // Get exercise name
    final exerciseResult = await db.query(
      'exercises',
      where: 'id = ?',
      whereArgs: [exerciseId],
      limit: 1,
    );
    final exerciseName = exerciseResult.isNotEmpty
        ? exerciseResult.first['name'] as String
        : 'Unknown Exercise';

    // Calculate estimated 1RM
    final estimated1RM = PersonalRecord.calculate1RM(weight, reps);

    // Check max weight PR
    final maxWeightPR = await getLatestPR(exerciseId, 'max_weight');
    if (maxWeightPR == null || weight > maxWeightPR.value) {
      final pr = PersonalRecord(
        exerciseId: exerciseId,
        exerciseName: exerciseName,
        recordType: 'max_weight',
        value: weight,
        weight: weight,
        reps: reps,
        setId: setId,
      );
      await createPR(pr);
      newPRs.add(pr);
    }

    // Check estimated 1RM PR
    final max1RMPR = await getLatestPR(exerciseId, '1rm');
    if (max1RMPR == null || estimated1RM > max1RMPR.value) {
      final pr = PersonalRecord(
        exerciseId: exerciseId,
        exerciseName: exerciseName,
        recordType: '1rm',
        value: estimated1RM,
        weight: weight,
        reps: reps,
        setId: setId,
      );
      await createPR(pr);
      newPRs.add(pr);
    }

    // Check max reps at a specific weight (only if same weight or higher)
    final maxRepsPR = await getLatestPR(exerciseId, 'max_reps');
    if (maxRepsPR == null || reps > maxRepsPR.reps!) {
      final pr = PersonalRecord(
        exerciseId: exerciseId,
        exerciseName: exerciseName,
        recordType: 'max_reps',
        value: reps.toDouble(),
        weight: weight,
        reps: reps,
        setId: setId,
      );
      await createPR(pr);
      newPRs.add(pr);
    }

    // Check max volume (weight * reps)
    final volume = weight * reps;
    final maxVolumePR = await getLatestPR(exerciseId, 'max_volume');
    if (maxVolumePR == null || volume > maxVolumePR.value) {
      final pr = PersonalRecord(
        exerciseId: exerciseId,
        exerciseName: exerciseName,
        recordType: 'max_volume',
        value: volume,
        weight: weight,
        reps: reps,
        setId: setId,
      );
      await createPR(pr);
      newPRs.add(pr);
    }

    return newPRs;
  }

  // Create a new PR
  Future<int> createPR(PersonalRecord pr) async {
    final db = await _db;
    return await db.insert('personal_records', pr.toMap());
  }

  // Get PR summary for all exercises
  Future<Map<int, Map<String, PersonalRecord>>> getPRSummary() async {
    final db = await _db;
    final results = await db.rawQuery('''
      SELECT pr.*, e.name as exercise_name
      FROM personal_records pr
      JOIN exercises e ON pr.exercise_id = e.id
      WHERE pr.id IN (
        SELECT pr2.id
        FROM personal_records pr2
        WHERE pr2.exercise_id = pr.exercise_id
        AND pr2.record_type = pr.record_type
        ORDER BY pr2.value DESC, pr2.achieved_at DESC
        LIMIT 1
      )
      ORDER BY pr.achieved_at DESC
    ''');

    final Map<int, Map<String, PersonalRecord>> summary = {};
    for (final row in results) {
      final pr = PersonalRecord.fromMap(row);
      if (!summary.containsKey(pr.exerciseId)) {
        summary[pr.exerciseId] = {};
      }
      summary[pr.exerciseId]![pr.recordType] = pr;
    }

    return summary;
  }

  // Delete all PRs for an exercise
  Future<void> deletePRsForExercise(int exerciseId) async {
    final db = await _db;
    await db.delete(
      'personal_records',
      where: 'exercise_id = ?',
      whereArgs: [exerciseId],
    );
  }
}
