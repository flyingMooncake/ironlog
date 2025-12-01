import 'package:sqflite/sqflite.dart';
import '../core/database/database_helper.dart';
import '../models/body_measurement.dart';

class BodyMeasurementRepository {
  Future<Database> get _db async => await DatabaseHelper.instance.database;

  // Save a new body measurement
  Future<int> saveMeasurement(BodyMeasurement measurement) async {
    final db = await _db;
    return await db.insert(
      'body_measurements',
      measurement.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get all measurements ordered by date (newest first)
  Future<List<BodyMeasurement>> getAllMeasurements() async {
    final db = await _db;
    final results = await db.query(
      'body_measurements',
      orderBy: 'recorded_at DESC',
    );

    return results.map((map) => BodyMeasurement.fromMap(map)).toList();
  }

  // Get latest measurement
  Future<BodyMeasurement?> getLatestMeasurement() async {
    final db = await _db;
    final results = await db.query(
      'body_measurements',
      orderBy: 'recorded_at DESC',
      limit: 1,
    );

    if (results.isEmpty) return null;
    return BodyMeasurement.fromMap(results.first);
  }

  // Get measurements within a date range
  Future<List<BodyMeasurement>> getMeasurementsInRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await _db;
    final results = await db.query(
      'body_measurements',
      where: 'recorded_at BETWEEN ? AND ?',
      whereArgs: [
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ],
      orderBy: 'recorded_at DESC',
    );

    return results.map((map) => BodyMeasurement.fromMap(map)).toList();
  }

  // Delete a measurement
  Future<int> deleteMeasurement(int id) async {
    final db = await _db;
    return await db.delete(
      'body_measurements',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Update a measurement
  Future<int> updateMeasurement(BodyMeasurement measurement) async {
    final db = await _db;
    return await db.update(
      'body_measurements',
      measurement.toMap(),
      where: 'id = ?',
      whereArgs: [measurement.id],
    );
  }
}
