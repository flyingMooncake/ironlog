import '../core/database/database_helper.dart';
import '../models/template_group.dart';

class TemplateGroupRepository {
  final _db = DatabaseHelper.instance;

  Future<List<TemplateGroup>> getAllGroups() async {
    final db = await _db.database;
    final result = await db.query(
      'template_groups',
      orderBy: 'order_index ASC',
    );
    return result.map((map) => TemplateGroup.fromMap(map)).toList();
  }

  Future<TemplateGroup?> getGroupById(int id) async {
    final db = await _db.database;
    final result = await db.query(
      'template_groups',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    return TemplateGroup.fromMap(result.first);
  }

  Future<int> createGroup(TemplateGroup group) async {
    final db = await _db.database;
    return await db.insert('template_groups', group.toMap());
  }

  Future<void> updateGroup(TemplateGroup group) async {
    final db = await _db.database;
    await db.update(
      'template_groups',
      group.toMap(),
      where: 'id = ?',
      whereArgs: [group.id],
    );
  }

  Future<void> deleteGroup(int id) async {
    final db = await _db.database;
    // Remove group_id from templates in this group
    await db.update(
      'workout_templates',
      {'group_id': null},
      where: 'group_id = ?',
      whereArgs: [id],
    );
    // Delete the group
    await db.delete(
      'template_groups',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> reorderGroups(List<TemplateGroup> groups) async {
    final db = await _db.database;
    final batch = db.batch();
    for (int i = 0; i < groups.length; i++) {
      batch.update(
        'template_groups',
        {'order_index': i},
        where: 'id = ?',
        whereArgs: [groups[i].id],
      );
    }
    await batch.commit(noResult: true);
  }
}
