import '../models/page_model.dart';
import '../models/folder_model.dart';
import '../models/note_model.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NotesRepository {
  // Keep an in-memory seed for UI, but persist notes to local storage
  final List<PageModel> _pages = [];
  static const String _notesKey = 'saved_notes';

  NotesRepository() {
    _seed();
    _loadSavedNotes();
  }

  Future<void> _loadSavedNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = prefs.getStringList(_notesKey) ?? [];
      
      for (final noteStr in notesJson) {
        final noteData = jsonDecode(noteStr);
        final note = NoteModel(
          id: noteData['id'],
          type: NoteType.text,
          content: noteData['content'],
        );
        
        final folder = getFolder('p1', 'f1');
        if (folder != null && !folder.notes.any((n) => n.id == note.id)) {
          folder.notes.add(note);
        }
      }
    } catch (e) {
      debugPrint('Failed to load notes: $e');
    }
  }

  void _seed() {
    final note1 = NoteModel(id: 'n1', type: NoteType.text, content: 'Hello from note 1');
    final note2 = NoteModel(id: 'n2', type: NoteType.text, content: 'Second note');

    final folder = FolderModel(id: 'f1', title: 'General', notes: [note1, note2]);
    final page = PageModel(id: 'p1', title: 'Personal', folders: [folder]);
    _pages.add(page);
  }

  List<PageModel> getPages() => _pages;

  PageModel? getPage(String id) => _pages.firstWhere((p) => p.id == id, orElse: () => _pages.first);

  FolderModel? getFolder(String pageId, String folderId) {
    final p = getPage(pageId);
    if (p == null) return null;
    return p.folders.firstWhere((f) => f.id == folderId, orElse: () => p.folders.first);
  }

  Future<bool> saveNoteSimple(String content, {String type = 'simple'}) async {
    final id = Uuid().v4();
    try {
      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final currentNotes = prefs.getStringList(_notesKey) ?? [];
      
      final noteData = {
        'id': id,
        'content': content,
        'type': type,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      };
      
      currentNotes.add(jsonEncode(noteData));
      await prefs.setStringList(_notesKey, currentNotes);
      
      // Also add to in-memory for immediate UI update
      final newNote = NoteModel(id: id, type: NoteType.text, content: content);
      final folder = getFolder('p1', 'f1');
      if (folder != null) {
        folder.notes.add(newNote);
      }
      
      return true;
    } catch (e) {
      debugPrint('Failed to save note: $e');
      return false;
    }
  }
}
