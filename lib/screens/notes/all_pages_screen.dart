import 'package:flutter/material.dart';
import '../../repositories/notes_repository.dart';
import '../../components/page_card/page_card.dart';
import 'page_folders_screen.dart';

class AllPagesScreen extends StatelessWidget {
  const AllPagesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final repo = NotesRepository();
    final pages = repo.getPages();
    return Scaffold(
      appBar: AppBar(title: const Text('All Pages')),
      body: ListView(
        children: pages
            .map((p) => PageCard(
                title: p.title,
                foldersCount: p.folders.length,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PageFoldersScreen(pageId: p.id)),
                  );
                }))
            .toList(),
      ),
      floatingActionButton: FloatingActionButton(onPressed: () {}, child: const Icon(Icons.add)),
    );
  }
}
