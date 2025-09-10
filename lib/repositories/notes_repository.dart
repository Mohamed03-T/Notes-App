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

  Future<void> _loadSavedNotes() async {
    try {
      debugPrint('📖 بدء تحميل الملاحظات المحفوظة...');
      final prefs = await SharedPreferences.getInstance();
      final notesJson = prefs.getStringList(_notesKey) ?? [];
      debugPrint('📖 تم العثور على ${notesJson.length} ملاحظة محفوظة');
      
      for (final noteStr in notesJson) {
        try {
          final noteData = jsonDecode(noteStr);
          final note = NoteModel(
            id: noteData['id'],
            type: NoteType.text,
            content: noteData['content'],
          );
          
          // Check if note has folder info, otherwise default to first folder
          final pageId = noteData['pageId'] ?? 'p1';
          final folderId = noteData['folderId'] ?? 'f1';
          
          debugPrint('📝 تحميل ملاحظة: ${note.content} إلى المجلد: $folderId');
          
          final folder = getFolder(pageId, folderId);
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
    } catch (e) {
      debugPrint('❌ فشل في تحميل الملاحظات: $e');
    }
  }

  void _seed() {
    // تحقق من وجود البيانات أولاً
    if (_pages.isNotEmpty) {
      return;
    }

    // إنشاء الصفحات المختلفة
    _createPersonalPage();
    _createWorkPage();
    _createStudyPage();
    _createProjectsPage();
    _createHealthPage();
    
    debugPrint('📋 تم إنشاء ${_pages.length} صفحات تجريبية');
  }

  void _createPersonalPage() {
    final note1 = NoteModel(id: 'n1', type: NoteType.text, content: 'مرحباً من الملاحظة الأولى');
    final note2 = NoteModel(id: 'n2', type: NoteType.text, content: 'هذه ملاحظة تجريبية ثانية');

    final now = DateTime.now();
    final folder1 = FolderModel(
      id: 'f1', 
      title: 'العام', 
      notes: [note1, note2],
      updatedAt: now.subtract(const Duration(hours: 2)),
    );
    final folder2 = FolderModel(
      id: 'f2', 
      title: 'أفكار', 
      notes: [],
      updatedAt: now.subtract(const Duration(days: 1)),
    );
    final folder3 = FolderModel(
      id: 'f3', 
      title: 'مهام', 
      notes: [],
      updatedAt: now.subtract(const Duration(hours: 6)),
    );
    final folder4 = FolderModel(
      id: 'f4', 
      title: 'مذكرات', 
      notes: [],
      updatedAt: now.subtract(const Duration(minutes: 30)),
    );
    
    final page = PageModel(id: 'p1', title: 'شخصي', folders: [folder1, folder2, folder3, folder4]);
    _pages.add(page);
  }

  void _createWorkPage() {
    final now = DateTime.now();
    final workNote1 = NoteModel(id: 'wn1', type: NoteType.text, content: 'اجتماع مع الفريق غداً');
    final workNote2 = NoteModel(id: 'wn2', type: NoteType.text, content: 'مراجعة التقرير الشهري');
    final workNote3 = NoteModel(id: 'wn3', type: NoteType.text, content: 'تطوير الميزة الجديدة');
    
    final meetingsFolder = FolderModel(
      id: 'wf1',
      title: 'اجتماعات',
      notes: [workNote1],
      updatedAt: now.subtract(const Duration(minutes: 15)), // تحديث حديث
    );
    final tasksFolder = FolderModel(
      id: 'wf2',
      title: 'مهام العمل',
      notes: [workNote2, workNote3],
      updatedAt: now.subtract(const Duration(hours: 1)),
    );
    final projectsFolder = FolderModel(
      id: 'wf3',
      title: 'مشاريع',
      notes: [],
      updatedAt: now.subtract(const Duration(days: 2)),
    );
    
    final workPage = PageModel(id: 'p2', title: 'العمل', folders: [meetingsFolder, tasksFolder, projectsFolder]);
    _pages.add(workPage);
  }

  void _createStudyPage() {
    final now = DateTime.now();
    final studyNote1 = NoteModel(id: 'sn1', type: NoteType.text, content: 'مراجعة الفصل الثالث');
    
    final notesFolder = FolderModel(
      id: 'sf1',
      title: 'ملاحظات الدراسة',
      notes: [studyNote1],
      updatedAt: now.subtract(const Duration(hours: 4)),
    );
    final homeworkFolder = FolderModel(
      id: 'sf2',
      title: 'واجبات',
      notes: [],
      updatedAt: now.subtract(const Duration(days: 1)),
    );
    final examsFolder = FolderModel(
      id: 'sf3',
      title: 'امتحانات',
      notes: [],
      updatedAt: now.subtract(const Duration(hours: 8)),
    );
    
    final studyPage = PageModel(id: 'p3', title: 'الدراسة', folders: [notesFolder, homeworkFolder, examsFolder]);
    _pages.add(studyPage);
  }

  void _createProjectsPage() {
    final now = DateTime.now();
    
    final appDevFolder = FolderModel(
      id: 'pf1',
      title: 'تطوير التطبيقات',
      notes: [],
      updatedAt: now.subtract(const Duration(days: 3)),
    );
    final webDevFolder = FolderModel(
      id: 'pf2',
      title: 'تطوير المواقع',
      notes: [],
      updatedAt: now.subtract(const Duration(hours: 12)),
    );
    
    final projectsPage = PageModel(id: 'p4', title: 'المشاريع', folders: [appDevFolder, webDevFolder]);
    _pages.add(projectsPage);
  }

  void _createHealthPage() {
    final now = DateTime.now();
    
    final workoutFolder = FolderModel(
      id: 'hf1',
      title: 'تمارين',
      notes: [],
      updatedAt: now.subtract(const Duration(hours: 18)),
    );
    final dietFolder = FolderModel(
      id: 'hf2',
      title: 'نظام غذائي',
      notes: [],
      updatedAt: now.subtract(const Duration(days: 2)),
    );
    
    final healthPage = PageModel(id: 'p5', title: 'الصحة', folders: [workoutFolder, dietFolder]);
    _pages.add(healthPage);
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

  PageModel? getPage(String id) => _pages.firstWhere((p) => p.id == id, orElse: () => _pages.first);

  FolderModel? getFolder(String pageId, String folderId) {
    final p = getPage(pageId);
    if (p == null) return null;
    return p.folders.firstWhere((f) => f.id == folderId, orElse: () => p.folders.first);
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
