import '../models/page_model.dart';
import '../models/folder_model.dart';
import '../models/note_model.dart';
// ...existing code...

class NotesRepository {
  // Simple in-memory mock
  final List<PageModel> _pages = [];

  NotesRepository() {
    _seed();
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
}
