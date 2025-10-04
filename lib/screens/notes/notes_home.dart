import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../components/top_bar/top_bar.dart';
import '../../core/layout/layout_helpers.dart';
import '../../utils/responsive.dart';
import '../../repositories/notes_repository.dart';
import '../../components/folder_card/folder_card.dart';
import '../../models/folder_model.dart';
import '../../widgets/app_logo.dart';
import 'folder_notes_screen.dart';
import 'all_pages_screen.dart';
import 'add_folder_screen.dart';
import 'add_page_screen.dart';
import '../settings/settings_screen.dart';

class NotesHome extends StatefulWidget {
  const NotesHome({super.key});

  @override
  State<NotesHome> createState() => _NotesHomeState();
}

class _NotesHomeState extends State<NotesHome> {
  NotesRepository? repo;
  bool isInitializing = true;
  int currentPageIndex = 0;
  List<FolderModel> folderList = [];  // Track folders for reorder
  FolderModel? _draggingFolder;
  
  // Cache للحسابات المتكررة
  late int _gridCols;
  late double _gridAspect;
  bool _gridConfigInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeRepository();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_gridConfigInitialized) {
      _updateGridConfig();
      _gridConfigInitialized = true;
    }
  }

  void _updateGridConfig() {
    final width = MediaQuery.of(context).size.width;
    _gridCols = width > 1000 ? 4 : (width > 600 ? 3 : 2);
    _gridAspect = width > 1000 ? 0.95 : (width > 600 ? 0.9 : 0.85);
  }

  Future<void> _initializeRepository() async {
    try {
      repo = await NotesRepository.instance;
      // after repo loaded, initialize folder list for current page
      final pages = repo!.getPages();
      if (pages.isNotEmpty) {
        final currentPage = pages[currentPageIndex];
        folderList = List<FolderModel>.from(currentPage.folders);
      }
      if (mounted) {
        setState(() {
          isInitializing = false;
        });
      }
    } catch (e) {
  if (kDebugMode) debugPrint('❌ خطأ في تحميل البيانات: $e');
      if (mounted) {
        setState(() {
          isInitializing = false;
        });
      }
    }
  }

  void _selectPage(int index) {
    if (repo == null) return;
    setState(() {
      currentPageIndex = index;
      // update folder list for new selected page
      final pages = repo!.getPages();
      if (pages.isNotEmpty && index < pages.length) {
        folderList = List<FolderModel>.from(pages[index].folders);
      }
    });
  }

  void _openAllPagesScreen() async {
    final selectedPageIndex = await Navigator.push<int>(
      context, 
      MaterialPageRoute(builder: (_) => const AllPagesScreen())
    );
    
    if (selectedPageIndex != null) {
      if (!mounted) return;
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
      final allPages = repo!.getPages();
      final newPageIndex = allPages.indexWhere((page) => page.id == result);
      if (newPageIndex != -1) {
        if (!mounted) return;
        setState(() {
          currentPageIndex = newPageIndex;
        });
      }
    }
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  // دالة لإظهار قائمة التحكم بالمجلد عند النقر المزدوج
  void _showFolderActions(FolderModel folder, AppLocalizations l10n) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.symmetric(vertical: Layout.smallGap(context) * 0.8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(Layout.horizontalPadding(context)),
                child: Text(
                  '${l10n.manageFolder} ${folder.title}',
                  style: TextStyle(
                    fontSize: Responsive.sp(context, 2.6),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: Icon(
                  folder.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                  color: Colors.blue,
                ),
                title: Text(folder.isPinned ? l10n.unpinFolder : l10n.pinFolder),
                onTap: () => Navigator.pop(context, 'pin'),
              ),
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.green),
                title: Text(l10n.renameFolder),
                onTap: () => Navigator.pop(context, 'rename'),
              ),
              ListTile(
                leading: const Icon(Icons.palette, color: Colors.orange),
                title: Text(l10n.changeBackgroundColor),
                onTap: () => Navigator.pop(context, 'color'),
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(l10n.deleteFolder, style: const TextStyle(color: Colors.red)),
                onTap: () => Navigator.pop(context, 'delete'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );

    if (result != null) {
      await _handleFolderAction(folder, result, l10n);
    }
  }

  // دالة لمعالجة إجراءات المجلد
  Future<void> _handleFolderAction(FolderModel folder, String action, AppLocalizations l10n) async {
    switch (action) {
      case 'pin':
        setState(() {
          folder.isPinned = !folder.isPinned;
        });
        break;
      case 'rename':
        final newName = await showDialog<String>(
          context: context,
          builder: (ctx) {
            final controller = TextEditingController(text: folder.title);
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(l10n.renameFolder),
              content: TextField(
                controller: controller,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: l10n.folderName,
                ),
                autofocus: true,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(l10n.cancel),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, controller.text.trim()),
                  child: Text(l10n.confirm),
                ),
              ],
            );
          },
        );
        if (newName != null && newName.isNotEmpty) {
          setState(() {
            folder.title = newName;
          });
        }
        break;
      case 'color':
        final colors = [
          Colors.red, Colors.orange, Colors.yellow, Colors.green,
          Colors.blue, Colors.indigo, Colors.purple, Colors.pink,
          Colors.teal, Colors.brown, Colors.grey
        ];
        final chosen = await showDialog<Color?>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(l10n.selectBackgroundColor),
            content: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // زر إزالة اللون
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx, null),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400, width: 2),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: const Icon(Icons.clear, color: Colors.grey),
                    ),
                  ),
                  // ألوان مختلفة
                  ...colors.map((c) => GestureDetector(
                    onTap: () => Navigator.pop(ctx, c),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: c,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: Colors.grey.shade300, width: 2),
                      ),
                    ),
                  )),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.cancel),
              ),
            ],
          ),
        );
        if (chosen != null) {
          setState(() {
            folder.backgroundColor = chosen;
          });
        }
        break;
      case 'delete':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(l10n.confirmDelete),
            content: Text(l10n.deleteConfirmMessage(folder.title)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.cancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text(l10n.delete, style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
        if (confirm == true) {
          final allPages = repo!.getPages();
          final currentPage = allPages[currentPageIndex];
          repo!.deleteFolder(currentPage.id, folder.id);
          setState(() {});
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    // عرض شاشة التحميل إذا لم يتم تحميل البيانات بعد
    if (isInitializing || repo == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              SizedBox(height: Layout.sectionSpacing(context) / 2),
              Text(
                l10n.loadingData,
                style: TextStyle(fontSize: Layout.bodyFont(context)),
              ),
            ],
          ),
        ),
      );
    }

    final allPages = repo!.getPages(); // ترتيب الصفحات الأصلي
    // إذا كانت هناك تغييرات جديدة، استخدم الترتيب حسب النشاط لعرض الشرائح
    final bool useSorted = repo!.hasNewChanges;
    final sortedPages = useSorted ? repo!.getPagesSortedByActivity() : allPages;
    
    // التأكد من أن الفهرس صحيح
    if (currentPageIndex >= allPages.length) {
      currentPageIndex = 0;
    }
    
    final current = allPages.isNotEmpty ? allPages[currentPageIndex] : null;

    if (current == null || allPages.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.welcome),
          backgroundColor: Colors.grey.shade800,
          foregroundColor: Colors.grey.shade200,
          actions: [
            IconButton(
              onPressed: () async {
                final result = await Navigator.push<String>(
                  context,
                  MaterialPageRoute(builder: (context) => const AddPageScreen()),
                );
                
                  if (result != null) {
                    // تحديث الشاشة وانتقل إلى الصفحة الجديدة
                    final allPages = repo!.getPages();
                    final newPageIndex = allPages.indexWhere((page) => page.id == result);
                    if (newPageIndex != -1) {
                      if (!mounted) return;
                      setState(() {
                        currentPageIndex = newPageIndex;
                      });
                    }
                  }
              },
              icon: const Icon(Icons.add, color: Colors.blue),
              tooltip: l10n.addNewPage,
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppLogo(
                size: Responsive.wp(context, 36),
                showText: false,
              ),
              SizedBox(height: Layout.sectionSpacing(context)),
              Text(
                l10n.noPagesYet,
                style: TextStyle(
                  fontSize: Responsive.sp(context, 3.6),
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              SizedBox(height: Layout.smallGap(context)),
              Text(
                l10n.createFirstPage,
                style: TextStyle(
                  fontSize: Layout.bodyFont(context),
                  color: Colors.grey.shade500,
                ),
              ),
              SizedBox(height: Layout.sectionSpacing(context) * 1.5),
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push<String>(
                    context,
                    MaterialPageRoute(builder: (context) => const AddPageScreen()),
                  );
                  
                  if (result != null) {
                    final allPages = repo!.getPages();
                    final newPageIndex = allPages.indexWhere((page) => page.id == result);
                    if (newPageIndex != -1) {
                      if (!mounted) return;
                      setState(() {
                        currentPageIndex = newPageIndex;
                      });
                    }
                  }
                },
                icon: const Icon(Icons.add),
                label: Text(l10n.createNewPage),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: Responsive.wp(context, 6), vertical: Responsive.hp(context, 1.5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Initialize or reset folderList when page changes
    if (folderList.length != current.folders.length) {
      folderList = List<FolderModel>.from(current.folders)
        ..sort((a, b) {
          if (a.isPinned && !b.isPinned) return -1;
          if (!a.isPinned && b.isPinned) return 1;
          return 0;
        });
    }

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
        onAllPagesPressed: _openAllPagesScreen, // دمج زر جميع الصفحات مع القائمة
        onAddPagePressed: _addNewPage, // إضافة دالة إضافة الصفحة
        onSettingsPressed: _openSettings, // إضافة دالة الإعدادات
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // إعادة تحميل البيانات من التخزين المحلي فقط
          await repo!.refreshData();
          // تحديث folderList من البيانات المحدثة
          final pages = repo!.getPages();
          if (pages.isNotEmpty && currentPageIndex < pages.length) {
            folderList = List<FolderModel>.from(pages[currentPageIndex].folders);
          }
          if (!mounted) return;
          setState(() {});
        },
        child: folderList.isEmpty 
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const AppLogo(
                    size: 140,
                    showText: false,
                  ),
                  SizedBox(height: Layout.sectionSpacing(context)),
                  Text(
                    l10n.noFoldersYet,
                    style: TextStyle(
                      fontSize: Responsive.sp(context, 3.0),
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  SizedBox(height: Layout.smallGap(context)),
                  Text(
                    l10n.tapPlusToAddFolder,
                    style: TextStyle(
                      fontSize: Layout.bodyFont(context),
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            )
          : LayoutBuilder(
            builder: (context, constraints) {
              // تحديث Grid config إذا تغير حجم الشاشة
              final newCols = constraints.maxWidth > 1000 ? 4 : (constraints.maxWidth > 600 ? 3 : 2);
              if (newCols != _gridCols) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _updateGridConfig();
                });
              }
              
              return GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _gridCols,
                  childAspectRatio: _gridAspect,
                ),
                padding: EdgeInsets.all(Layout.horizontalPadding(context)),
                itemCount: folderList.length,
                itemBuilder: (context, index) {
                  final f = folderList[index];
                  final targetIndex = index;
              return DragTarget<FolderModel>(
                onWillAcceptWithDetails: (details) => details.data != f,
                onAcceptWithDetails: (details) async {
                  final dragged = details.data;
                  final oldIndex = folderList.indexOf(dragged);
                  
                  setState(() {
                    folderList.removeAt(oldIndex);
                    folderList.insert(targetIndex, dragged);
                  });
                  
                  // Persist new order
                  await repo!.reorderFolders(current.id, folderList.map((f) => f.id).toList());
                  
                  // تحديث folderList من المصدر الفعلي بعد إعادة الترتيب
                  final updatedPage = repo!.getPage(current.id);
                  if (updatedPage != null) {
                    if (!mounted) return;
                    setState(() {
                      folderList = List<FolderModel>.from(updatedPage.folders);
                    });
                  }
                },
                builder: (context, candidateData, rejectedData) {
                  final isTarget = candidateData.isNotEmpty;
                  final isDragging = _draggingFolder == f || isTarget;
                  
                  Widget dragWidget = LongPressDraggable<FolderModel>(
                    data: f,
                    delay: const Duration(milliseconds: 600),
                    onDragStarted: () => setState(() => _draggingFolder = f),
                    onDragEnd: (_) => setState(() => _draggingFolder = null),
                          feedback: Material(
                      elevation: 12.0,
                      color: Colors.transparent,
                      child: Transform.scale(
                        scale: 1.03,
                        child: Container(
                          width: Responsive.wp(context, 44),
                          height: Responsive.hp(context, 30),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Color.fromRGBO(59, 130, 246, 0.4),
                                blurRadius: 16,
                                spreadRadius: 4,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Container(
                            margin: EdgeInsets.all(Responsive.wp(context, 2)),
                            decoration: BoxDecoration(
                              color: (f.backgroundColor ?? Colors.blue.shade100),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.blue.shade300,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(Responsive.wp(context, 3)),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade200,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(14),
                                      topRight: Radius.circular(14),
                                    ),
                                  ),
                                  child: Text(
                                    f.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: Responsive.sp(context, 1.9),
                                      color: Colors.white,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Expanded(
                                  child: Center(
                                    child: Icon(
                                      Icons.folder,
                                      size: Responsive.sp(context, 4.0),
                                      color: Colors.blue.shade300,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    childWhenDragging: Container(
                        margin: EdgeInsets.all(Responsive.wp(context, 2)),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Color.fromRGBO(59, 130, 246, 0.5),
                            width: 2,
                            style: BorderStyle.solid,
                          ),
                            color: Color.fromRGBO(59, 130, 246, 0.1),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.drag_indicator,
                            size: Responsive.sp(context, 3.6),
                            color: Colors.blue,
                          ),
                        ),
                      ),
            child: FolderCard(
                      folder: f,
                      isDragging: isDragging,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FolderNotesScreen(pageId: current.id, folderId: f.id),
                          ),
                        );
                        // تحديث folderList من البيانات الحديثة في الذاكرة
                        final pages = repo!.getPages();
                        if (pages.isNotEmpty && currentPageIndex < pages.length) {
                          folderList = List<FolderModel>.from(pages[currentPageIndex].folders);
                        }
                        if (!mounted) return;
                        setState(() {});
                      },
                      onDoubleTap: () => _showFolderActions(f, l10n), // إضافة النقر المزدوج
                      onDelete: () {
                        repo!.deleteFolder(current.id, f.id);
                        setState(() {});
                      },
                    ),
                  );
                  
                  // إضافة حدود زرقاء عند السحب فوق المنطقة
                  if (isTarget) {
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.blue.shade400,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color.fromRGBO(59, 130, 246, 0.2),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: dragWidget,
                    );
                  }
                  
                  return dragWidget;
                },
              );
                },
              );
            },
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
            if (!mounted) return;
            setState(() {});
          }
        },
        backgroundColor: Colors.blue,
        tooltip: l10n.addNewFolder,
        child: Icon(Icons.create_new_folder, color: Colors.white, size: Layout.iconSize(context) + 6),
      ),
    );
  }
}
