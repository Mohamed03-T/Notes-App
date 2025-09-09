import 'package:flutter/material.dart';
import '../../repositories/notes_repository.dart';
import '../../components/note_card/note_card.dart';
import '../../components/composer_bar/composer_bar.dart';
import 'add_note_screen.dart';

class FolderNotesScreen extends StatelessWidget {
  final String pageId;
  final String folderId;

  const FolderNotesScreen({Key? key, required this.pageId, required this.folderId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final repo = NotesRepository();
    final folder = repo.getFolder(pageId, folderId)!;
    return Scaffold(
      appBar: AppBar(title: Text(folder.title)),
      body: Column(
        children: [
          Expanded(child: ListView(children: folder.notes.map((n) => NoteCard(note: n)).toList())),
          ComposerBar(onSend: (text) {}),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddNoteScreen())),
        child: const Icon(Icons.add),
      ),
    );
  }
}
