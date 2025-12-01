import 'package:sqflite/sqflite.dart';
import '../core/database/database_helper.dart';
import '../models/weight_entry.dart';

class WeightHistoryRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Create a new weight entry
  Future<int> createWeightEntry(WeightEntry entry) async {
    final db = await _dbHelper.database;
    return await db.insert(
      'weight_history',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get all weight entries
  Future<List<WeightEntry>> getAllWeightEntries() async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'weight_history',
      orderBy: 'recorded_at DESC',
    );
    return result.map((map) => WeightEntry.fromMap(map)).toList();
  }

  // Get weight entries within a date range
  Future<List<WeightEntry>> getWeightEntriesInRange(DateTime start, DateTime end) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'weight_history',
      where: 'recorded_at BETWEEN ? AND ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'recorded_at ASC',
    );
    return result.map((map) => WeightEntry.fromMap(map)).toList();
  }

  // Get latest weight entry
  Future<WeightEntry?> getLatestWeightEntry() async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'weight_history',
      orderBy: 'recorded_at DESC',
      limit: 1,
    );
    if (result.isEmpty) return null;
    return WeightEntry.fromMap(result.first);
  }

  // Update weight entry
  Future<int> updateWeightEntry(WeightEntry entry) async {
    final db = await _dbHelper.database;
    return await db.update(
      'weight_history',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  // Delete weight entry
  Future<int> deleteWeightEntry(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'weight_history',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get weight change over time period
  Future<Map<String, double>> getWeightChange(int days) async {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days));

    final entries = await getWeightEntriesInRange(startDate, now);
    if (entries.length < 2) {
      return {'change': 0, 'percentage': 0};
    }

    final oldestWeight = entries.first.weight;
    final latestWeight = entries.last.weight;
    final change = latestWeight - oldestWeight;
    final percentage = (change / oldestWeight) * 100;

    return {
      'change': change,
      'percentage': percentage,
    };
  }
}
