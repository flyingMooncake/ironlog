import 'package:sqflite/sqflite.dart';
import '../core/database/database_helper.dart';
import '../models/user_profile.dart';

class UserRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Get user profile (there should only be one)
  Future<UserProfile?> getUserProfile() async {
    final db = await _dbHelper.database;
    final result = await db.query('user_profile', limit: 1);

    if (result.isEmpty) return null;
    return UserProfile.fromMap(result.first);
  }

  // Create or update user profile
  Future<int> saveUserProfile(UserProfile profile) async {
    final db = await _dbHelper.database;

    // Check if profile exists
    final existing = await getUserProfile();

    if (existing == null) {
      // Create new profile
      return await db.insert(
        'user_profile',
        profile.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } else {
      // Update existing profile
      return await db.update(
        'user_profile',
        profile.toMap(),
        where: 'id = ?',
        whereArgs: [existing.id],
      );
    }
  }

  // Get or create default profile
  Future<UserProfile> getOrCreateProfile() async {
    final profile = await getUserProfile();

    if (profile != null) return profile;

    // Create default profile
    final defaultProfile = UserProfile(
      unitSystem: UnitSystem.metric,
      restTimerDefault: 90,
    );

    await saveUserProfile(defaultProfile);
    return defaultProfile;
  }

  // Update specific fields
  Future<int> updateUnitSystem(UnitSystem unitSystem) async {
    final profile = await getOrCreateProfile();
    final updated = UserProfile(
      id: profile.id,
      weight: profile.weight,
      height: profile.height,
      age: profile.age,
      unitSystem: unitSystem,
      restTimerDefault: profile.restTimerDefault,
    );
    return await saveUserProfile(updated);
  }

  Future<int> updateRestTimer(int seconds) async {
    final profile = await getOrCreateProfile();
    final updated = UserProfile(
      id: profile.id,
      weight: profile.weight,
      height: profile.height,
      age: profile.age,
      unitSystem: profile.unitSystem,
      restTimerDefault: seconds,
    );
    return await saveUserProfile(updated);
  }
}
