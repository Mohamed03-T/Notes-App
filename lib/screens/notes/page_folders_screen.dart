import 'package:flutter/material.dart';
import '../../repositories/notes_repository.dart';
import '../../components/folder_card/folder_card.dart';
import '../../core/layout/layout_helpers.dart';
import '../../utils/responsive.dart';

class PageFoldersScreen extends StatelessWidget {
  final String pageId;

  const PageFoldersScreen({Key? key, required this.pageId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final repo = NotesRepository();
    final page = repo.getPage(pageId)!;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(title: Text(page.title, style: TextStyle(fontSize: Layout.titleFont(context)))),
      body: Padding(
        padding: EdgeInsets.all(Layout.horizontalPadding(context)),
        child: width > 800
          ? GridView.count(
              crossAxisCount: 3,
              crossAxisSpacing: Responsive.wp(context, 2),
              mainAxisSpacing: Responsive.hp(context, 1.8),
              childAspectRatio: 0.92,
              children: page.folders.map((f) => FolderCard(folder: f)).toList(),
            )
          : ListView(
              children: page.folders.map((f) => Padding(
                padding: EdgeInsets.only(bottom: Layout.sectionSpacing(context) * 0.6),
                child: FolderCard(folder: f),
              )).toList(),
            ),
      ),
    );
  }
}
