import '../models/page_model.dart';
import '../models/folder_model.dart';
import '../models/note_model.dart';
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

  // Keep an in-memory seed for UI, but persist notes to local storage
  final List<PageModel> _pages = [];
  static const String _notesKey = 'saved_notes';
  bool _isInitialized = false;
  bool _hasNewChanges = false; // متغير لتتبع التغييرات الجديدة

  NotesRepository._internal();

  // للاستخدام المباشر (سيعمل بالبيانات التجريبية حتى ينتهي التحميل)
  factory NotesRepository() {
    if (_instance == null) {
      _instance = NotesRepository._internal();
      _instance!._seed();
      _instance!._loadSavedNotes();
    }
    return _instance!;
  }

  Future<void> _initialize() async {
    if (!_isInitialized) {
      _seed();
      await _loadSavedNotes();
      _isInitialized = true;
    }
  }

  bool get hasNewChanges => _hasNewChanges;
  
  void markChangesAsViewed() {
    _hasNewChanges = false;
  }

  Future<void> _loadSavedNotes() async {
    try {
      debugPrint('📖 بدء تحميل الملاحظات المحفوظة...');
      final prefs = await SharedPreferences.getInstance();
      final notesJson = prefs.getStringList(_notesKey) ?? [];
      debugPrint('📖 تم العثور على ${notesJson.length} ملاحظة محفوظة');
      
      for (final noteStr in notesJson) {
        try {
          final noteData = jsonDecode(noteStr);
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
          );
          
          // Check if note has folder info, otherwise default to first folder
          final pageId = noteData['pageId'] ?? 'p1';
          final folderId = noteData['folderId'] ?? 'f1';
          
          debugPrint('📝 تحميل ملاحظة: ${note.content} إلى المجلد: $folderId');
          
          var folder = getFolder(pageId, folderId);
          
          // إذا لم يجد المجلد أو الصفحة، حاول إنشاء صفحة ومجلد افتراضيين
          if (folder == null) {
            debugPrint('⚠️ المجلد غير موجود، سيتم إنشاء مجلد افتراضي');
            // إنشاء صفحة افتراضية إذا لم تكن موجودة
            if (_pages.isEmpty) {
              final defaultPageId = addNewPage('صفحة افتراضية');
              final defaultFolderId = addNewFolder(defaultPageId, 'الملاحظات');
              folder = getFolder(defaultPageId, defaultFolderId);
            } else {
              // إنشاء مجلد افتراضي في أول صفحة
              final firstPage = _pages.first;
              if (firstPage.folders.isEmpty) {
                final defaultFolderId = addNewFolder(firstPage.id, 'الملاحظات');
                folder = getFolder(firstPage.id, defaultFolderId);
              } else {
                folder = firstPage.folders.first;
              }
            }
          }
          
          if (folder != null && !folder.notes.any((n) => n.id == note.id)) {
            folder.notes.add(note);
            debugPrint('✅ تم إضافة الملاحظة للمجلد ${folder.title}');
          } else {
            debugPrint('⚠️ المجلد غير موجود أو الملاحظة موجودة مسبقاً');
          }
        } catch (e) {
          debugPrint('❌ خطأ في تحميل ملاحظة: $e');
        }
      }
      debugPrint('📖 انتهى تحميل الملاحظات');
      // بعد تحميل كل الملاحظات، أعد حساب أزمنة التحديث لكل مجلد بناءً على أحدث ملاحظة به
      _recomputeAllFolderTimestamps();
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

  void _seed() {
    // تحقق من وجود البيانات أولاً
    if (_pages.isNotEmpty) {
      return;
    }

    // لا توجد بيانات افتراضية - التطبيق يبدأ فارغاً
    debugPrint('📋 التطبيق يبدأ بدون بيانات افتراضية');
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
    return folderId;
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

  Future<bool> saveNoteSimple(String content, {String type = 'simple'}) async {
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
      
      final noteData = {
        'id': id,
        'content': content,
        'type': type,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      };
      debugPrint('NotesRepository: created noteData = $noteData');
      
      currentNotes.add(jsonEncode(noteData));
      debugPrint('NotesRepository: added note to list, new count = ${currentNotes.length}');
      
      await prefs.setStringList(_notesKey, currentNotes);
      debugPrint('NotesRepository: saved to SharedPreferences');
      
      // Also add to in-memory for immediate UI update
      final newNote = NoteModel(id: id, type: NoteType.text, content: content);
      final folder = getFolder('p1', 'f1');
      if (folder != null) {
        folder.notes.add(newNote);
        debugPrint('NotesRepository: added to in-memory folder, new folder notes count = ${folder.notes.length}');
      } else {
        debugPrint('NotesRepository: WARNING - folder not found');
      }
      
      debugPrint('NotesRepository: saveNoteSimple returning true');
      return true;
    } catch (e) {
      debugPrint('NotesRepository: Failed to save note: $e');
      return false;
    }
  }

  Future<bool> saveNoteToFolder(String content, String pageId, String folderId, {String type = 'simple'}) async {
    debugPrint('NotesRepository: saveNoteToFolder called with content="$content", pageId="$pageId", folderId="$folderId"');
    final id = Uuid().v4();
    debugPrint('NotesRepository: generated id = $id');
    
    try {
      // Save to SharedPreferences with folder info
      debugPrint('NotesRepository: getting SharedPreferences instance...');
      final prefs = await SharedPreferences.getInstance();
      debugPrint('NotesRepository: got SharedPreferences instance');
      
      final currentNotes = prefs.getStringList(_notesKey) ?? [];
      debugPrint('NotesRepository: current notes count = ${currentNotes.length}');
      
      final noteData = {
        'id': id,
        'content': content,
        'type': type,
        'pageId': pageId,
        'folderId': folderId,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      };
      debugPrint('NotesRepository: created noteData = $noteData');
      
      currentNotes.add(jsonEncode(noteData));
      debugPrint('NotesRepository: added note to list, new count = ${currentNotes.length}');
      
      await prefs.setStringList(_notesKey, currentNotes);
      debugPrint('NotesRepository: saved to SharedPreferences successfully');
      
      // Also add to in-memory for immediate UI update
      final newNote = NoteModel(id: id, type: NoteType.text, content: content);
      final folder = getFolder(pageId, folderId);
      if (folder != null) {
        folder.notes.add(newNote);
        // تحديث وقت المجلد
        _updateFolderTimestamp(pageId, folderId);
        // وضع علامة على وجود تغييرات جديدة
        _hasNewChanges = true;
        debugPrint('NotesRepository: added to in-memory folder, new folder notes count = ${folder.notes.length}');
        
        // طباعة حالة جميع المجلدات للتشخيص
        _printAllFoldersStatus();
      } else {
        debugPrint('NotesRepository: WARNING - folder not found');
      }
      
      debugPrint('NotesRepository: saveNoteToFolder returning true');
      return true;
    } catch (e) {
      debugPrint('NotesRepository: Failed to save note: $e');
      return false;
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

  // دالة لمسح جميع البيانات المحفوظة (للاختبار)
  Future<void> clearAllSavedNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
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
    debugPrint('✅ تم إعادة تحميل البيانات بنجاح');
  }
}
