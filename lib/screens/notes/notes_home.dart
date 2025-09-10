import 'package:flutter/material.dart';
import '../../components/top_bar/top_bar.dart';
import '../../repositories/notes_repository.dart';
import '../../components/folder_card/folder_card.dart';
import '../../components/composer_bar/composer_bar.dart';
import 'folder_notes_screen.dart';
import 'all_pages_screen.dart';

class NotesHome extends StatelessWidget {
  const NotesHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final repo = NotesRepository();
    final pages = repo.getPages();
    final current = pages.first;

    return Scaffold(
      appBar: TopBar(
        pages: pages.map((p) => p.title).toList(),
        onMorePressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AllPagesScreen())),
      ),
      body: Column(
        children: [
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              padding: const EdgeInsets.all(12),
              children: current.folders
                  .map((f) => FolderCard(
                      folder: f,
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => FolderNotesScreen(pageId: current.id, folderId: f.id)))) )
                  .toList(),
            ),
          ),
          ComposerBar(onSend: (text) {
            // يمكن إضافة ملاحظة سريعة هنا
          }),
        ],
      ),
    );
  }
}
