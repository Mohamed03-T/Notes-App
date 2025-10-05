import '../models/page_model.dart';
import '../models/folder_model.dart';
import '../models/note_model.dart';
import '../core/database/sqlite_notes_store.dart';
import '../core/database/i_notes_store.dart';
import '../core/database/migration_service.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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
  
  // مفاتيح التخزين مع إصدارات (للترحيل من SharedPreferences)
  static const String _notesKey = 'saved_notes_v2';
  static const String _pagesKey = 'saved_pages_v1';
  static const String _versionKey = 'data_version';
  static const String _backupKey = 'backup_notes_v2';
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
      
      // 🔵 2️⃣ تحقق من حالة الترحيل وتنفيذه إذا لزم الأمر
      final migrationService = MigrationService();
      final migrationStatus = await migrationService.checkMigrationStatus();
      
      debugPrint('📊 حالة الترحيل: $migrationStatus');
      
      if (migrationStatus == MigrationState.pending || migrationStatus == MigrationState.notNeeded) {
        debugPrint('🚀 بدء الترحيل من SharedPreferences إلى SQLite...');
        final result = await migrationService.startMigration();
        
        if (result.success && result.data != null) {
          final report = result.data!;
          debugPrint('✅ نجح الترحيل! Pages: ${report.newPagesCount}, Folders: ${report.newFoldersCount}, Notes: ${report.newNotesCount}');
          _usingSqlite = true;
        } else {
          debugPrint('❌ فشل الترحيل: ${result.error}');
          debugPrint('⚠️ سيستمر استخدام SharedPreferences');
          _usingSqlite = false;
        }
      } else if (migrationStatus == MigrationState.completed) {
        debugPrint('✅ SQLite جاهز للاستخدام (الترحيل مكتمل)');
        _usingSqlite = true;
      } else {
        debugPrint('⚠️ حالة غير متوقعة ($migrationStatus)، سيستمر استخدام SharedPreferences');
        _usingSqlite = false;
      }
      
      // 3️⃣ حمّل البيانات حسب المصدر
      if (_usingSqlite) {
        await _loadFromSqlite();
      } else {
        await _loadFromSharedPreferences();
      }
      
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

  // 🔵 تحميل البيانات من SharedPreferences (طريقة legacy)
  Future<void> _loadFromSharedPreferences() async {
    await _checkAndMigrateData();
    await _loadPages();
    if (_pages.isEmpty) {
      _seed();
    }
    await _loadSavedNotes();
  }

  bool get hasNewChanges => _hasNewChanges;
  
  void markChangesAsViewed() {
    _hasNewChanges = false;
  }

  // تحقق من إصدار البيانات والترحيل إذا لزم الأمر
  Future<void> _checkAndMigrateData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentVersion = prefs.getInt(_versionKey) ?? 1;
      
      debugPrint('🔄 فحص إصدار البيانات: الحالي=$currentVersion, المطلوب=$_currentDataVersion');
      
      if (currentVersion < _currentDataVersion) {
        debugPrint('🔄 بدء ترحيل البيانات من الإصدار $currentVersion إلى $_currentDataVersion');
        await _migrateFromVersion(currentVersion);
        await prefs.setInt(_versionKey, _currentDataVersion);
        debugPrint('✅ تم الترحيل بنجاح إلى الإصدار $_currentDataVersion');
      }
    } catch (e) {
      debugPrint('❌ فشل في فحص/ترحيل البيانات: $e');
    }
  }

  // ترحيل البيانات من إصدار قديم
  Future<void> _migrateFromVersion(int fromVersion) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (fromVersion == 1) {
        // ترحيل من الإصدار 1 إلى 2
        debugPrint('📦 ترحيل البيانات من الإصدار 1 إلى 2');
        
        // نسخ البيانات القديمة إلى نسخة احتياطية
        final oldNotes = prefs.getStringList('saved_notes') ?? [];
        if (oldNotes.isNotEmpty) {
          await prefs.setStringList(_backupKey, oldNotes);
          debugPrint('💾 تم إنشاء نسخة احتياطية من ${oldNotes.length} ملاحظة');
          
          // نسخ البيانات إلى المفتاح الجديد
          await prefs.setStringList(_notesKey, oldNotes);
          debugPrint('✅ تم نسخ البيانات إلى المفتاح الجديد');
        }
      }
    } catch (e) {
      debugPrint('❌ فشل في ترحيل البيانات: $e');
    }
  }

  Future<void> _loadSavedNotes() async {
    try {
      debugPrint('📖 بدء تحميل الملاحظات المحفوظة...');
      
      // التحقق من سلامة البيانات أولاً
      final isDataValid = await validateDataIntegrity();
      if (!isDataValid) {
        debugPrint('⚠️ البيانات قد تكون تالفة، محاولة الاستعادة من النسخة الاحتياطية...');
        final restored = await restoreFromBackup();
        if (!restored) {
          debugPrint('❌ فشل في الاستعادة من النسخة الاحتياطية');
          return;
        }
      }
      
      final prefs = await SharedPreferences.getInstance();
      final notesJson = prefs.getStringList(_notesKey) ?? [];
      debugPrint('📖 تم العثور على ${notesJson.length} ملاحظة محفوظة');
      
      for (final noteStr in notesJson) {
        try {
          final noteData = jsonDecode(noteStr);
          
          // ✅ تحقق من وجود pageId و folderId أولاً
          final pageId = noteData['pageId'];
          final folderId = noteData['folderId'];
          
          // إذا لم تكن موجودة، تخطي الملاحظة مع تحذير
          if (pageId == null || folderId == null) {
            debugPrint('⚠️ تخطي ملاحظة بدون pageId/folderId: ${noteData['content']?.toString().substring(0, 30) ?? 'unknown'}');
            debugPrint('   - pageId: $pageId, folderId: $folderId');
            debugPrint('   - سيتم تجاهل هذه الملاحظة حتى يتم إصلاح البيانات');
            continue;  // تخطي هذه الملاحظة
          }
          
          // استخدم createdAt المخزن إن وُجد للحفاظ على الطابع الزمني الحقيقي للملاحظة
          DateTime? createdAt;
          if (noteData['createdAt'] != null) {
            try {
              createdAt = DateTime.fromMillisecondsSinceEpoch(noteData['createdAt']);
            } catch (_) {
              createdAt = null;
            }
          }

          final note = NoteModel(
            id: noteData['id'],
            type: NoteType.text,
            content: noteData['content'],
            createdAt: createdAt,
            colorValue: noteData['colorValue'] is int
                ? noteData['colorValue']
                : (noteData['colorValue'] is String ? int.tryParse(noteData['colorValue']) : null),
            isPinned: noteData['isPinned'] == true,
            isArchived: noteData['isArchived'] == true,
            isDeleted: noteData['isDeleted'] == true,
            updatedAt: noteData['updatedAt'] != null ? DateTime.fromMillisecondsSinceEpoch(noteData['updatedAt']) : null,
            attachments: (noteData['attachments'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
          );
          
          debugPrint('📝 تحميل ملاحظة: ${note.content} إلى المجلد: $folderId');
          
          var folder = getFolder(pageId, folderId);

          // إذا لم يجد المجلد أو الصفحة، حاول إنشائها تلقائياً بدلاً من تجاهل الملاحظة
          if (folder == null) {
            debugPrint('⚠️ المجلد/الصفحة غير موجودين: إنشاء تلقائي pageId=$pageId, folderId=$folderId');
            // Ensure page exists
            var page = getPage(pageId);
            if (page == null) {
              // Create a page with the provided id
              page = PageModel(id: pageId, title: 'صفحة', folders: []);
              _pages.add(page);
            }
            // Create folder with given id
            final newFolder = FolderModel(id: folderId, title: 'مجلد', notes: [], updatedAt: DateTime.now());
            page.folders.add(newFolder);
            folder = newFolder;
            // Persist the updated pages/folders structure
            _savePages();
          }
          
          if (!folder.notes.any((n) => n.id == note.id)) {
            folder.notes.add(note);
            debugPrint('✅ تم إضافة الملاحظة للمجلد ${folder.title}');
          } else {
            debugPrint('⚠️ الملاحظة موجودة مسبقاً في المجلد');
          }
        } catch (e) {
          debugPrint('❌ خطأ في تحميل ملاحظة: $e');
        }
      }
      debugPrint('📖 انتهى تحميل الملاحظات');
      // بعد تحميل كل الملاحظات، أعد حساب أزمنة التحديث لكل مجلد بناءً على أحدث ملاحظة به
      _recomputeAllFolderTimestamps();
      // تحميل ترتيب المجلدات المحفوظ
      await _loadFolderOrders();
    } catch (e) {
      debugPrint('❌ فشل في تحميل الملاحظات: $e');
    }
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

  // تحميل ترتيب المجلدات المحفوظ
  Future<void> _loadFolderOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      debugPrint('📂 تحميل ترتيب المجلدات المحفوظ...');
      
      for (final page in _pages) {
        final orderKey = 'folder_order_${page.id}';
        final savedOrder = prefs.getStringList(orderKey);
        
        if (savedOrder != null && savedOrder.isNotEmpty) {
          debugPrint('📂 ترتيب محفوظ للصفحة ${page.title}: $savedOrder');
          
          // إعادة ترتيب المجلدات حسب الترتيب المحفوظ
          final Map<String, FolderModel> folderMap = {
            for (var f in page.folders) f.id: f
          };
          
          final reorderedFolders = <FolderModel>[];
          for (final folderId in savedOrder) {
            if (folderMap.containsKey(folderId)) {
              reorderedFolders.add(folderMap[folderId]!);
              folderMap.remove(folderId);
            } else {
              debugPrint('⚠️ مجلد مفقود في الترتيب المحفوظ: $folderId');
            }
          }
          
          // إضافة أي مجلدات جديدة لم تكن في الترتيب المحفوظ
          if (folderMap.isNotEmpty) {
            debugPrint('📂 إضافة مجلدات جديدة: ${folderMap.keys.toList()}');
            reorderedFolders.addAll(folderMap.values);
          }
          
          page.folders.clear();
          page.folders.addAll(reorderedFolders);
          
          debugPrint('✅ تم تحميل ترتيب المجلدات للصفحة: ${page.title}');
        } else {
          debugPrint('📂 لا يوجد ترتيب محفوظ للصفحة: ${page.title}');
        }
      }
    } catch (e) {
      debugPrint('❌ فشل في تحميل ترتيب المجلدات: $e');
    }
  }

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
  // persist pages
  _savePages();
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
  // persist pages (folders changed)
  _savePages();
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
      final success = await _safeSetStringList('folder_order_$pageId', orderedFolderIds);
      if (success) {
        debugPrint('✅ تم حفظ ترتيب المجلدات للصفحة: $pageId');
        // أيضاً احفظ آخر وقت تحديث للترتيب
        await _safeSave('folder_order_timestamp_$pageId', DateTime.now().millisecondsSinceEpoch.toString());
  // persist pages order too
  _savePages();
      } else {
        throw Exception('فشل في حفظ ترتيب المجلدات');
      }
    } catch (e) {
      debugPrint('❌ فشل حفظ ترتيب المجلدات: $e');
      // محاولة استرداد البيانات من النسخة الاحتياطية
      await _recoverFromBackup();
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
      // Save to SharedPreferences
      debugPrint('NotesRepository: getting SharedPreferences instance...');
      final prefs = await SharedPreferences.getInstance();
      debugPrint('NotesRepository: got SharedPreferences instance');
      
      final currentNotes = prefs.getStringList(_notesKey) ?? [];
      debugPrint('NotesRepository: current notes count = ${currentNotes.length}');
      
      // Save under default page/folder p1/f1 to ensure discoverability
      final noteData = {
        'id': id,
        'content': content,
        'type': type,
        'pageId': 'p1',
        'folderId': 'f1',
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'colorValue': colorValue,
        'isPinned': false,
        'isArchived': false,
        'isDeleted': false,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
        'attachments': attachments ?? [],
      };
      debugPrint('NotesRepository: created noteData = $noteData');
      
      currentNotes.add(jsonEncode(noteData));
      debugPrint('NotesRepository: added note to list, new count = ${currentNotes.length}');
      
      await prefs.setStringList(_notesKey, currentNotes);
      debugPrint('NotesRepository: saved to SharedPreferences');
      
      // Also add to in-memory for immediate UI update
  final newNote = NoteModel(id: id, type: NoteType.text, content: content, colorValue: colorValue, attachments: attachments);
      final folder = getFolder('p1', 'f1');
      if (folder != null) {
        folder.notes.add(newNote);
        debugPrint('NotesRepository: added to in-memory folder, new folder notes count = ${folder.notes.length}');
      } else {
        debugPrint('NotesRepository: WARNING - folder not found');
        // If default folder missing, create it to avoid dropped notes
        final page = getPage('p1') ?? PageModel(id: 'p1', title: 'الصفحة الرئيسية', folders: []);
        if (! _pages.contains(page)) _pages.add(page);
        final created = FolderModel(id: 'f1', title: 'عام', notes: [newNote], updatedAt: DateTime.now());
        page.folders.add(created);
        _savePages();
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
      // إنشاء كائن الملاحظة
      final newNote = NoteModel(id: id, type: NoteType.text, content: content, colorValue: colorValue, attachments: attachments);
      
      // 🔵 حفظ إلى SQLite إذا كان مُفعّلاً
      if (_usingSqlite) {
        debugPrint('💾 حفظ الملاحظة إلى SQLite...');
        final result = await _store.saveNote(newNote, pageId, folderId);
        if (!result.success) {
          debugPrint('❌ فشل حفظ الملاحظة إلى SQLite: ${result.error}');
          return null;
        }
        debugPrint('✅ تم حفظ الملاحظة في SQLite');
        
        // إعادة قراءة الملاحظات من SQLite لتحديث الذاكرة
        final notesResult = await _store.getNotesByFolderId(folderId);
        if (notesResult.success && notesResult.data != null) {
          final folder = getFolder(pageId, folderId);
          if (folder != null) {
            folder.notes.clear();
            folder.notes.addAll(notesResult.data!);
            debugPrint('🔄 تم تحديث الذاكرة من SQLite - عدد الملاحظات: ${folder.notes.length}');
          }
        }
        
        return id; // إرجاع معرّف الملاحظة
      } else {
        // استخدام SharedPreferences (طريقة legacy)
        debugPrint('NotesRepository: getting SharedPreferences instance...');
        final prefs = await SharedPreferences.getInstance();
        debugPrint('NotesRepository: got SharedPreferences instance');
        
        final currentNotes = prefs.getStringList(_notesKey) ?? [];
        debugPrint('NotesRepository: current notes count = ${currentNotes.length}');
        
        // البحث عن الملاحظة الموجودة إذا كان noteId موجوداً
        int existingIndex = -1;
        int? existingCreatedAt;
        if (noteId != null) {
          existingIndex = currentNotes.indexWhere((noteStr) {
            try {
              final note = jsonDecode(noteStr);
              if (note['id'] == noteId) {
                existingCreatedAt = note['createdAt'];
                return true;
              }
              return false;
            } catch (e) {
              return false;
            }
          });
        }
        
        final noteData = {
          'id': id,
          'content': content,
          'type': type,
          'pageId': pageId,
          'folderId': folderId,
          'createdAt': existingCreatedAt ?? DateTime.now().millisecondsSinceEpoch,
          'colorValue': colorValue,
          'isPinned': false,
          'isArchived': false,
          'isDeleted': false,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
          'attachments': attachments ?? [],
        };
        debugPrint('NotesRepository: created noteData = $noteData');
        
        if (existingIndex != -1) {
          // تحديث الملاحظة الموجودة
          currentNotes[existingIndex] = jsonEncode(noteData);
          debugPrint('NotesRepository: updated existing note at index $existingIndex');
        } else {
          // إضافة ملاحظة جديدة
          currentNotes.add(jsonEncode(noteData));
          debugPrint('NotesRepository: added new note to list, new count = ${currentNotes.length}');
        }
        
        // حفظ نسخة احتياطية كل 10 ملاحظات
        if (currentNotes.length % 10 == 0) {
          await _createBackup(currentNotes);
        }

        // استخدام الحفظ الآمن مع إعادة المحاولة
        final saveSuccess = await _safeSetStringList(_notesKey, currentNotes);
        if (!saveSuccess) {
          throw Exception('فشل في حفظ البيانات بشكل آمن');
        }
        
        debugPrint('NotesRepository: saved to SharedPreferences successfully');
        
        // تحديث الذاكرة للتحديث الفوري للواجهة (SharedPreferences فقط)
        final folder = getFolder(pageId, folderId);
        if (folder != null) {
          // البحث عن الملاحظة الموجودة في الذاكرة
          final existingNoteIndex = folder.notes.indexWhere((note) => note.id == id);
          if (existingNoteIndex != -1) {
            // تحديث الملاحظة الموجودة
            folder.notes[existingNoteIndex] = newNote;
            debugPrint('NotesRepository: updated existing note in memory at index $existingNoteIndex');
          } else {
            // إضافة ملاحظة جديدة
            folder.notes.add(newNote);
            debugPrint('NotesRepository: added new note to in-memory folder');
          }
          
          // تحديث وقت المجلد
          _updateFolderTimestamp(pageId, folderId);
          // وضع علامة على وجود تغييرات جديدة
          _hasNewChanges = true;
          debugPrint('NotesRepository: folder notes count = ${folder.notes.length}');
          
          // طباعة حالة جميع المجلدات للتشخيص
          _printAllFoldersStatus();
        } else {
          debugPrint('NotesRepository: WARNING - folder not found');
        }
      }
      
      debugPrint('NotesRepository: saveNoteToFolder returning id: $id');
      return id; // إرجاع معرّف الملاحظة
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
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // إنشاء نسخة احتياطية قبل المسح
      final currentNotes = prefs.getStringList(_notesKey) ?? [];
      if (currentNotes.isNotEmpty) {
        await _createBackup(currentNotes);
        debugPrint('💾 تم إنشاء نسخة احتياطية قبل المسح');
      }
      
      await prefs.remove(_notesKey);
      debugPrint('🗑️ تم مسح جميع الملاحظات المحفوظة');
    } catch (e) {
      debugPrint('❌ فشل في مسح الملاحظات: $e');
    }
  }

  // دالة لعرض الملاحظات المحفوظة
  Future<void> debugSavedNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = prefs.getStringList(_notesKey) ?? [];
      debugPrint('🔍 الملاحظات المحفوظة في SharedPreferences:');
      for (int i = 0; i < notesJson.length; i++) {
        final noteData = jsonDecode(notesJson[i]);
        debugPrint('  $i: ${noteData['content']} (مجلد: ${noteData['folderId']})');
      }
    } catch (e) {
      debugPrint('❌ فشل في قراءة الملاحظات المحفوظة: $e');
    }
  }

  // إنشاء نسخة احتياطية من البيانات
  Future<void> _createBackup(List<String> notesData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_backupKey, notesData);
      await prefs.setString('backup_timestamp', DateTime.now().toIso8601String());
      debugPrint('💾 تم إنشاء نسخة احتياطية من ${notesData.length} ملاحظة');
    } catch (e) {
      debugPrint('❌ فشل في إنشاء النسخة الاحتياطية: $e');
    }
  }

  // Persist pages and folders structure (notes kept in _notesKey)
  Future<void> _savePages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pagesData = _pages.map((p) {
        return jsonEncode({
          'id': p.id,
          'title': p.title,
          'folders': p.folders.map((f) => {
            'id': f.id,
            'title': f.title,
            'updatedAt': f.updatedAt.millisecondsSinceEpoch,
            'isPinned': f.isPinned,
          }).toList(),
        });
      }).toList();

      await prefs.setStringList(_pagesKey, pagesData);
      debugPrint('✅ تم حفظ بنية الصفحات/المجلدات ($_pagesKey)');
    } catch (e) {
      debugPrint('❌ فشل في حفظ بنية الصفحات: $e');
    }
  }

  Future<void> _loadPages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pagesData = prefs.getStringList(_pagesKey) ?? [];
      if (pagesData.isEmpty) {
        debugPrint('📄 لا توجد بنية صفحات محفوظة');
        return;
      }

      _pages.clear();
      for (final pStr in pagesData) {
        try {
          final p = jsonDecode(pStr);
          final page = PageModel(id: p['id'], title: p['title'], folders: []);
          final folders = (p['folders'] as List<dynamic>? ) ?? [];
          for (final f in folders) {
            final folder = FolderModel(
              id: f['id'],
              title: f['title'],
              notes: [],
              updatedAt: DateTime.fromMillisecondsSinceEpoch(f['updatedAt'] ?? DateTime.now().millisecondsSinceEpoch),
              isPinned: f['isPinned'] ?? false,
            );
            page.folders.add(folder);
          }
          _pages.add(page);
        } catch (e) {
          debugPrint('⚠️ تخطي صفحة تالفة في التحميل: $e');
        }
      }

      // Ensure default exists
      if (_pages.isEmpty) {
        _seed();
      }

      debugPrint('✅ تم تحميل بنية الصفحات: ${_pages.length} صفحة');
    } catch (e) {
      debugPrint('❌ فشل في تحميل بنية الصفحات: $e');
    }
  }

  // استرداد البيانات من النسخة الاحتياطية
  Future<bool> restoreFromBackup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final backupData = prefs.getStringList(_backupKey);
      
      if (backupData != null && backupData.isNotEmpty) {
        await prefs.setStringList(_notesKey, backupData);
        debugPrint('✅ تم استرداد ${backupData.length} ملاحظة من النسخة الاحتياطية');
        return true;
      } else {
        debugPrint('⚠️ لا توجد نسخة احتياطية متاحة');
        return false;
      }
    } catch (e) {
      debugPrint('❌ فشل في استرداد النسخة الاحتياطية: $e');
      return false;
    }
  }

  // Export full backup (pages structure + notes) as JSON string
  Future<String> exportBackupJson() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notes = prefs.getStringList(_notesKey) ?? [];
      final pages = _pages.map((p) => {
        'id': p.id,
        'title': p.title,
        'folders': p.folders.map((f) => {
          'id': f.id,
          'title': f.title,
          'updatedAt': f.updatedAt.millisecondsSinceEpoch,
          'isPinned': f.isPinned,
        }).toList(),
      }).toList();

      final exportData = {
        'version': _currentDataVersion,
        'pages': pages,
        'notes': notes,
        'timestamp': DateTime.now().toIso8601String(),
      };
      return jsonEncode(exportData);
    } catch (e) {
      debugPrint('❌ فشل في إنشاء JSON للنسخة الاحتياطية: $e');
      rethrow;
    }
  }

  // Import backup JSON string (overwrites current notes/pages)
  Future<bool> importBackupJson(String jsonStr) async {
    try {
      final data = jsonDecode(jsonStr);
      final prefs = await SharedPreferences.getInstance();

      // Replace notes
      final List<dynamic> notesList = data['notes'] ?? [];
      final notesStrings = notesList.map((e) => e.toString()).toList();
      await prefs.setStringList(_notesKey, notesStrings);

      // Replace pages
      final List<dynamic> pagesList = data['pages'] ?? [];
      _pages.clear();
      for (final p in pagesList) {
        final page = PageModel(id: p['id'], title: p['title'], folders: []);
        final folders = (p['folders'] as List<dynamic>?) ?? [];
        for (final f in folders) {
          final folder = FolderModel(
            id: f['id'],
            title: f['title'],
            notes: [],
            updatedAt: DateTime.fromMillisecondsSinceEpoch(f['updatedAt'] ?? DateTime.now().millisecondsSinceEpoch),
            isPinned: f['isPinned'] ?? false,
          );
          page.folders.add(folder);
        }
        _pages.add(page);
      }

      // persist pages
      await _savePages();

      // reload notes into memory structure
      await refreshData();
      debugPrint('✅ تم استيراد النسخة الاحتياطية من JSON');
      return true;
    } catch (e) {
      debugPrint('❌ فشل في استيراد النسخة الاحتياطية من JSON: $e');
      return false;
    }
  }

  // Restore from prefs backup key (backup_notes_v2)
  Future<bool> restoreFromPrefsBackup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final backupData = prefs.getStringList(_backupKey);
      if (backupData == null || backupData.isEmpty) return false;

      await prefs.setStringList(_notesKey, backupData);
      await refreshData();
      debugPrint('✅ تم استعادة الملاحظات من المفتاح $_backupKey');
      return true;
    } catch (e) {
      debugPrint('❌ فشل في استعادة من المفتاح $_backupKey: $e');
      return false;
    }
  }

  // التحقق من سلامة البيانات
  Future<bool> validateDataIntegrity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesData = prefs.getStringList(_notesKey) ?? [];
      
      int validNotes = 0;
      int corruptedNotes = 0;
      
      for (final noteStr in notesData) {
        try {
          final noteData = jsonDecode(noteStr);
          if (noteData['id'] != null && noteData['content'] != null) {
            validNotes++;
          } else {
            corruptedNotes++;
          }
        } catch (e) {
          corruptedNotes++;
        }
      }
      
      debugPrint('🔍 فحص سلامة البيانات: صالحة=$validNotes، تالفة=$corruptedNotes');
      
      // إذا كان أكثر من 10% من البيانات تالفة، أعتبر البيانات غير سليمة
      final totalNotes = validNotes + corruptedNotes;
      if (totalNotes > 0 && (corruptedNotes / totalNotes) > 0.1) {
        debugPrint('⚠️ البيانات قد تكون تالفة: ${(corruptedNotes / totalNotes * 100).toStringAsFixed(1)}% تالفة');
        return false;
      }
      
      return true;
    } catch (e) {
      debugPrint('❌ فشل في فحص سلامة البيانات: $e');
      return false;
    }
  }

  // دالة لإعادة تحميل البيانات من التخزين المحلي
  Future<void> refreshData() async {
    debugPrint('🔄 إعادة تحميل البيانات...');
    
    // مسح البيانات الحالية
    for (final page in _pages) {
      for (final folder in page.folders) {
        folder.notes.clear();
      }
    }
    
    // إعادة تحميل الملاحظات من SharedPreferences
    await _loadSavedNotes();
    // ملاحظة: _loadFolderOrders تم استدعاؤها بالفعل في _loadSavedNotes
    debugPrint('✅ تم إعادة تحميل البيانات بنجاح');
  }

  // Add error recovery system
  Future<bool> _recoverFromBackup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final backupData = prefs.getString('${_notesKey}_backup');
      
      if (backupData != null && backupData.isNotEmpty) {
        await prefs.setString(_notesKey, backupData);
        debugPrint('✅ تم استرداد البيانات من النسخة الاحتياطية');
        return true;
      }
    } catch (e) {
      debugPrint('❌ فشل في استرداد البيانات من النسخة الاحتياطية: $e');
    }
    return false;
  }

  // Helper to persist the entire notes list from in-memory structure
  Future<void> _persistAllNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allNotes = <String>[];
      for (final p in _pages) {
        for (final f in p.folders) {
          for (final n in f.notes) {
            final noteData = {
              'id': n.id,
              'content': n.content,
              'type': 'simple',
              'pageId': p.id,
              'folderId': f.id,
              'createdAt': n.createdAt.millisecondsSinceEpoch,
              'colorValue': n.colorValue,
              'isPinned': n.isPinned,
              'isArchived': n.isArchived,
              'isDeleted': n.isDeleted,
              'updatedAt': n.updatedAt?.millisecondsSinceEpoch ?? n.createdAt.millisecondsSinceEpoch,
              'attachments': n.attachments ?? [],
            };
            allNotes.add(jsonEncode(noteData));
          }
        }
      }
      await prefs.setStringList(_notesKey, allNotes);
      debugPrint('✅ تم حفظ جميع الملاحظات (${allNotes.length})');
    } catch (e) {
      debugPrint('❌ فشل في حفظ جميع الملاحظات: $e');
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

  // Add retry mechanism for critical operations
  Future<T?> _retryOperation<T>(Future<T> Function() operation, {int maxRetries = 3}) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        return await operation();
      } catch (e) {
        debugPrint('❌ محاولة $attempt فشلت: $e');
        if (attempt == maxRetries) {
          debugPrint('💀 فشل في العملية بعد $maxRetries محاولات');
          rethrow;
        }
        await Future.delayed(Duration(milliseconds: 100 * attempt));
      }
    }
    return null;
  }

  // Enhanced save operation with retry and validation
  Future<bool> _safeSave(String key, String data) async {
    return await _retryOperation(() async {
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.setString(key, data);
      
      // Verify the save was successful
      final savedData = prefs.getString(key);
      if (savedData != data) {
        throw Exception('فشل في التحقق من حفظ البيانات');
      }
      
      debugPrint('✅ تم حفظ البيانات بنجاح للمفتاح: $key');
      return success;
    }) ?? false;
  }

  // Enhanced save operation for string lists
  Future<bool> _safeSetStringList(String key, List<String> data) async {
    return await _retryOperation(() async {
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.setStringList(key, data);
      
      // Verify the save was successful
      final savedData = prefs.getStringList(key) ?? [];
      if (savedData.length != data.length) {
        throw Exception('فشل في التحقق من حفظ البيانات - طول القائمة مختلف');
      }
      
      // Quick verification of a few items
      for (int i = 0; i < data.length && i < 3; i++) {
        if (savedData[i] != data[i]) {
          throw Exception('فشل في التحقق من حفظ البيانات - محتوى مختلف');
        }
      }
      
      debugPrint('✅ تم حفظ قائمة البيانات بنجاح للمفتاح: $key (${data.length} عنصر)');
      return success;
    }) ?? false;
  }

  // Enhanced data cleanup with protection
  Future<void> performMaintenanceCleanup() async {
    try {
      debugPrint('🧹 بدء تنظيف البيانات...');
      
      // Create a comprehensive backup before cleanup
      final prefs = await SharedPreferences.getInstance();
      final currentNotes = prefs.getStringList(_notesKey) ?? [];
      await _createBackup(currentNotes);
      
      // Remove old temporary data
      final allKeys = prefs.getKeys();
      final keysToRemove = allKeys.where((key) => 
        key.startsWith('temp_') || 
        key.startsWith('cache_') ||
        key.endsWith('_old')
      ).toList();
      
      for (final key in keysToRemove) {
        await prefs.remove(key);
        debugPrint('🗑️ تم حذف البيانات المؤقتة: $key');
      }
      
      // Validate data integrity after cleanup
      final isValid = await validateDataIntegrity();
      if (!isValid) {
        debugPrint('⚠️ تم اكتشاف مشاكل في البيانات بعد التنظيف');
        await _recoverFromBackup();
      }
      
      debugPrint('✅ تم انتهاء تنظيف البيانات بنجاح');
    } catch (e) {
      debugPrint('❌ فشل في تنظيف البيانات: $e');
    }
  }
}
