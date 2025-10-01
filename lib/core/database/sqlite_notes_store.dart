import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

import '../../models/page_model.dart';
import '../../models/folder_model.dart';
import '../../models/note_model.dart';
import 'i_notes_store.dart';
import 'database_helper.dart';
import 'database_contract.dart';

/// SQLite Store - تنفيذ واجهة التخزين باستخدام SQLite
class SqliteNotesStore implements INotesStore {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // ==================== Pages Operations ====================

  @override
  Future<OperationResult<String>> savePage(PageModel page) async {
    try {
      final db = await _dbHelper.database;
      final now = DateTime.now().millisecondsSinceEpoch;

      await db.insert(
        PagesTable.tableName,
        {
          PagesTable.columnId: page.id,
          PagesTable.columnTitle: page.title,
          PagesTable.columnCreatedAt: now,
          PagesTable.columnUpdatedAt: now,
          PagesTable.columnSortOrder: 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      debugPrint('✅ Page saved: ${page.id}');
      return OperationResult.successWith(page.id);
    } catch (e) {
      debugPrint('❌ Error saving page: $e');
      return OperationResult.failure('فشل في حفظ الصفحة: $e');
    }
  }

  @override
  Future<OperationResult<List<PageModel>>> getAllPages() async {
    try {
      final db = await _dbHelper.database;
      final results = await db.query(
        PagesTable.tableName,
        orderBy: '${PagesTable.columnSortOrder} ASC, ${PagesTable.columnUpdatedAt} DESC',
      );

      final pages = <PageModel>[];
      for (final row in results) {
        final pageId = row[PagesTable.columnId] as String;
        final foldersResult = await getFoldersByPageId(pageId);
        
        pages.add(PageModel(
          id: pageId,
          title: row[PagesTable.columnTitle] as String,
          folders: foldersResult.data ?? [],
        ));
      }

      debugPrint('✅ Loaded ${pages.length} pages');
      return OperationResult.successWith(pages);
    } catch (e) {
      debugPrint('❌ Error loading pages: $e');
      return OperationResult.failure('فشل في تحميل الصفحات: $e');
    }
  }

  @override
  Future<OperationResult<PageModel>> getPageById(String pageId) async {
    try {
      final db = await _dbHelper.database;
      final results = await db.query(
        PagesTable.tableName,
        where: '${PagesTable.columnId} = ?',
        whereArgs: [pageId],
        limit: 1,
      );

      if (results.isEmpty) {
        return OperationResult.notFound('الصفحة غير موجودة');
      }

      final row = results.first;
      final foldersResult = await getFoldersByPageId(pageId);

      final page = PageModel(
        id: pageId,
        title: row[PagesTable.columnTitle] as String,
        folders: foldersResult.data ?? [],
      );

      return OperationResult.successWith(page);
    } catch (e) {
      debugPrint('❌ Error getting page: $e');
      return OperationResult.failure('فشل في تحميل الصفحة: $e');
    }
  }

  @override
  Future<OperationResult<bool>> updatePage(PageModel page) async {
    try {
      final db = await _dbHelper.database;
      final now = DateTime.now().millisecondsSinceEpoch;

      final count = await db.update(
        PagesTable.tableName,
        {
          PagesTable.columnTitle: page.title,
          PagesTable.columnUpdatedAt: now,
        },
        where: '${PagesTable.columnId} = ?',
        whereArgs: [page.id],
      );

      if (count == 0) {
        return OperationResult.notFound('الصفحة غير موجودة');
      }

      debugPrint('✅ Page updated: ${page.id}');
      return OperationResult.successWith(true);
    } catch (e) {
      debugPrint('❌ Error updating page: $e');
      return OperationResult.failure('فشل في تحديث الصفحة: $e');
    }
  }

  @override
  Future<OperationResult<bool>> deletePage(String pageId) async {
    try {
      final db = await _dbHelper.database;
      
      // Foreign keys will cascade delete folders and notes
      final count = await db.delete(
        PagesTable.tableName,
        where: '${PagesTable.columnId} = ?',
        whereArgs: [pageId],
      );

      if (count == 0) {
        return OperationResult.notFound('الصفحة غير موجودة');
      }

      debugPrint('✅ Page deleted: $pageId');
      return OperationResult.successWith(true);
    } catch (e) {
      debugPrint('❌ Error deleting page: $e');
      return OperationResult.failure('فشل في حذف الصفحة: $e');
    }
  }

  // ==================== Folders Operations ====================

  @override
  Future<OperationResult<String>> saveFolder(FolderModel folder, String pageId) async {
    try {
      final db = await _dbHelper.database;
      final now = DateTime.now().millisecondsSinceEpoch;

      await db.insert(
        FoldersTable.tableName,
        {
          FoldersTable.columnId: folder.id,
          FoldersTable.columnPageId: pageId,
          FoldersTable.columnTitle: folder.title,
          FoldersTable.columnIsPinned: folder.isPinned ? 1 : 0,
          FoldersTable.columnBackgroundColor: folder.backgroundColor?.value,
          FoldersTable.columnCreatedAt: now,
          FoldersTable.columnUpdatedAt: folder.updatedAt.millisecondsSinceEpoch,
          FoldersTable.columnSortOrder: 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      debugPrint('✅ Folder saved: ${folder.id}');
      return OperationResult.successWith(folder.id);
    } catch (e) {
      debugPrint('❌ Error saving folder: $e');
      return OperationResult.failure('فشل في حفظ المجلد: $e');
    }
  }

  @override
  Future<OperationResult<List<FolderModel>>> getFoldersByPageId(String pageId) async {
    try {
      final db = await _dbHelper.database;
      final results = await db.query(
        FoldersTable.tableName,
        where: '${FoldersTable.columnPageId} = ?',
        whereArgs: [pageId],
        orderBy: '${FoldersTable.columnIsPinned} DESC, ${FoldersTable.columnUpdatedAt} DESC',
      );

      final folders = <FolderModel>[];
      for (final row in results) {
        final folderId = row[FoldersTable.columnId] as String;
        final notesResult = await getNotesByFolderId(folderId);
        
        final bgColorValue = row[FoldersTable.columnBackgroundColor] as int?;
        
        folders.add(FolderModel(
          id: folderId,
          title: row[FoldersTable.columnTitle] as String,
          notes: notesResult.data ?? [],
          updatedAt: DateTime.fromMillisecondsSinceEpoch(
            row[FoldersTable.columnUpdatedAt] as int,
          ),
          isPinned: (row[FoldersTable.columnIsPinned] as int) == 1,
          backgroundColor: bgColorValue != null ? Color(bgColorValue) : null,
        ));
      }

      debugPrint('✅ Loaded ${folders.length} folders for page $pageId');
      return OperationResult.successWith(folders);
    } catch (e) {
      debugPrint('❌ Error loading folders: $e');
      return OperationResult.failure('فشل في تحميل المجلدات: $e');
    }
  }

  @override
  Future<OperationResult<FolderModel>> getFolderById(String folderId) async {
    try {
      final db = await _dbHelper.database;
      final results = await db.query(
        FoldersTable.tableName,
        where: '${FoldersTable.columnId} = ?',
        whereArgs: [folderId],
        limit: 1,
      );

      if (results.isEmpty) {
        return OperationResult.notFound('المجلد غير موجود');
      }

      final row = results.first;
      final notesResult = await getNotesByFolderId(folderId);
      final bgColorValue = row[FoldersTable.columnBackgroundColor] as int?;

      final folder = FolderModel(
        id: folderId,
        title: row[FoldersTable.columnTitle] as String,
        notes: notesResult.data ?? [],
        updatedAt: DateTime.fromMillisecondsSinceEpoch(
          row[FoldersTable.columnUpdatedAt] as int,
        ),
        isPinned: (row[FoldersTable.columnIsPinned] as int) == 1,
        backgroundColor: bgColorValue != null ? Color(bgColorValue) : null,
      );

      return OperationResult.successWith(folder);
    } catch (e) {
      debugPrint('❌ Error getting folder: $e');
      return OperationResult.failure('فشل في تحميل المجلد: $e');
    }
  }

  @override
  Future<OperationResult<bool>> updateFolder(FolderModel folder) async {
    try {
      final db = await _dbHelper.database;
      final now = DateTime.now().millisecondsSinceEpoch;

      final count = await db.update(
        FoldersTable.tableName,
        {
          FoldersTable.columnTitle: folder.title,
          FoldersTable.columnIsPinned: folder.isPinned ? 1 : 0,
          FoldersTable.columnBackgroundColor: folder.backgroundColor?.value,
          FoldersTable.columnUpdatedAt: now,
        },
        where: '${FoldersTable.columnId} = ?',
        whereArgs: [folder.id],
      );

      if (count == 0) {
        return OperationResult.notFound('المجلد غير موجود');
      }

      debugPrint('✅ Folder updated: ${folder.id}');
      return OperationResult.successWith(true);
    } catch (e) {
      debugPrint('❌ Error updating folder: $e');
      return OperationResult.failure('فشل في تحديث المجلد: $e');
    }
  }

  @override
  Future<OperationResult<bool>> deleteFolder(String folderId) async {
    try {
      final db = await _dbHelper.database;
      
      // Foreign keys will cascade delete notes
      final count = await db.delete(
        FoldersTable.tableName,
        where: '${FoldersTable.columnId} = ?',
        whereArgs: [folderId],
      );

      if (count == 0) {
        return OperationResult.notFound('المجلد غير موجود');
      }

      debugPrint('✅ Folder deleted: $folderId');
      return OperationResult.successWith(true);
    } catch (e) {
      debugPrint('❌ Error deleting folder: $e');
      return OperationResult.failure('فشل في حذف المجلد: $e');
    }
  }

  // ==================== Notes Operations ====================

  @override
  Future<OperationResult<String>> saveNote(NoteModel note, String pageId, String folderId) async {
    try {
      final db = await _dbHelper.database;
      final now = DateTime.now().millisecondsSinceEpoch;

      await db.insert(
        NotesTable.tableName,
        {
          NotesTable.columnId: note.id,
          NotesTable.columnPageId: pageId,
          NotesTable.columnFolderId: folderId,
          NotesTable.columnType: note.type.name,
          NotesTable.columnContent: note.content,
          NotesTable.columnColorValue: note.colorValue,
          NotesTable.columnIsPinned: note.isPinned ? 1 : 0,
          NotesTable.columnIsArchived: note.isArchived ? 1 : 0,
          NotesTable.columnIsDeleted: note.isDeleted ? 1 : 0,
          NotesTable.columnCreatedAt: note.createdAt.millisecondsSinceEpoch,
          NotesTable.columnUpdatedAt: now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // حفظ المرفقات إن وُجدت
      if (note.attachments != null && note.attachments!.isNotEmpty) {
        for (final attachment in note.attachments!) {
          await saveAttachment(note.id, attachment);
        }
      }

      // تحديث وقت المجلد
      await db.update(
        FoldersTable.tableName,
        {FoldersTable.columnUpdatedAt: now},
        where: '${FoldersTable.columnId} = ?',
        whereArgs: [folderId],
      );

      debugPrint('✅ Note saved: ${note.id}');
      return OperationResult.successWith(note.id);
    } catch (e) {
      debugPrint('❌ Error saving note: $e');
      return OperationResult.failure('فشل في حفظ الملاحظة: $e');
    }
  }

  @override
  Future<OperationResult<List<NoteModel>>> getNotesByFolderId(String folderId) async {
    try {
      final db = await _dbHelper.database;
      final results = await db.query(
        NotesTable.tableName,
        where: '${NotesTable.columnFolderId} = ? AND ${NotesTable.columnIsDeleted} = 0',
        whereArgs: [folderId],
        orderBy: '${NotesTable.columnIsPinned} DESC, ${NotesTable.columnCreatedAt} DESC',
      );

      final notes = <NoteModel>[];
      for (final row in results) {
        final noteId = row[NotesTable.columnId] as String;
        final attachmentsResult = await getAttachmentsByNoteId(noteId);
        
        final typeStr = row[NotesTable.columnType] as String;
        final noteType = NoteType.values.firstWhere(
          (e) => e.name == typeStr,
          orElse: () => NoteType.text,
        );

        notes.add(NoteModel(
          id: noteId,
          type: noteType,
          content: row[NotesTable.columnContent] as String,
          createdAt: DateTime.fromMillisecondsSinceEpoch(
            row[NotesTable.columnCreatedAt] as int,
          ),
          colorValue: row[NotesTable.columnColorValue] as int?,
          isPinned: (row[NotesTable.columnIsPinned] as int) == 1,
          isArchived: (row[NotesTable.columnIsArchived] as int) == 1,
          isDeleted: (row[NotesTable.columnIsDeleted] as int) == 1,
          updatedAt: DateTime.fromMillisecondsSinceEpoch(
            row[NotesTable.columnUpdatedAt] as int,
          ),
          attachments: attachmentsResult.data,
        ));
      }

      debugPrint('✅ Loaded ${notes.length} notes for folder $folderId');
      return OperationResult.successWith(notes);
    } catch (e) {
      debugPrint('❌ Error loading notes: $e');
      return OperationResult.failure('فشل في تحميل الملاحظات: $e');
    }
  }

  @override
  Future<OperationResult<NoteModel>> getNoteById(String noteId) async {
    try {
      final db = await _dbHelper.database;
      final results = await db.query(
        NotesTable.tableName,
        where: '${NotesTable.columnId} = ?',
        whereArgs: [noteId],
        limit: 1,
      );

      if (results.isEmpty) {
        return OperationResult.notFound('الملاحظة غير موجودة');
      }

      final row = results.first;
      final attachmentsResult = await getAttachmentsByNoteId(noteId);
      
      final typeStr = row[NotesTable.columnType] as String;
      final noteType = NoteType.values.firstWhere(
        (e) => e.name == typeStr,
        orElse: () => NoteType.text,
      );

      final note = NoteModel(
        id: noteId,
        type: noteType,
        content: row[NotesTable.columnContent] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          row[NotesTable.columnCreatedAt] as int,
        ),
        colorValue: row[NotesTable.columnColorValue] as int?,
        isPinned: (row[NotesTable.columnIsPinned] as int) == 1,
        isArchived: (row[NotesTable.columnIsArchived] as int) == 1,
        isDeleted: (row[NotesTable.columnIsDeleted] as int) == 1,
        updatedAt: DateTime.fromMillisecondsSinceEpoch(
          row[NotesTable.columnUpdatedAt] as int,
        ),
        attachments: attachmentsResult.data,
      );

      return OperationResult.successWith(note);
    } catch (e) {
      debugPrint('❌ Error getting note: $e');
      return OperationResult.failure('فشل في تحميل الملاحظة: $e');
    }
  }

  @override
  Future<OperationResult<bool>> updateNote(NoteModel note) async {
    try {
      final db = await _dbHelper.database;
      final now = DateTime.now().millisecondsSinceEpoch;

      final count = await db.update(
        NotesTable.tableName,
        {
          NotesTable.columnContent: note.content,
          NotesTable.columnColorValue: note.colorValue,
          NotesTable.columnIsPinned: note.isPinned ? 1 : 0,
          NotesTable.columnIsArchived: note.isArchived ? 1 : 0,
          NotesTable.columnUpdatedAt: now,
        },
        where: '${NotesTable.columnId} = ?',
        whereArgs: [note.id],
      );

      if (count == 0) {
        return OperationResult.notFound('الملاحظة غير موجودة');
      }

      debugPrint('✅ Note updated: ${note.id}');
      return OperationResult.successWith(true);
    } catch (e) {
      debugPrint('❌ Error updating note: $e');
      return OperationResult.failure('فشل في تحديث الملاحظة: $e');
    }
  }

  @override
  Future<OperationResult<bool>> deleteNote(String noteId) async {
    try {
      final db = await _dbHelper.database;
      final now = DateTime.now().millisecondsSinceEpoch;

      // حذف منطقي
      final count = await db.update(
        NotesTable.tableName,
        {
          NotesTable.columnIsDeleted: 1,
          NotesTable.columnUpdatedAt: now,
        },
        where: '${NotesTable.columnId} = ?',
        whereArgs: [noteId],
      );

      if (count == 0) {
        return OperationResult.notFound('الملاحظة غير موجودة');
      }

      debugPrint('✅ Note deleted (soft): $noteId');
      return OperationResult.successWith(true);
    } catch (e) {
      debugPrint('❌ Error deleting note: $e');
      return OperationResult.failure('فشل في حذف الملاحظة: $e');
    }
  }

  @override
  Future<OperationResult<bool>> permanentlyDeleteNote(String noteId) async {
    try {
      final db = await _dbHelper.database;
      
      // حذف نهائي (سيحذف المرفقات تلقائياً بسبب CASCADE)
      final count = await db.delete(
        NotesTable.tableName,
        where: '${NotesTable.columnId} = ?',
        whereArgs: [noteId],
      );

      if (count == 0) {
        return OperationResult.notFound('الملاحظة غير موجودة');
      }

      debugPrint('✅ Note permanently deleted: $noteId');
      return OperationResult.successWith(true);
    } catch (e) {
      debugPrint('❌ Error permanently deleting note: $e');
      return OperationResult.failure('فشل في حذف الملاحظة نهائياً: $e');
    }
  }

  // ==================== Attachments Operations ====================

  @override
  Future<OperationResult<String>> saveAttachment(String noteId, String filePath) async {
    try {
      final db = await _dbHelper.database;
      final attachmentId = const Uuid().v4();
      final now = DateTime.now().millisecondsSinceEpoch;

      // استخراج اسم الملف ونوعه
      final fileName = filePath.split('/').last;
      final extension = fileName.split('.').last.toLowerCase();
      
      String attachmentType = AttachmentTypes.other;
      if (['jpg', 'jpeg', 'png', 'gif', 'bmp'].contains(extension)) {
        attachmentType = AttachmentTypes.image;
      } else if (['mp3', 'wav', 'ogg', 'm4a'].contains(extension)) {
        attachmentType = AttachmentTypes.audio;
      } else if (['mp4', 'avi', 'mov', 'mkv'].contains(extension)) {
        attachmentType = AttachmentTypes.video;
      } else if (['pdf', 'doc', 'docx', 'txt'].contains(extension)) {
        attachmentType = AttachmentTypes.document;
      }

      await db.insert(
        AttachmentsTable.tableName,
        {
          AttachmentsTable.columnId: attachmentId,
          AttachmentsTable.columnNoteId: noteId,
          AttachmentsTable.columnType: attachmentType,
          AttachmentsTable.columnPath: filePath,
          AttachmentsTable.columnFileName: fileName,
          AttachmentsTable.columnFileSize: null, // يمكن إضافته لاحقاً
          AttachmentsTable.columnCreatedAt: now,
        },
      );

      debugPrint('✅ Attachment saved: $attachmentId');
      return OperationResult.successWith(attachmentId);
    } catch (e) {
      debugPrint('❌ Error saving attachment: $e');
      return OperationResult.failure('فشل في حفظ المرفق: $e');
    }
  }

  @override
  Future<OperationResult<List<String>>> getAttachmentsByNoteId(String noteId) async {
    try {
      final db = await _dbHelper.database;
      final results = await db.query(
        AttachmentsTable.tableName,
        where: '${AttachmentsTable.columnNoteId} = ?',
        whereArgs: [noteId],
        orderBy: '${AttachmentsTable.columnCreatedAt} ASC',
      );

      final attachments = results
          .map((row) => row[AttachmentsTable.columnPath] as String)
          .toList();

      return OperationResult.successWith(attachments);
    } catch (e) {
      debugPrint('❌ Error loading attachments: $e');
      return OperationResult.failure('فشل في تحميل المرفقات: $e');
    }
  }

  @override
  Future<OperationResult<bool>> deleteAttachment(String attachmentId) async {
    try {
      final db = await _dbHelper.database;
      
      final count = await db.delete(
        AttachmentsTable.tableName,
        where: '${AttachmentsTable.columnId} = ?',
        whereArgs: [attachmentId],
      );

      if (count == 0) {
        return OperationResult.notFound('المرفق غير موجود');
      }

      debugPrint('✅ Attachment deleted: $attachmentId');
      return OperationResult.successWith(true);
    } catch (e) {
      debugPrint('❌ Error deleting attachment: $e');
      return OperationResult.failure('فشل في حذف المرفق: $e');
    }
  }

  // ==================== Backup & Migration ====================

  @override
  Future<OperationResult<String>> createFullBackup() async {
    try {
      final db = await _dbHelper.database;
      final now = DateTime.now().millisecondsSinceEpoch;

      // جمع جميع البيانات
      final pagesResult = await getAllPages();
      if (!pagesResult.success) {
        return OperationResult.failure('فشل في جمع الصفحات للنسخ الاحتياطي');
      }

      final backupData = {
        'version': kDatabaseVersion,
        'timestamp': now,
        'pages': pagesResult.data!.map((page) => _pageToJson(page)).toList(),
      };

      final backupJson = jsonEncode(backupData);
      final backupId = const Uuid().v4();

      // حفظ في جدول النسخ الاحتياطية
      await db.insert(BackupsTable.tableName, {
        BackupsTable.columnId: backupId,
        BackupsTable.columnType: 'full',
        BackupsTable.columnData: backupJson,
        BackupsTable.columnCreatedAt: now,
        BackupsTable.columnNote: 'نسخة احتياطية كاملة',
      });

      debugPrint('✅ Full backup created: $backupId');
      return OperationResult.successWith(backupJson);
    } catch (e) {
      debugPrint('❌ Error creating backup: $e');
      return OperationResult.failure('فشل في إنشاء نسخة احتياطية: $e');
    }
  }

  @override
  Future<OperationResult<bool>> restoreFromBackup(String backupData) async {
    try {
      final db = await _dbHelper.database;
      final data = jsonDecode(backupData) as Map<String, dynamic>;

      // التحقق من الإصدار
      final version = data['version'] as int?;
      if (version == null) {
        return OperationResult.failure('نسخة احتياطية غير صالحة');
      }

      // استخدام Transaction للسلامة
      await db.transaction((txn) async {
        // حذف البيانات الحالية
        await txn.delete(NotesTable.tableName);
        await txn.delete(FoldersTable.tableName);
        await txn.delete(PagesTable.tableName);

        // استرداد البيانات
        final pages = data['pages'] as List<dynamic>;
        for (final pageData in pages) {
          await _restorePage(txn, pageData as Map<String, dynamic>);
        }
      });

      debugPrint('✅ Backup restored successfully');
      return OperationResult.successWith(true);
    } catch (e) {
      debugPrint('❌ Error restoring backup: $e');
      return OperationResult.failure('فشل في استرداد النسخة الاحتياطية: $e');
    }
  }

  @override
  Future<OperationResult<bool>> validateIntegrity() async {
    try {
      final isValid = await _dbHelper.validateDatabaseIntegrity();
      
      if (!isValid) {
        return OperationResult.failure('قاعدة البيانات تالفة');
      }

      // فحص إضافي: التحقق من العلاقات
      final db = await _dbHelper.database;
      
      // التحقق من أن جميع المجلدات تنتمي لصفحات موجودة
      final orphanedFolders = await db.rawQuery('''
        SELECT COUNT(*) as count FROM ${FoldersTable.tableName} f
        LEFT JOIN ${PagesTable.tableName} p ON f.${FoldersTable.columnPageId} = p.${PagesTable.columnId}
        WHERE p.${PagesTable.columnId} IS NULL
      ''');
      
      final orphanedCount = Sqflite.firstIntValue(orphanedFolders) ?? 0;
      if (orphanedCount > 0) {
        debugPrint('⚠️ Found $orphanedCount orphaned folders');
        return OperationResult.failure('توجد مجلدات معزولة (بدون صفحة)');
      }

      debugPrint('✅ Database integrity validated');
      return OperationResult.successWith(true);
    } catch (e) {
      debugPrint('❌ Error validating integrity: $e');
      return OperationResult.failure('فشل في التحقق من سلامة البيانات: $e');
    }
  }

  @override
  Future<OperationResult<Map<String, int>>> getStatistics() async {
    try {
      final stats = await _dbHelper.getDatabaseStats();
      return OperationResult.successWith(stats);
    } catch (e) {
      debugPrint('❌ Error getting statistics: $e');
      return OperationResult.failure('فشل في الحصول على الإحصائيات: $e');
    }
  }

  // ==================== Helper Methods ====================

  Map<String, dynamic> _pageToJson(PageModel page) {
    return {
      'id': page.id,
      'title': page.title,
      'folders': page.folders.map((folder) => _folderToJson(folder)).toList(),
    };
  }

  Map<String, dynamic> _folderToJson(FolderModel folder) {
    return {
      'id': folder.id,
      'title': folder.title,
      'isPinned': folder.isPinned,
      'backgroundColor': folder.backgroundColor?.value,
      'updatedAt': folder.updatedAt.millisecondsSinceEpoch,
      'notes': folder.notes.map((note) => _noteToJson(note)).toList(),
    };
  }

  Map<String, dynamic> _noteToJson(NoteModel note) {
    return {
      'id': note.id,
      'type': note.type.name,
      'content': note.content,
      'createdAt': note.createdAt.millisecondsSinceEpoch,
      'colorValue': note.colorValue,
      'isPinned': note.isPinned,
      'isArchived': note.isArchived,
      'isDeleted': note.isDeleted,
      'updatedAt': note.updatedAt?.millisecondsSinceEpoch,
      'attachments': note.attachments,
    };
  }

  Future<void> _restorePage(Transaction txn, Map<String, dynamic> pageData) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    await txn.insert(PagesTable.tableName, {
      PagesTable.columnId: pageData['id'],
      PagesTable.columnTitle: pageData['title'],
      PagesTable.columnCreatedAt: now,
      PagesTable.columnUpdatedAt: now,
      PagesTable.columnSortOrder: 0,
    });

    final folders = pageData['folders'] as List<dynamic>?;
    if (folders != null) {
      for (final folderData in folders) {
        await _restoreFolder(txn, pageData['id'] as String, folderData as Map<String, dynamic>);
      }
    }
  }

  Future<void> _restoreFolder(Transaction txn, String pageId, Map<String, dynamic> folderData) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    await txn.insert(FoldersTable.tableName, {
      FoldersTable.columnId: folderData['id'],
      FoldersTable.columnPageId: pageId,
      FoldersTable.columnTitle: folderData['title'],
      FoldersTable.columnIsPinned: folderData['isPinned'] == true ? 1 : 0,
      FoldersTable.columnBackgroundColor: folderData['backgroundColor'],
      FoldersTable.columnCreatedAt: now,
      FoldersTable.columnUpdatedAt: folderData['updatedAt'] ?? now,
      FoldersTable.columnSortOrder: 0,
    });

    final notes = folderData['notes'] as List<dynamic>?;
    if (notes != null) {
      for (final noteData in notes) {
        await _restoreNote(txn, pageId, folderData['id'] as String, noteData as Map<String, dynamic>);
      }
    }
  }

  Future<void> _restoreNote(Transaction txn, String pageId, String folderId, Map<String, dynamic> noteData) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    await txn.insert(NotesTable.tableName, {
      NotesTable.columnId: noteData['id'],
      NotesTable.columnPageId: pageId,
      NotesTable.columnFolderId: folderId,
      NotesTable.columnType: noteData['type'],
      NotesTable.columnContent: noteData['content'],
      NotesTable.columnColorValue: noteData['colorValue'],
      NotesTable.columnIsPinned: noteData['isPinned'] == true ? 1 : 0,
      NotesTable.columnIsArchived: noteData['isArchived'] == true ? 1 : 0,
      NotesTable.columnIsDeleted: noteData['isDeleted'] == true ? 1 : 0,
      NotesTable.columnCreatedAt: noteData['createdAt'] ?? now,
      NotesTable.columnUpdatedAt: noteData['updatedAt'] ?? now,
    });

    // استرداد المرفقات
    final attachments = noteData['attachments'] as List<dynamic>?;
    if (attachments != null) {
      for (final attachment in attachments) {
        final attachmentId = const Uuid().v4();
        await txn.insert(AttachmentsTable.tableName, {
          AttachmentsTable.columnId: attachmentId,
          AttachmentsTable.columnNoteId: noteData['id'],
          AttachmentsTable.columnType: AttachmentTypes.other,
          AttachmentsTable.columnPath: attachment.toString(),
          AttachmentsTable.columnFileName: attachment.toString().split('/').last,
          AttachmentsTable.columnFileSize: null,
          AttachmentsTable.columnCreatedAt: now,
        });
      }
    }
  }
}
