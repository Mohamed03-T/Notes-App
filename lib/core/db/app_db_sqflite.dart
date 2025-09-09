import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDbSqflite {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'notes_app.db');
    _db = await openDatabase(path, version: 1, onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE notes (
          id TEXT PRIMARY KEY,
          content TEXT,
          type TEXT,
          createdAt INTEGER
        )
      ''');
    });
    return _db!;
  }

  static Future<void> insertNote(Map<String, dynamic> note) async {
    final db = await database;
    await db.insert('notes', note);
  }

  static Future<List<Map<String, dynamic>>> getNotes() async {
    final db = await database;
    return db.query('notes', orderBy: 'createdAt DESC');
  }
}
