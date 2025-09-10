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

    final note1 = NoteModel(id: 'n1', type: NoteType.text, content: 'Hello from note 1');
    final note2 = NoteModel(id: 'n2', type: NoteType.text, content: 'Second note');

    final folder1 = FolderModel(id: 'f1', title: 'العام', notes: [note1, note2]);
    final folder2 = FolderModel(id: 'f2', title: 'أفكار', notes: []);
    final folder3 = FolderModel(id: 'f3', title: 'مهام', notes: []);
    final folder4 = FolderModel(id: 'f4', title: 'مذكرات', notes: []);
    
    final page = PageModel(id: 'p1', title: 'شخصي', folders: [folder1, folder2, folder3, folder4]);
    _pages.add(page);
    
    debugPrint('📋 تم إنشاء البيانات التجريبية');
  }

  List<PageModel> getPages() => _pages;

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
}
