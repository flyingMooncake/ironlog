import '../core/database/database_helper.dart';
import '../models/progress_photo.dart';

class ProgressPhotoRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> createPhoto(ProgressPhoto photo) async {
    final db = await _dbHelper.database;
    return await db.insert('progress_photos', photo.toMap());
  }

  Future<List<ProgressPhoto>> getAllPhotos() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'progress_photos',
      orderBy: 'taken_at DESC',
    );
    return maps.map((map) => ProgressPhoto.fromMap(map)).toList();
  }

  Future<List<ProgressPhoto>> getPhotosByDateRange(DateTime start, DateTime end) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'progress_photos',
      where: 'taken_at BETWEEN ? AND ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'taken_at DESC',
    );
    return maps.map((map) => ProgressPhoto.fromMap(map)).toList();
  }

  Future<List<ProgressPhoto>> getPhotosByType(PhotoType type) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'progress_photos',
      where: 'photo_type = ?',
      whereArgs: [type.name],
      orderBy: 'taken_at DESC',
    );
    return maps.map((map) => ProgressPhoto.fromMap(map)).toList();
  }

  Future<ProgressPhoto?> getPhotoById(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'progress_photos',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return ProgressPhoto.fromMap(maps.first);
  }

  Future<int> updatePhoto(ProgressPhoto photo) async {
    final db = await _dbHelper.database;
    return await db.update(
      'progress_photos',
      photo.toMap(),
      where: 'id = ?',
      whereArgs: [photo.id],
    );
  }

  Future<int> deletePhoto(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'progress_photos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getPhotoCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM progress_photos');
    return result.first['count'] as int;
  }
}
