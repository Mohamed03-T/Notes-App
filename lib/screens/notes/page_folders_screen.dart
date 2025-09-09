import 'package:flutter/material.dart';
import '../../repositories/notes_repository.dart';
import '../../components/folder_card/folder_card.dart';

class PageFoldersScreen extends StatelessWidget {
  final String pageId;

  const PageFoldersScreen({Key? key, required this.pageId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final repo = NotesRepository();
    final page = repo.getPage(pageId)!;
    return Scaffold(
      appBar: AppBar(title: Text(page.title)),
      body: ListView(children: page.folders.map((f) => FolderCard(folder: f)).toList()),
    );
  }
}
