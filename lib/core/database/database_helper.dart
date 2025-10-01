import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import 'database_contract.dart';

/// Database Helper - مدير قاعدة البيانات
/// يوفر واجهة موحدة للتعامل مع SQLite
class DatabaseHelper {
  static DatabaseHelper? _instance;
  static Database? _database;

  DatabaseHelper._internal();

  /// Singleton instance
  static DatabaseHelper get instance {
    _instance ??= DatabaseHelper._internal();
    return _instance!;
  }

  /// الحصول على قاعدة البيانات
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// تهيئة قاعدة البيانات
  Future<Database> _initDatabase() async {
    try {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, kDatabaseName);

      debugPrint('📂 Database path: $path');

      return await openDatabase(
        path,
        version: kDatabaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onConfigure: _onConfigure,
      );
    } catch (e) {
      debugPrint('❌ Error initializing database: $e');
      rethrow;
    }
  }

  /// تكوين قاعدة البيانات (تفعيل Foreign Keys)
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
    debugPrint('✅ Foreign keys enabled');
  }

  /// إنشاء الجداول عند إنشاء قاعدة البيانات لأول مرة
  Future<void> _onCreate(Database db, int version) async {
    debugPrint('📊 Creating database tables...');

    try {
      // إنشاء جدول البيانات الوصفية
      await db.execute(MetaTable.createTable);
      debugPrint('✅ Meta table created');

      // إنشاء جدول الصفحات
      await db.execute(PagesTable.createTable);
      await db.execute(PagesTable.indexUpdatedAt);
      debugPrint('✅ Pages table created');

      // إنشاء جدول المجلدات
      await db.execute(FoldersTable.createTable);
      await db.execute(FoldersTable.indexPageId);
      await db.execute(FoldersTable.indexUpdatedAt);
      debugPrint('✅ Folders table created');

      // إنشاء جدول الملاحظات
      await db.execute(NotesTable.createTable);
      await db.execute(NotesTable.indexPageId);
      await db.execute(NotesTable.indexFolderId);
      await db.execute(NotesTable.indexCreatedAt);
      await db.execute(NotesTable.indexDeleted);
      debugPrint('✅ Notes table created');

      // إنشاء جدول المرفقات
      await db.execute(AttachmentsTable.createTable);
      await db.execute(AttachmentsTable.indexNoteId);
      await db.execute(AttachmentsTable.indexCreatedAt);
      debugPrint('✅ Attachments table created');

      // إنشاء جدول النسخ الاحتياطية
      await db.execute(BackupsTable.createTable);
      await db.execute(BackupsTable.indexCreatedAt);
      debugPrint('✅ Backups table created');

      // تهيئة البيانات الوصفية
      await _initializeMetadata(db);

      debugPrint('✅ Database created successfully');
    } catch (e) {
      debugPrint('❌ Error creating database: $e');
      rethrow;
    }
  }

  /// ترقية قاعدة البيانات عند تحديث الإصدار
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('🔄 Upgrading database from v$oldVersion to v$newVersion');

    // سيتم إضافة منطق الترقية هنا في المستقبل
    // مثال:
    // if (oldVersion < 2) {
    //   await db.execute('ALTER TABLE notes ADD COLUMN new_field TEXT');
    // }
  }

  /// تهيئة البيانات الوصفية
  Future<void> _initializeMetadata(Database db) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.insert(MetaTable.tableName, {
      MetaTable.columnKey: MetaTable.keyDataVersion,
      MetaTable.columnValue: kDatabaseVersion.toString(),
      MetaTable.columnUpdatedAt: now,
    });

    await db.insert(MetaTable.tableName, {
      MetaTable.columnKey: MetaTable.keyMigrationStatus,
      MetaTable.columnValue: MigrationStatus.notStarted,
      MetaTable.columnUpdatedAt: now,
    });

    debugPrint('✅ Metadata initialized');
  }

  /// الحصول على قيمة من جدول البيانات الوصفية
  Future<String?> getMetadata(String key) async {
    try {
      final db = await database;
      final results = await db.query(
        MetaTable.tableName,
        where: '${MetaTable.columnKey} = ?',
        whereArgs: [key],
      );

      if (results.isEmpty) return null;
      return results.first[MetaTable.columnValue] as String?;
    } catch (e) {
      debugPrint('❌ Error getting metadata: $e');
      return null;
    }
  }

  /// تحديث قيمة في جدول البيانات الوصفية
  Future<bool> setMetadata(String key, String value) async {
    try {
      final db = await database;
      final now = DateTime.now().millisecondsSinceEpoch;

      final count = await db.update(
        MetaTable.tableName,
        {
          MetaTable.columnValue: value,
          MetaTable.columnUpdatedAt: now,
        },
        where: '${MetaTable.columnKey} = ?',
        whereArgs: [key],
      );

      if (count == 0) {
        await db.insert(MetaTable.tableName, {
          MetaTable.columnKey: key,
          MetaTable.columnValue: value,
          MetaTable.columnUpdatedAt: now,
        });
      }

      return true;
    } catch (e) {
      debugPrint('❌ Error setting metadata: $e');
      return false;
    }
  }

  /// التحقق من سلامة قاعدة البيانات
  Future<bool> validateDatabaseIntegrity() async {
    try {
      final db = await database;
      final result = await db.rawQuery('PRAGMA integrity_check');
      
      if (result.isEmpty) return false;
      
      final status = result.first.values.first;
      final isValid = status == 'ok';
      
      debugPrint(isValid ? '✅ Database integrity: OK' : '❌ Database integrity: FAILED');
      return isValid;
    } catch (e) {
      debugPrint('❌ Error validating database integrity: $e');
      return false;
    }
  }

  /// الحصول على إحصائيات قاعدة البيانات
  Future<Map<String, int>> getDatabaseStats() async {
    try {
      final db = await database;
      
      final pagesCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM ${PagesTable.tableName}'),
      ) ?? 0;
      
      final foldersCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM ${FoldersTable.tableName}'),
      ) ?? 0;
      
      final notesCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM ${NotesTable.tableName} WHERE ${NotesTable.columnIsDeleted} = 0'),
      ) ?? 0;
      
      final attachmentsCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM ${AttachmentsTable.tableName}'),
      ) ?? 0;

      return {
        'pages': pagesCount,
        'folders': foldersCount,
        'notes': notesCount,
        'attachments': attachmentsCount,
      };
    } catch (e) {
      debugPrint('❌ Error getting database stats: $e');
      return {};
    }
  }

  /// حذف قاعدة البيانات (للتطوير فقط)
  Future<void> deleteDatabase() async {
    try {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, kDatabaseName);
      
      if (_database != null) {
        await _database!.close();
        _database = null;
      }
      
      await databaseFactory.deleteDatabase(path);
      debugPrint('🗑️ Database deleted');
    } catch (e) {
      debugPrint('❌ Error deleting database: $e');
      rethrow;
    }
  }

  /// إغلاق قاعدة البيانات
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      debugPrint('🔒 Database closed');
    }
  }
}
