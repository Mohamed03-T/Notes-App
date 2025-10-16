import '../models/page_model.dart';
import '../models/folder_model.dart';
import '../models/note_model.dart';
import '../core/database/sqlite_notes_store.dart';
import '../core/database/i_notes_store.dart';
import '../core/database/database_helper.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart' show debugPrint;
// dart:convert removed - no longer needed for SharedPreferences migration

class NotesRepository {
  // Singleton pattern
  static NotesRepository? _instance;
  static Future<NotesRepository> get instance async {
    if (_instance == null) {
      _instance = NotesRepository._internal();
      await _instance!._initialize();
    }
    return _instance!;
  }

  // 🔵 SQLite Storage Layer
  late final INotesStore _store;
  
  // Keep an in-memory seed for UI, but persist notes to local storage
  final List<PageModel> _pages = [];
  
  static const int _currentDataVersion = 3; // ⬆️ الإصدار الحالي (SQLite)
  
  bool _isInitialized = false;
  bool _hasNewChanges = false;
  bool _usingSqlite = false; // 🔵 علم للإشارة إلى استخدام SQLite

  NotesRepository._internal();

  // للاستخدام المباشر (سيعمل بالبيانات التجريبية حتى ينتهي التحميل)
  factory NotesRepository() {
    if (_instance == null) {
      _instance = NotesRepository._internal();
      // ملاحظة: هذا factory للاستخدام السريع فقط
      // يُفضل استخدام NotesRepository.instance للتهيئة الكاملة
      _instance!._loadPages().then((_) {
        if (_instance!._pages.isEmpty) {
          _instance!._seed();
        }
        _instance!._loadSavedNotes();
      });
    }
    return _instance!;
  }

  Future<void> _initialize() async {
    if (!_isInitialized) {
      // 🔵 1️⃣ تهيئة SQLite Store
      _store = SqliteNotesStore();
      
  // Using SQLite-only store.
      _usingSqlite = true;
      await _loadFromSqlite();
      
      _isInitialized = true;
      debugPrint('✅ تم تهيئة NotesRepository: ${_pages.length} صفحة (SQLite: $_usingSqlite)');
    }
  }

  // 🔵 تحميل البيانات من SQLite
  Future<void> _loadFromSqlite() async {
    try {
      // 1️⃣ حمّل الصفحات
      final pagesResult = await _store.getAllPages();
      if (pagesResult.success && pagesResult.data != null) {
        _pages.clear();
        _pages.addAll(pagesResult.data!);
        debugPrint('✅ تم تحميل ${_pages.length} صفحة من SQLite');
      }
      
      // 2️⃣ إذا لم توجد صفحات، أنشئ الافتراضية
      if (_pages.isEmpty) {
        _seed();
        await _savePagesToSqlite();
      }
      
      // 3️⃣ حمّل المجلدات والملاحظات لكل صفحة
      for (final page in _pages) {
        final foldersResult = await _store.getFoldersByPageId(page.id);
        if (foldersResult.success && foldersResult.data != null) {
          page.folders.clear();
          page.folders.addAll(foldersResult.data!);
          
          // حمّل الملاحظات لكل مجلد
          for (final folder in page.folders) {
            final notesResult = await _store.getNotesByFolderId(folder.id);
            if (notesResult.success && notesResult.data != null) {
              folder.notes.clear();
              folder.notes.addAll(notesResult.data!);
            }
          }
        }
      }
      
      debugPrint('✅ تم تحميل جميع البيانات من SQLite');
    } catch (e) {
      debugPrint('❌ خطأ في تحميل البيانات من SQLite: $e');
    }
  }

  // 🔵 حفظ الصفحات إلى SQLite
  Future<void> _savePagesToSqlite() async {
    for (final page in _pages) {
      await _store.savePage(page);
      for (final folder in page.folders) {
        await _store.saveFolder(folder, page.id);
        for (final note in folder.notes) {
          await _store.saveNote(note, page.id, folder.id);
        }
      }
    }
  }

  // SQLite-only loading.

  bool get hasNewChanges => _hasNewChanges;
  
  void markChangesAsViewed() {
    _hasNewChanges = false;
  }

  // Migration logic removed. This repository uses SQLite only.

  // Load saved notes from SQLite
  Future<void> _loadSavedNotes() async {
    await _loadFromSqlite();
  }

  void _recomputeAllFolderTimestamps() {
    for (final page in _pages) {
      for (int i = 0; i < page.folders.length; i++) {
        final folder = page.folders[i];
        if (folder.notes.isNotEmpty) {
          // احسب أحدث createdAt بين ملاحظات المجلد
          DateTime latest = folder.notes.first.createdAt;
          for (final n in folder.notes) {
            if (n.createdAt.isAfter(latest)) latest = n.createdAt;
          }
          // استبدال المجلد بواحد جديد يحمل updatedAt الأحدث
          page.folders[i] = FolderModel(
            id: folder.id,
            title: folder.title,
            notes: folder.notes,
            updatedAt: latest,
          );
        }
      }
    }
  }

  // Folder-order persistence removed; ordering is handled in-memory and persisted via SQLite when needed.

  void _seed() {
    // تحقق من وجود البيانات أولاً
    if (_pages.isNotEmpty) {
      return;
    }

  // Ensure at least one default page and folder exist so legacy notes (p1/f1) have a target
  debugPrint('📋 لا توجد صفحات، إنشاء صفحة ومجلد افتراضي');
  final defaultPage = PageModel(id: 'p1', title: 'الصفحة الرئيسية', folders: []);
  final defaultFolder = FolderModel(id: 'f1', title: 'عام', notes: [], updatedAt: DateTime.now());
  defaultPage.folders.add(defaultFolder);
  _pages.add(defaultPage);
  // Persist the created default structure
  _savePages();
  }

  List<PageModel> getPages() => _pages;

  List<PageModel> getPagesSortedByActivity() {
    final sortedPages = List<PageModel>.from(_pages);
    
    // ترتيب الصفحات حسب آخر نشاط (أحدث مجلد تم تعديله في كل صفحة)
    sortedPages.sort((a, b) {
      final aLatest = _getLatestFolderUpdate(a);
      final bLatest = _getLatestFolderUpdate(b);
      return bLatest.compareTo(aLatest); // ترتيب تنازلي (الأحدث أولاً)
    });
    
    return sortedPages;
  }

  DateTime _getLatestFolderUpdate(PageModel page) {
    if (page.folders.isEmpty) return DateTime(2000); // تاريخ قديم للصفحات الفارغة
    
    DateTime latest = page.folders.first.updatedAt;
    for (final folder in page.folders) {
      if (folder.updatedAt.isAfter(latest)) {
        latest = folder.updatedAt;
      }
    }
    return latest;
  }

  PageModel? getPage(String id) {
    try {
      return _pages.firstWhere((p) => p.id == id);
    } catch (e) {
      // إذا لم يجد الصفحة المطلوبة، حاول إرجاع أول صفحة
      if (_pages.isNotEmpty) {
        return _pages.first;
      }
      return null;
    }
  }

  // إضافة صفحة جديدة
  String addNewPage(String title) {
    final id = Uuid().v4();
    final newPage = PageModel(
      id: id,
      title: title,
      folders: [],
    );
    _pages.add(newPage);
    debugPrint('📄 تم إضافة صفحة جديدة: $title (ID: $id)');
    _savePages();
    if (_usingSqlite) {
      _savePagesToSqlite();
    }
    return id;
  }

  // إضافة مجلد جديد إلى صفحة
  String addNewFolder(String pageId, String folderTitle) {
    final folderId = Uuid().v4();
    final page = _pages.firstWhere((p) => p.id == pageId);
    
    final newFolder = FolderModel(
      id: folderId,
      title: folderTitle,
      notes: [],
      updatedAt: DateTime.now(),
    );
    
    page.folders.add(newFolder);
    debugPrint('📁 تم إضافة مجلد جديد: $folderTitle في الصفحة: ${page.title} (ID: $folderId)');
    _savePages();
    if (_usingSqlite) {
      _savePagesToSqlite();
    }
    return folderId;
  }
  
  // إعادة ترتيب المجلدات وحفظ الترتيب
  Future<void> reorderFolders(String pageId, List<String> orderedFolderIds) async {
    final page = getPage(pageId);
    if (page == null) return;
    
    // Map ids to folder models
    final Map<String, FolderModel> map = {for (var f in page.folders) f.id: f};
    page.folders
      ..clear()
      ..addAll(orderedFolderIds.map((id) => map[id]!).toList());
    
    // Persist order with safe save
    try {
      // Persist order by saving pages/folders to SQLite
      await _savePagesToSqlite();
      debugPrint('✅ تم حفظ ترتيب المجلدات للصفحة: $pageId');
    } catch (e) {
      debugPrint('❌ فشل حفظ ترتيب المجلدات: $e');
      // fallback: reload data from DB
      await refreshData();
    }
  }
  
  /// إعادة ترتيب الملاحظات عند السحب والإفلات
  Future<void> reorderNote(String pageId, String folderId, String draggedNoteId, String targetNoteId) async {
    try {
      final folder = getFolder(pageId, folderId);
      if (folder == null) return;
      
      // البحث عن الملاحظتين
      final draggedIndex = folder.notes.indexWhere((n) => n.id == draggedNoteId);
      final targetIndex = folder.notes.indexWhere((n) => n.id == targetNoteId);
      
      if (draggedIndex == -1 || targetIndex == -1) {
        debugPrint('⚠️ لم يتم العثور على الملاحظات للترتيب');
        return;
      }
      
      // إعادة الترتيب في الذاكرة
      final draggedNote = folder.notes.removeAt(draggedIndex);
      folder.notes.insert(targetIndex, draggedNote);
      
      debugPrint('✅ تم إعادة ترتيب الملاحظة من $draggedIndex إلى $targetIndex');
      
      // حفظ الترتيب الجديد
      if (_usingSqlite) {
        try {
          // Update sortOrder for all notes in the folder based on current in-memory order
          for (int i = 0; i < folder.notes.length; i++) {
            final n = folder.notes[i];
            // create updated NoteModel with new sortOrder
            final updated = NoteModel(
              id: n.id,
              type: n.type,
              content: n.content,
              createdAt: n.createdAt,
              colorValue: n.colorValue,
              isPinned: n.isPinned,
              isArchived: n.isArchived,
              isDeleted: n.isDeleted,
              updatedAt: n.updatedAt,
              attachments: n.attachments,
              sortOrder: i,
            );
            // persist update
            await _store.updateNote(updated);
            // also update in-memory instance
            folder.notes[i] = updated;
          }
        } catch (e) {
          debugPrint('❌ Failed to persist note order to SQLite: $e');
        }
      } else {
  // Persist note order to storage
        await _persistAllNotes();
      }
    } catch (e) {
      debugPrint('❌ خطأ في إعادة ترتيب الملاحظة: $e');
    }
  }
  
  
  /// حذف مجلد من صفحة
  void deleteFolder(String pageId, String folderId) {
    try {
      final page = _pages.firstWhere((p) => p.id == pageId);
      page.folders.removeWhere((f) => f.id == folderId);
      _hasNewChanges = true;
      debugPrint('🗑️ تم حذف المجلد: $folderId من الصفحة: ${page.title}');
  _savePages();
    } catch (e) {
      debugPrint('❌ خطأ عند حذف المجلد: $e');
    }
  }

  FolderModel? getFolder(String pageId, String folderId) {
    final p = getPage(pageId);
    if (p == null) return null;
    try {
      return p.folders.firstWhere((f) => f.id == folderId);
    } catch (e) {
      // إذا لم يجد المجلد المطلوب، حاول إرجاع أول مجلد
      if (p.folders.isNotEmpty) {
        return p.folders.first;
      }
      return null;
    }
  }

  Future<bool> saveNoteSimple(String content, {String type = 'simple', int? colorValue, List<String>? attachments}) async {
    debugPrint('NotesRepository: saveNoteSimple called with content="$content"');
    final id = Uuid().v4();
    debugPrint('NotesRepository: generated id = $id');
    
    try {
      // Persist note to SQLite under default p1/f1
      final note = NoteModel(id: id, type: NoteType.text, content: content, colorValue: colorValue, attachments: attachments ?? []);
      final result = await _store.saveNote(note, 'p1', 'f1');
      if (!result.success) {
        debugPrint('NotesRepository: Failed to save note to SQLite: ${result.error}');
        return false;
      }

      // Update in-memory
      var folder = getFolder('p1', 'f1');
      if (folder == null) {
        var page = getPage('p1');
        if (page == null) {
          page = PageModel(id: 'p1', title: 'الصفحة الرئيسية', folders: []);
          _pages.add(page);
        }
        final created = FolderModel(id: 'f1', title: 'عام', notes: [note], updatedAt: DateTime.now());
        page.folders.add(created);
      } else {
        folder.notes.add(note);
      }

      debugPrint('NotesRepository: saveNoteSimple returning true');
      return true;
    } catch (e) {
      debugPrint('NotesRepository: Failed to save note: $e');
      return false;
    }
  }

  Future<String?> saveNoteToFolder(String content, String pageId, String folderId, {String? noteId, String type = 'simple', int? colorValue, List<String>? attachments}) async {
    debugPrint('NotesRepository: saveNoteToFolder called with content="$content", pageId="$pageId", folderId="$folderId", noteId="$noteId"');
    final id = noteId ?? Uuid().v4(); // استخدام noteId الموجود أو إنشاء جديد
    debugPrint('NotesRepository: using id = $id');
    
    try {
      // create note model
      final newNote = NoteModel(id: id, type: NoteType.text, content: content, colorValue: colorValue, attachments: attachments ?? []);

      // save to sqlite
      final result = await _store.saveNote(newNote, pageId, folderId);
      if (!result.success) {
        debugPrint('❌ فشل حفظ الملاحظة إلى SQLite: ${result.error}');
        return null;
      }

      // update memory by reloading folder notes
      final notesResult = await _store.getNotesByFolderId(folderId);
      final folder = getFolder(pageId, folderId);
      if (notesResult.success && notesResult.data != null) {
        if (folder != null) {
          folder.notes.clear();
          folder.notes.addAll(notesResult.data!);
        }
      } else if (folder != null) {
        // fallback: append
        folder.notes.add(newNote);
      }

      _updateFolderTimestamp(pageId, folderId);
      _hasNewChanges = true;
      _printAllFoldersStatus();

      debugPrint('NotesRepository: saveNoteToFolder returning id: $id');
      return id;
    } catch (e) {
      debugPrint('NotesRepository: Failed to save note: $e');
      return null;
    }
  }

  void _printAllFoldersStatus() {
    debugPrint('🗂️ حالة جميع المجلدات:');
    for (final page in _pages) {
      debugPrint('📄 صفحة: ${page.title} (${page.id})');
      for (final folder in page.folders) {
        debugPrint('  📁 مجلد: ${folder.title} (${folder.id}) - عدد الملاحظات: ${folder.notes.length}');
        for (final note in folder.notes) {
          debugPrint('    📝 ملاحظة: ${note.content}');
        }
      }
    }
  }

  void _updateFolderTimestamp(String pageId, String folderId) {
    final page = getPage(pageId);
    if (page != null) {
      final folderIndex = page.folders.indexWhere((f) => f.id == folderId);
      if (folderIndex != -1) {
        // إنشاء مجلد جديد بنفس البيانات لكن بوقت محدث
        final oldFolder = page.folders[folderIndex];
        final updatedFolder = FolderModel(
          id: oldFolder.id,
          title: oldFolder.title,
          notes: oldFolder.notes,
          updatedAt: DateTime.now(),
        );
        page.folders[folderIndex] = updatedFolder;
        debugPrint('⏰ تم تحديث وقت المجلد ${oldFolder.title}');
      }
    }
  }

  // دالة لمسح جميع البيانات المحفوظة (للاختبار) مع نسخة احتياطية
  Future<void> clearAllSavedNotes() async {
    // Remove entire SQLite database and reinitialize empty store
    try {
      await DatabaseHelper.instance.deleteDatabase();
      // Recreate store & reload
      _store = SqliteNotesStore();
      _pages.clear();
      _seed();
      await _savePagesToSqlite();
      debugPrint('🗑️ تم حذف قاعدة البيانات وإعادة الإنشاء (بدء من الصفر)');
    } catch (e) {
      debugPrint('❌ فشل في مسح البيانات: $e');
    }
  }

  // Persist pages and folders structure to SQLite
  Future<void> _savePages() async {
    // Delegate to SQLite-backed saver
    await _savePagesToSqlite();
  }

  // Load pages from SQLite (wrapper)
  Future<void> _loadPages() async {
    final result = await _store.getAllPages();
    if (result.success && result.data != null) {
      _pages.clear();
      _pages.addAll(result.data!);
    }
  }

  // Backup and restore delegate to the SQLite store
  Future<String?> exportBackupJson() async {
    final res = await _store.createFullBackup();
    return res.success ? res.data : null;
  }

  Future<bool> importBackupJson(String jsonStr) async {
    final res = await _store.restoreFromBackup(jsonStr);
    if (res.success) {
      // reload memory
      await _loadFromSqlite();
    }
    return res.success;
  }

  // Note: export/import handled via _store above

  // restoreFromPrefsBackup removed

  // Validate integrity via SQLite store
  Future<bool> validateDataIntegrity() async {
    final res = await _store.validateIntegrity();
    return res.success;
  }

  // Reload in-memory data from SQLite
  Future<void> refreshData() async {
    debugPrint('🔄 إعادة تحميل البيانات من SQLite...');
    await _loadFromSqlite();
    debugPrint('✅ تم إعادة تحميل البيانات بنجاح');
  }

  // Add error recovery system
  // _recoverFromBackup removed

  // Helper to persist the entire notes list from in-memory structure
  // Persist all in-memory notes to SQLite
  Future<void> _persistAllNotes() async {
    // Ensure pages/folders exist in DB
    await _savePagesToSqlite();
    for (final p in _pages) {
      for (final f in p.folders) {
        for (final n in f.notes) {
          try {
            await _store.saveNote(n, p.id, f.id);
          } catch (e) {
            debugPrint('❌ Failed to persist note ${n.id}: $e');
          }
        }
      }
    }
  }

  // Toggle pinned state
  Future<void> togglePin(String pageId, String folderId, String noteId) async {
    final folder = getFolder(pageId, folderId);
    if (folder == null) return;
    final idx = folder.notes.indexWhere((n) => n.id == noteId);
    if (idx == -1) return;
    final old = folder.notes[idx];
    final updated = NoteModel(
      id: old.id,
      type: old.type,
      content: old.content,
      createdAt: old.createdAt,
      colorValue: old.colorValue,
      isPinned: !old.isPinned,
      isArchived: old.isArchived,
      isDeleted: old.isDeleted,
      updatedAt: DateTime.now(),
    );
    folder.notes[idx] = updated;
    await _persistAllNotes();
  }

  Future<void> toggleArchive(String pageId, String folderId, String noteId) async {
    final folder = getFolder(pageId, folderId);
    if (folder == null) return;
    final idx = folder.notes.indexWhere((n) => n.id == noteId);
    if (idx == -1) return;
    final old = folder.notes[idx];
    final updated = NoteModel(
      id: old.id,
      type: old.type,
      content: old.content,
      createdAt: old.createdAt,
      colorValue: old.colorValue,
      isPinned: old.isPinned,
      isArchived: !old.isArchived,
      isDeleted: old.isDeleted,
      updatedAt: DateTime.now(),
    );
    folder.notes[idx] = updated;
    await _persistAllNotes();
  }

  Future<void> deleteNote(String pageId, String folderId, String noteId) async {
    final folder = getFolder(pageId, folderId);
    if (folder == null) return;
    final idx = folder.notes.indexWhere((n) => n.id == noteId);
    if (idx == -1) return;
    final old = folder.notes[idx];
    final updated = NoteModel(
      id: old.id,
      type: old.type,
      content: old.content,
      createdAt: old.createdAt,
      colorValue: old.colorValue,
      isPinned: old.isPinned,
      isArchived: old.isArchived,
      isDeleted: true,
      updatedAt: DateTime.now(),
    );
    folder.notes[idx] = updated;
    await _persistAllNotes();
  }

  Future<void> restoreNote(String pageId, String folderId, String noteId) async {
    final folder = getFolder(pageId, folderId);
    if (folder == null) return;
    final idx = folder.notes.indexWhere((n) => n.id == noteId);
    if (idx == -1) return;
    final old = folder.notes[idx];
    final updated = NoteModel(
      id: old.id,
      type: old.type,
      content: old.content,
      createdAt: old.createdAt,
      colorValue: old.colorValue,
      isPinned: old.isPinned,
      isArchived: old.isArchived,
      isDeleted: false,
      updatedAt: DateTime.now(),
    );
    folder.notes[idx] = updated;
    await _persistAllNotes();
  }

  // Update an existing note's fields and persist
  Future<bool> updateNote(String pageId, String folderId, String noteId, {String? content, int? colorValue, List<String>? attachments, bool? isPinned, bool? isArchived, bool? isDeleted}) async {
    try {
      final folder = getFolder(pageId, folderId);
      if (folder == null) return false;
      final idx = folder.notes.indexWhere((n) => n.id == noteId);
      if (idx == -1) return false;
      final old = folder.notes[idx];
      final updated = NoteModel(
        id: old.id,
        type: old.type,
        content: content ?? old.content,
        createdAt: old.createdAt,
        colorValue: colorValue ?? old.colorValue,
        isPinned: isPinned ?? old.isPinned,
        isArchived: isArchived ?? old.isArchived,
        isDeleted: isDeleted ?? old.isDeleted,
        updatedAt: DateTime.now(),
        attachments: attachments ?? old.attachments,
      );
      folder.notes[idx] = updated;
      _updateFolderTimestamp(pageId, folderId);
      _hasNewChanges = true;
      await _persistAllNotes();
      return true;
    } catch (e) {
      debugPrint('❌ فشل في تحديث الملاحظة: $e');
      return false;
    }
  }

  // retry helper removed

  // _safeSave removed

  // Enhanced save operation for string lists
  // _safeSetStringList and maintenance cleanup removed - SQLite-only codebase
}
