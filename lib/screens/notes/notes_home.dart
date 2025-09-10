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
  int currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    repo = NotesRepository();
  }

  void _selectPage(int index) {
    setState(() {
      currentPageIndex = index;
    });
  }

  void _openAllPagesScreen() async {
    final selectedPageIndex = await Navigator.push<int>(
      context, 
      MaterialPageRoute(builder: (_) => const AllPagesScreen())
    );
    
    if (selectedPageIndex != null) {
      setState(() {
        currentPageIndex = selectedPageIndex;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final allPages = repo.getPages(); // استخدام الترتيب الأصلي الثابت
    
    // التأكد من أن الفهرس صحيح
    if (currentPageIndex >= allPages.length) {
      currentPageIndex = 0;
    }
    
    final current = allPages.isNotEmpty ? allPages[currentPageIndex] : null;

    if (current == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('لا توجد صفحات')),
        body: const Center(child: Text('لا توجد صفحات متاحة')),
      );
    }

    return Scaffold(
      appBar: TopBar(
        pages: allPages.map((p) => p.title).toList(), // الترتيب الأصلي
        currentPageIndex: currentPageIndex, // الفهرس الحقيقي
        onPageSelected: _selectPage, // التنقل العادي
        onMorePressed: _openAllPagesScreen,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // إعادة تحميل البيانات من التخزين المحلي فقط
          await repo.refreshData();
          setState(() {});
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
                    
                    // فقط إعادة تحميل البيانات، بدون تغيير الترتيب
                    await repo.refreshData();
                    setState(() {});
                  }))
              .toList(),
        ),
      ),
    );
  }
}
