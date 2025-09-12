import 'package:flutter/material.dart';
import '../../components/top_bar/top_bar.dart';
import '../../repositories/notes_repository.dart';
import '../../components/folder_card/folder_card.dart';
import 'folder_notes_screen.dart';
import 'all_pages_screen.dart';
import 'add_folder_screen.dart';
import 'add_page_screen.dart';

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
    debugPrint('🔄 تم اختيار الصفحة بالفهرس: $index');
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

  void _addNewPage() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const AddPageScreen()),
    );
    
    if (result != null) {
      // تحديث الشاشة وانتقل إلى الصفحة الجديدة
      final allPages = repo.getPages();
      final newPageIndex = allPages.indexWhere((page) => page.id == result);
      if (newPageIndex != -1) {
        setState(() {
          currentPageIndex = newPageIndex;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
  final allPages = repo.getPages(); // ترتيب الصفحات الأصلي
  // إذا كانت هناك تغييرات جديدة، استخدم الترتيب حسب النشاط لعرض الشرائح
  final bool useSorted = repo.hasNewChanges;
  final sortedPages = useSorted ? repo.getPagesSortedByActivity() : allPages;
    
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

  debugPrint('🔍 الصفحة الحالية: ${current.title} (فهرس: $currentPageIndex)');
  debugPrint('🔍 استخدام الترتيب المصنف؟ $useSorted');

    return Scaffold(
      appBar: TopBar(
        // إذا كنا نستخدم الترتيب المصنّف، أعرض عناوين الصفحات المصنفة
        pages: (useSorted ? sortedPages : allPages).map((p) => p.title).toList(),
        // بناء خريطة من مواضع العرض إلى المواضع الأصلية بحيث لا نخسر الفهرس الحقيقي
        originalIndices: useSorted ? List.generate(sortedPages.length, (i) => allPages.indexWhere((p) => p.id == sortedPages[i].id)) : null,
        currentPageIndex: currentPageIndex, // الفهرس الحقيقي
        totalPagesCount: allPages.length, // العدد الكلي للصفحات الأصلية
        onPageSelected: (int origIndex) {
          // فقط انتقل إلى الصفحة المحددة. لا نعلم التغييرات كمطلّعة هنا
          // لأن ذلك يغيّر طريقة العرض من المصنّف إلى الأصلي فوراً ويُحدث إعادة ترتيب
          _selectPage(origIndex);
        }, // التنقل العادي بدون تغيير ترتيب
        onMorePressed: _openAllPagesScreen,
        onAddPagePressed: _addNewPage, // إضافة دالة إضافة الصفحة
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<String>(
            context,
            MaterialPageRoute(
              builder: (context) => AddFolderScreen(
                pageId: current.id,
                page: current,
              ),
            ),
          );
          
          if (result != null) {
            // تحديث الشاشة بعد إضافة مجلد جديد
            setState(() {});
          }
        },
        backgroundColor: Colors.blue,
        tooltip: 'إضافة مجلد جديد',
        child: const Icon(Icons.create_new_folder, color: Colors.white),
      ),
    );
  }
}
