import 'package:flutter/material.dart';
import '../../components/top_bar/top_bar.dart';
import '../../repositories/notes_repository.dart';
import '../../components/folder_card/folder_card.dart';
import '../../models/page_model.dart';
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
  List<PageModel> cachedSortedPages = [];
  DateTime lastSortTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    repo = NotesRepository();
    _updateSortedPages();
  }

  void _updateSortedPages() {
    cachedSortedPages = repo.getPagesSortedByActivity();
    lastSortTime = DateTime.now();
    debugPrint('🔄 تم تحديث ترتيب الصفحات');
  }

  void _selectPage(int index) {
    setState(() {
      currentPageIndex = index;
    });
  }

  int _getIndexInSortedList(PageModel currentPage, List<PageModel> sortedPages) {
    final index = sortedPages.indexWhere((p) => p.id == currentPage.id);
    return index >= 0 ? index : 0;
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
    final allPages = repo.getPages();
    final sortedPages = repo.getPagesSortedByActivity();
    
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
        pages: sortedPages.map((p) => p.title).toList(),
        currentPageIndex: _getIndexInSortedList(current, sortedPages),
        onPageSelected: (index) {
          // العثور على الصفحة المختارة في القائمة الأصلية
          final selectedPage = sortedPages[index];
          final originalIndex = allPages.indexWhere((p) => p.id == selectedPage.id);
          _selectPage(originalIndex);
        },
        onMorePressed: _openAllPagesScreen,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // إعادة تحميل البيانات من التخزين المحلي
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
                    // إعادة تحميل البيانات لتحديث أوقات التعديل والملاحظات الجديدة
                    await repo.refreshData();
                    setState(() {});
                  }))
              .toList(),
        ),
      ),
    );
  }
}
