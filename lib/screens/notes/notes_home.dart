import 'package:flutter/material.dart';
import '../../components/top_bar/top_bar.dart';
import '../../repositories/notes_repository.dart';
import '../../components/folder_card/folder_card.dart';
import 'folder_notes_screen.dart';
import 'all_pages_screen.dart';

class NotesHome extends StatefulWidget {
  const NotesHome({Key? key}) : super(key: key);

  @override
  _NotesHomeState createState() => _NotesHomeState();
}

class _NotesHomeState extends State<NotesHome> {
  late NotesRepository repo;

  @override
  void initState() {
    super.initState();
    repo = NotesRepository();
  }

  @override
  Widget build(BuildContext context) {
    final pages = repo.getPages();
    final current = pages.first;

    return Scaffold(
      appBar: TopBar(
        pages: pages.map((p) => p.title).toList(),
        onMorePressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AllPagesScreen())),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // إعادة تحميل البيانات
          setState(() {
            repo = NotesRepository();
          });
        },
        child: GridView.count(
          crossAxisCount: 2,
          padding: const EdgeInsets.all(12),
          childAspectRatio: 0.8, // تعديل النسبة لإعطاء مساحة أكبر للمعاينة
          children: current.folders
              .map((f) => FolderCard(
                  folder: f,
                  onTap: () async {
                    await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => FolderNotesScreen(pageId: current.id, folderId: f.id)));
                    // تحديث الواجهة عند العودة
                    setState(() {});
                  }))
              .toList(),
        ),
      ),
    );
  }
}
