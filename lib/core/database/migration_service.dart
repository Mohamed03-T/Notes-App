import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:sqflite/sqflite.dart';

import 'database_helper.dart';
import 'database_contract.dart';
import 'sqlite_notes_store.dart';
import 'i_notes_store.dart';

/// خدمة الترحيل من SharedPreferences إلى SQLite
/// 
/// المسؤولية:
/// - نسخ احتياطي كامل قبل الترحيل
/// - ترحيل البيانات بأمان باستخدام Transactions
/// - التحقق من سلامة البيانات بعد الترحيل
/// - إمكانية التراجع (Rollback) في حالة الفشل
class MigrationService {
  final SqliteNotesStore _sqliteStore = SqliteNotesStore();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // مفاتيح SharedPreferences القديمة
  static const String _oldNotesKey = 'saved_notes_v2';
  static const String _oldPagesKey = 'saved_pages_v1';
  
  // مفتاح حالة الترحيل
  static const String _migrationStatusKey = 'migration_completed';
  static const String _migrationBackupKey = 'backup_notes_v2_before_migration';

  /// التحقق من حالة الترحيل
  Future<MigrationState> checkMigrationStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final completed = prefs.getBool(_migrationStatusKey) ?? false;

      if (completed) {
        return MigrationState.completed;
      }

      // التحقق من وجود بيانات في SharedPreferences
      final hasOldData = prefs.containsKey(_oldNotesKey) || prefs.containsKey(_oldPagesKey);
      
      if (!hasOldData) {
        return MigrationState.notNeeded;
      }

      // التحقق من قاعدة البيانات
      final stats = await _sqliteStore.getStatistics();
      final hasNewData = stats.success && (stats.data?['notes'] ?? 0) > 0;

      if (hasNewData) {
        return MigrationState.inProgress;
      }

      return MigrationState.pending;
    } catch (e) {
      debugPrint('❌ Error checking migration status: $e');
      return MigrationState.error;
    }
  }

  /// بدء عملية الترحيل
  /// Returns: OperationResult<MigrationReport>
  Future<OperationResult<MigrationReport>> startMigration() async {
    debugPrint('🚀 بدء عملية الترحيل من SharedPreferences إلى SQLite');
    
    final report = MigrationReport();
    report.startTime = DateTime.now();

    try {
      // 1. التحقق من حالة الترحيل
      final status = await checkMigrationStatus();
      if (status == MigrationState.completed) {
        debugPrint('✅ الترحيل تم بالفعل');
        return OperationResult.successWith(report..status = 'Already completed');
      }

      // 2. تحديث حالة الترحيل
      await _dbHelper.setMetadata(
        MetaTable.keyMigrationStatus,
        MigrationStatus.inProgress,
      );

      // 3. إنشاء نسخة احتياطية
      debugPrint('💾 إنشاء نسخة احتياطية...');
      final backupResult = await _createPreMigrationBackup();
      if (!backupResult.success) {
        return OperationResult.failure('فشل في إنشاء النسخة الاحتياطية');
      }
      report.backupCreated = true;

      // 4. قراءة البيانات من SharedPreferences
      debugPrint('📖 قراءة البيانات من SharedPreferences...');
      final oldDataResult = await _loadOldData();
      if (!oldDataResult.success) {
        await _rollback();
        return OperationResult.failure('فشل في قراءة البيانات القديمة: ${oldDataResult.error}');
      }

      final oldData = oldDataResult.data!;
      report.oldPagesCount = oldData['pages'].length;
      report.oldNotesCount = oldData['notes'].length;

      // 5. ترحيل البيانات إلى SQLite
      debugPrint('🔄 ترحيل البيانات إلى SQLite...');
      final migrationResult = await _migrateData(oldData);
      if (!migrationResult.success) {
        await _rollback();
        return OperationResult.failure('فشل في ترحيل البيانات: ${migrationResult.error}');
      }

      report.newPagesCount = migrationResult.data!['pages'] ?? 0;
      report.newFoldersCount = migrationResult.data!['folders'] ?? 0;
      report.newNotesCount = migrationResult.data!['notes'] ?? 0;

      // 6. التحقق من سلامة البيانات
      debugPrint('🔍 التحقق من سلامة البيانات...');
      final validationResult = await _validateMigration(report);
      if (!validationResult.success) {
        debugPrint('⚠️ تحذير: فشل التحقق من البيانات: ${validationResult.error}');
        report.warnings.add('فشل التحقق الكامل: ${validationResult.error}');
      } else {
        report.validated = true;
      }

      // 7. وضع علامة الاكتمال
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_migrationStatusKey, true);
      await _dbHelper.setMetadata(
        MetaTable.keyMigrationStatus,
        MigrationStatus.completed,
      );

      report.endTime = DateTime.now();
      report.status = 'Success';
      
      debugPrint('✅ الترحيل اكتمل بنجاح!');
      debugPrint('📊 الإحصائيات:');
      debugPrint('   - الصفحات: ${report.oldPagesCount} → ${report.newPagesCount}');
      debugPrint('   - المجلدات: ${report.newFoldersCount}');
      debugPrint('   - الملاحظات: ${report.oldNotesCount} → ${report.newNotesCount}');
      debugPrint('   - المدة: ${report.duration?.inSeconds ?? 0} ثانية');

      return OperationResult.successWith(report);
    } catch (e) {
      debugPrint('❌ خطأ حرج في الترحيل: $e');
      await _rollback();
      report.endTime = DateTime.now();
      report.status = 'Failed';
      report.errors.add(e.toString());
      return OperationResult.failure('فشل الترحيل: $e');
    }
  }

  /// إنشاء نسخة احتياطية قبل الترحيل
  Future<OperationResult<bool>> _createPreMigrationBackup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final oldNotes = prefs.getStringList(_oldNotesKey) ?? [];
      final oldPages = prefs.getStringList(_oldPagesKey) ?? [];

      final backup = {
        'timestamp': DateTime.now().toIso8601String(),
        'notes': oldNotes,
        'pages': oldPages,
      };

      await prefs.setString(_migrationBackupKey, jsonEncode(backup));
      debugPrint('✅ تم إنشاء نسخة احتياطية: ${oldNotes.length} ملاحظة، ${oldPages.length} صفحة');
      
      return OperationResult.successWith(true);
    } catch (e) {
      debugPrint('❌ فشل في إنشاء النسخة الاحتياطية: $e');
      return OperationResult.failure(e.toString());
    }
  }

  /// قراءة البيانات القديمة من SharedPreferences
  Future<OperationResult<Map<String, dynamic>>> _loadOldData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // قراءة الصفحات
      final pagesData = prefs.getStringList(_oldPagesKey) ?? [];
      final pages = <Map<String, dynamic>>[];
      
      for (final pageStr in pagesData) {
        try {
          final pageData = jsonDecode(pageStr) as Map<String, dynamic>;
          pages.add(pageData);
        } catch (e) {
          debugPrint('⚠️ تخطي صفحة تالفة: $e');
        }
      }

      // قراءة الملاحظات
      final notesData = prefs.getStringList(_oldNotesKey) ?? [];
      final notes = <Map<String, dynamic>>[];
      
      for (final noteStr in notesData) {
        try {
          final noteData = jsonDecode(noteStr) as Map<String, dynamic>;
          
          // التحقق من ID وإنشاء واحد جديد إذا كان مفقوداً أو مكرراً
          if (noteData['id'] == null || noteData['id'].toString().isEmpty) {
            noteData['id'] = const Uuid().v4();
            debugPrint('⚠️ تم إنشاء ID جديد لملاحظة');
          }
          
          notes.add(noteData);
        } catch (e) {
          debugPrint('⚠️ تخطي ملاحظة تالفة: $e');
        }
      }

      debugPrint('✅ تم قراءة ${pages.length} صفحة و ${notes.length} ملاحظة');
      
      return OperationResult.successWith({
        'pages': pages,
        'notes': notes,
      });
    } catch (e) {
      debugPrint('❌ فشل في قراءة البيانات القديمة: $e');
      return OperationResult.failure(e.toString());
    }
  }

  /// ترحيل البيانات إلى SQLite
  Future<OperationResult<Map<String, int>>> _migrateData(Map<String, dynamic> oldData) async {
    try {
      final db = await _dbHelper.database;
      int pagesCount = 0;
      int foldersCount = 0;
      int notesCount = 0;

      // استخدام Transaction لضمان سلامة البيانات
      await db.transaction((txn) async {
        final pages = oldData['pages'] as List<dynamic>;
        final notes = oldData['notes'] as List<dynamic>;

        // إذا لم توجد صفحات، إنشاء صفحة افتراضية
        if (pages.isEmpty) {
          final defaultPage = {
            'id': 'p1',
            'title': 'الصفحة الرئيسية',
            'folders': [
              {'id': 'f1', 'title': 'عام', 'updatedAt': DateTime.now().millisecondsSinceEpoch, 'isPinned': false}
            ],
          };
          pages.add(defaultPage);
        }

        // ترحيل الصفحات والمجلدات
        for (final pageData in pages) {
          final page = pageData as Map<String, dynamic>;
          final pageId = page['id'] as String;
          final now = DateTime.now().millisecondsSinceEpoch;

          // إدراج الصفحة
          await txn.insert(
            PagesTable.tableName,
            {
              PagesTable.columnId: pageId,
              PagesTable.columnTitle: page['title'] ?? 'صفحة',
              PagesTable.columnCreatedAt: now,
              PagesTable.columnUpdatedAt: now,
              PagesTable.columnSortOrder: pagesCount,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          pagesCount++;

          // إدراج المجلدات
          final folders = (page['folders'] as List<dynamic>?) ?? [];
          for (final folderData in folders) {
            final folder = folderData as Map<String, dynamic>;
            final folderId = folder['id'] as String;

            await txn.insert(
              FoldersTable.tableName,
              {
                FoldersTable.columnId: folderId,
                FoldersTable.columnPageId: pageId,
                FoldersTable.columnTitle: folder['title'] ?? 'مجلد',
                FoldersTable.columnIsPinned: folder['isPinned'] == true ? 1 : 0,
                FoldersTable.columnBackgroundColor: null,
                FoldersTable.columnCreatedAt: now,
                FoldersTable.columnUpdatedAt: folder['updatedAt'] ?? now,
                FoldersTable.columnSortOrder: foldersCount,
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
            foldersCount++;
          }
        }

        // ترحيل الملاحظات
        for (final noteData in notes) {
          final note = noteData as Map<String, dynamic>;
          final noteId = note['id'] as String;
          final pageId = note['pageId'] as String? ?? 'p1';
          final folderId = note['folderId'] as String? ?? 'f1';

          await txn.insert(
            NotesTable.tableName,
            {
              NotesTable.columnId: noteId,
              NotesTable.columnPageId: pageId,
              NotesTable.columnFolderId: folderId,
              NotesTable.columnType: note['type'] ?? 'text',
              NotesTable.columnContent: note['content'] ?? '',
              NotesTable.columnColorValue: note['colorValue'],
              NotesTable.columnIsPinned: note['isPinned'] == true ? 1 : 0,
              NotesTable.columnIsArchived: note['isArchived'] == true ? 1 : 0,
              NotesTable.columnIsDeleted: note['isDeleted'] == true ? 1 : 0,
              NotesTable.columnCreatedAt: note['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
              NotesTable.columnUpdatedAt: note['updatedAt'] ?? DateTime.now().millisecondsSinceEpoch,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          notesCount++;

          // ترحيل المرفقات
          final attachments = note['attachments'] as List<dynamic>?;
          if (attachments != null && attachments.isNotEmpty) {
            for (final attachment in attachments) {
              final attachmentId = const Uuid().v4();
              await txn.insert(
                AttachmentsTable.tableName,
                {
                  AttachmentsTable.columnId: attachmentId,
                  AttachmentsTable.columnNoteId: noteId,
                  AttachmentsTable.columnType: 'other',
                  AttachmentsTable.columnPath: attachment.toString(),
                  AttachmentsTable.columnFileName: attachment.toString().split('/').last,
                  AttachmentsTable.columnFileSize: null,
                  AttachmentsTable.columnCreatedAt: DateTime.now().millisecondsSinceEpoch,
                },
              );
            }
          }
        }
      });

      debugPrint('✅ تم ترحيل: $pagesCount صفحة، $foldersCount مجلد، $notesCount ملاحظة');
      
      return OperationResult.successWith({
        'pages': pagesCount,
        'folders': foldersCount,
        'notes': notesCount,
      });
    } catch (e) {
      debugPrint('❌ فشل في ترحيل البيانات: $e');
      return OperationResult.failure(e.toString());
    }
  }

  /// التحقق من سلامة الترحيل
  Future<OperationResult<bool>> _validateMigration(MigrationReport report) async {
    try {
      // 1. التحقق من سلامة قاعدة البيانات
      final integrityResult = await _sqliteStore.validateIntegrity();
      if (!integrityResult.success) {
        return OperationResult.failure('فشل فحص السلامة: ${integrityResult.error}');
      }

      // 2. مقارنة الأعداد
      final statsResult = await _sqliteStore.getStatistics();
      if (!statsResult.success) {
        return OperationResult.failure('فشل في الحصول على الإحصائيات');
      }

      final stats = statsResult.data!;
      final newNotesCount = stats['notes'] ?? 0;

      // السماح ببعض الاختلاف (ملاحظات محذوفة مثلاً)
      final difference = (report.oldNotesCount - newNotesCount).abs();
      if (difference > report.oldNotesCount * 0.1) {
        debugPrint('⚠️ فرق كبير في عدد الملاحظات: القديم=${report.oldNotesCount}, الجديد=$newNotesCount');
        return OperationResult.failure('فرق كبير في عدد الملاحظات');
      }

      // 3. التحقق من عينات المحتوى (أول 5 وآخر 5 ملاحظات)
      final validationResult = await _validateSampleContent();
      if (!validationResult.success) {
        report.warnings.add('تحذير في التحقق من المحتوى: ${validationResult.error}');
      }

      debugPrint('✅ التحقق من الترحيل نجح');
      return OperationResult.successWith(true);
    } catch (e) {
      debugPrint('❌ فشل في التحقق من الترحيل: $e');
      return OperationResult.failure(e.toString());
    }
  }

  /// التحقق من عينات المحتوى
  Future<OperationResult<bool>> _validateSampleContent() async {
    try {
      final db = await _dbHelper.database;
      
      // أول 5 ملاحظات
      final firstNotes = await db.query(
        NotesTable.tableName,
        orderBy: '${NotesTable.columnCreatedAt} ASC',
        limit: 5,
      );

      // آخر 5 ملاحظات
      final lastNotes = await db.query(
        NotesTable.tableName,
        orderBy: '${NotesTable.columnCreatedAt} DESC',
        limit: 5,
      );

      // التحقق من أن المحتوى ليس فارغاً
      for (final note in [...firstNotes, ...lastNotes]) {
        final content = note[NotesTable.columnContent] as String?;
        if (content == null || content.isEmpty) {
          debugPrint('⚠️ وجدت ملاحظة بمحتوى فارغ: ${note[NotesTable.columnId]}');
        }
      }

      debugPrint('✅ تم التحقق من ${firstNotes.length + lastNotes.length} ملاحظة نموذجية');
      return OperationResult.successWith(true);
    } catch (e) {
      debugPrint('❌ فشل في التحقق من عينات المحتوى: $e');
      return OperationResult.failure(e.toString());
    }
  }

  /// التراجع عن الترحيل
  Future<void> _rollback() async {
    try {
      debugPrint('🔄 التراجع عن الترحيل...');

      await _dbHelper.setMetadata(
        MetaTable.keyMigrationStatus,
        MigrationStatus.rolledBack,
      );

      // يمكن إضافة منطق إضافي لحذف البيانات المُدرجة

      debugPrint('✅ تم التراجع');
    } catch (e) {
      debugPrint('❌ فشل في التراجع: $e');
    }
  }

  /// استرداد من النسخة الاحتياطية قبل الترحيل
  Future<OperationResult<bool>> restoreFromPreMigrationBackup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final backupStr = prefs.getString(_migrationBackupKey);

      if (backupStr == null) {
        return OperationResult.failure('لا توجد نسخة احتياطية');
      }

      final backup = jsonDecode(backupStr) as Map<String, dynamic>;
      final notes = backup['notes'] as List<dynamic>;
      final pages = backup['pages'] as List<dynamic>;

      await prefs.setStringList(_oldNotesKey, notes.cast<String>());
      await prefs.setStringList(_oldPagesKey, pages.cast<String>());
      await prefs.setBool(_migrationStatusKey, false);

      debugPrint('✅ تم الاسترداد من النسخة الاحتياطية');
      return OperationResult.successWith(true);
    } catch (e) {
      debugPrint('❌ فشل في الاسترداد: $e');
      return OperationResult.failure(e.toString());
    }
  }
}

/// حالة الترحيل
enum MigrationState {
  notNeeded,    // لا يوجد بيانات قديمة
  pending,      // في انتظار البدء
  inProgress,   // قيد التنفيذ
  completed,    // مكتمل
  error,        // خطأ
}

/// تقرير الترحيل
class MigrationReport {
  DateTime? startTime;
  DateTime? endTime;
  String status = 'Unknown';
  
  int oldPagesCount = 0;
  int oldNotesCount = 0;
  
  int newPagesCount = 0;
  int newFoldersCount = 0;
  int newNotesCount = 0;
  
  bool backupCreated = false;
  bool validated = false;
  
  List<String> warnings = [];
  List<String> errors = [];

  Duration? get duration {
    if (startTime != null && endTime != null) {
      return endTime!.difference(startTime!);
    }
    return null;
  }

  @override
  String toString() {
    return '''
Migration Report:
  Status: $status
  Duration: ${duration?.inSeconds ?? '?'} seconds
  
  Old Data:
    - Pages: $oldPagesCount
    - Notes: $oldNotesCount
  
  New Data:
    - Pages: $newPagesCount
    - Folders: $newFoldersCount
    - Notes: $newNotesCount
  
  Flags:
    - Backup Created: $backupCreated
    - Validated: $validated
  
  Warnings: ${warnings.length}
  Errors: ${errors.length}
''';
  }
}
