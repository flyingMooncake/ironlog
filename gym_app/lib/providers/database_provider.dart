import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../core/database/database_helper.dart';

final databaseProvider = FutureProvider<Database>((ref) async {
  return await DatabaseHelper.instance.database;
});
