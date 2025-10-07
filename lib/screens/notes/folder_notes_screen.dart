import 'package:flutter/material.dart';
import '../../repositories/notes_repository.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../components/note_card/note_card.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/layout/layout_helpers.dart';
import '../../widgets/speed_dial_fab.dart';
import 'rich_note_editor.dart';

/// شاشة عرض الملاحظات داخل مجلد معين
/// زر الرجوع يخرج من الشاشة بضغطة واحدة
class FolderNotesScreen extends StatefulWidget {
  final String pageId;
  final String folderId;

  const FolderNotesScreen({super.key, required this.pageId, required this.folderId});

  @override
  State<FolderNotesScreen> createState() => _FolderNotesScreenState();
}

enum NoteSortType {
  newestFirst,    // الأحدث أولاً
  oldestFirst,    // الأقدم أولاً
  alphabetical,   // أبجدياً (أ-ي)
  reverseAlpha,   // أبجدياً عكسي (ي-أ)
}

class _FolderNotesScreenState extends State<FolderNotesScreen> with WidgetsBindingObserver {
  NotesRepository? repo;
  NoteSortType _sortType = NoteSortType.newestFirst; // الترتيب الافتراضي
  
  @override
  void initState() {
    super.initState();
    _initializeRepository();
    WidgetsBinding.instance.addObserver(this);
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint('🔄 التطبيق عاد للواجهة، تحديث البيانات...');
      setState(() {});
    }
  }
  
  Future<void> _initializeRepository() async {
    repo = await NotesRepository.instance;
    setState(() {});
  }
  
  Future<void> _refreshData() async {
    debugPrint('🔄 تحديث البيانات...');
    if (repo != null) {
      final folder = repo!.getFolder(widget.pageId, widget.folderId);
      debugPrint('📊 عدد الملاحظات: ${folder?.notes.length}');
      setState(() {});
    }
  }
  
  List _sortNotes(List notes) {
    final sorted = List.from(notes);
    
    sorted.sort((a, b) {
      // الملاحظات المثبتة دائماً في الأعلى
      if (a.isPinned != b.isPinned) {
        return a.isPinned ? -1 : 1;
      }
      
      // ثم الترتيب حسب النوع المحدد
      switch (_sortType) {
        case NoteSortType.newestFirst:
          // معالجة null values
          final aDate = a.updatedAt ?? a.createdAt;
          final bDate = b.updatedAt ?? b.createdAt;
          return bDate.compareTo(aDate); // الأحدث أولاً
        
        case NoteSortType.oldestFirst:
          // معالجة null values
          final aDate = a.updatedAt ?? a.createdAt;
          final bDate = b.updatedAt ?? b.createdAt;
          return aDate.compareTo(bDate); // الأقدم أولاً
        
        case NoteSortType.alphabetical:
          final aContent = a.content.toLowerCase();
          final bContent = b.content.toLowerCase();
          return aContent.compareTo(bContent); // أ-ي
        
        case NoteSortType.reverseAlpha:
          final aContent = a.content.toLowerCase();
          final bContent = b.content.toLowerCase();
          return bContent.compareTo(aContent); // ي-أ
      }
    });
    
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (repo == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.loadingData)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    final folder = repo!.getFolder(widget.pageId, widget.folderId);
    
    if (folder == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.error)),
        body: Center(child: Text(l10n.folderNotFound)),
      );
    }
    
    debugPrint('📋 FolderNotesScreen: عرض ${folder.notes.length} ملاحظة');
    
    // ترتيب الملاحظات
    final sortedNotes = _sortNotes(folder.notes);
    
    final reserved = kToolbarHeight + MediaQuery.of(context).padding.top;
    final avail = Layout.availableHeight(context, reservedHeight: reserved);

    return Scaffold(
      appBar: AppBar(
        title: Text(folder.title),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: Layout.iconSize(context) + 2),
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
        actions: [
          // زر الترتيب
          PopupMenuButton<NoteSortType>(
            icon: Icon(Icons.sort),
            tooltip: 'ترتيب الملاحظات',
            onSelected: (NoteSortType type) {
              setState(() {
                _sortType = type;
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: NoteSortType.newestFirst,
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 20,
                      color: _sortType == NoteSortType.newestFirst ? Colors.blue : null,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'الأحدث أولاً',
                      style: TextStyle(
                        color: _sortType == NoteSortType.newestFirst ? Colors.blue : null,
                        fontWeight: _sortType == NoteSortType.newestFirst ? FontWeight.bold : null,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: NoteSortType.oldestFirst,
                child: Row(
                  children: [
                    Icon(
                      Icons.history,
                      size: 20,
                      color: _sortType == NoteSortType.oldestFirst ? Colors.blue : null,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'الأقدم أولاً',
                      style: TextStyle(
                        color: _sortType == NoteSortType.oldestFirst ? Colors.blue : null,
                        fontWeight: _sortType == NoteSortType.oldestFirst ? FontWeight.bold : null,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: NoteSortType.alphabetical,
                child: Row(
                  children: [
                    Icon(
                      Icons.sort_by_alpha,
                      size: 20,
                      color: _sortType == NoteSortType.alphabetical ? Colors.blue : null,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'أبجدياً (أ-ي)',
                      style: TextStyle(
                        color: _sortType == NoteSortType.alphabetical ? Colors.blue : null,
                        fontWeight: _sortType == NoteSortType.alphabetical ? FontWeight.bold : null,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: NoteSortType.reverseAlpha,
                child: Row(
                  children: [
                    Icon(
                      Icons.sort_by_alpha,
                      size: 20,
                      color: _sortType == NoteSortType.reverseAlpha ? Colors.blue : null,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'أبجدياً (ي-أ)',
                      style: TextStyle(
                        color: _sortType == NoteSortType.reverseAlpha ? Colors.blue : null,
                        fontWeight: _sortType == NoteSortType.reverseAlpha ? FontWeight.bold : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: SizedBox(
          height: avail,
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: Layout.horizontalPadding(context) * 0.6),
              child: Wrap(
                spacing: Layout.smallGap(context), // المسافة الأفقية
                runSpacing: Layout.smallGap(context), // المسافة العمودية
                children: sortedNotes.map((n) {
                  return SizedBox(
                    width: (MediaQuery.of(context).size.width - Layout.horizontalPadding(context) * 1.2 - Layout.smallGap(context)) / 2,
                    child: NoteCard(
                  note: n,
                  onTap: () async {
                    debugPrint('📝 فتح ملاحظة للتعديل: ${n.id}');
                    
                    // فصل العنوان عن المحتوى
                    String? initialTitle;
                    String? initialContent;
                    
                    final allLines = n.content.split('\n');
                    final lines = <String>[];
                    for (var line in allLines) {
                      if (line.trim().isNotEmpty) {
                        lines.add(line);
                      }
                    }
                    
                    if (lines.length > 1) {
                      final firstLine = lines.first.trim();
                      if (firstLine.length <= 50 && !firstLine.endsWith('.') && !firstLine.endsWith('،')) {
                        initialTitle = firstLine;
                        initialContent = lines.skip(1).join('\n');
                      } else {
                        initialTitle = null;
                        initialContent = n.content;
                      }
                    } else {
                      initialTitle = null;
                      initialContent = n.content;
                    }
                    
                    final changed = await Navigator.push<bool?>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RichNoteEditor(
                          pageId: widget.pageId,
                          folderId: widget.folderId,
                          initialTitle: initialTitle,
                          initialContent: initialContent,
                          initialColor: n.colorValue,
                          existingNoteId: n.id, // تمرير معرف الملاحظة للتعديل
                        ),
                      ),
                    );
                    
                    if (changed == true) {
                      await _refreshData();
                    }
                  },
                  onPin: () async {
                    await repo!.togglePin(widget.pageId, widget.folderId, n.id);
                    setState(() {});
                  },
                  onArchive: () async {
                    await repo!.toggleArchive(widget.pageId, widget.folderId, n.id);
                    setState(() {});
                  },
                  onDelete: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await repo!.deleteNote(widget.pageId, widget.folderId, n.id);
                    setState(() {});
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Note deleted'),
                        action: SnackBarAction(
                          label: 'Undo',
                          onPressed: () async {
                            await repo!.restoreNote(widget.pageId, widget.folderId, n.id);
                            if (!mounted) return;
                            setState(() {});
                          },
                        ),
                      ),
                    );
                  },
                  onShare: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      if ((n.attachments ?? []).isNotEmpty) {
                        final xfiles = (n.attachments ?? []).map((p) => XFile(p)).toList();
                        await Share.shareXFiles(xfiles, text: n.content);
                      } else {
                        await Share.share(n.content);
                      }
                    } catch (e) {
                      messenger.showSnackBar(SnackBar(content: Text('Share failed')));
                    }
                  },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: Directionality(
        textDirection: TextDirection.ltr,
        child: SpeedDialFAB(
        icon: Icons.add,
        activeIcon: Icons.close,
        backgroundColor: Colors.blue,
        children: [
          SpeedDialChild(
            icon: Icons.text_fields,
            label: 'ملاحظة نصية',
            backgroundColor: Colors.blue.shade100,
            foregroundColor: Colors.blue.shade700,
            onPressed: () async {
              debugPrint('🔵 تم الضغط على زر ملاحظة نصية');
              try {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) {
                      debugPrint('🟢 جاري فتح RichNoteEditor');
                      return RichNoteEditor(
                        pageId: widget.pageId,
                        folderId: widget.folderId,
                      );
                    },
                  ),
                );
                debugPrint('🟡 نتيجة الإغلاق: $result (type: ${result.runtimeType})');
                // تحديث الواجهة دائماً عند الرجوع من صفحة الكتابة
                await _refreshData();
              } catch (e) {
                debugPrint('🔴 خطأ: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('خطأ: $e')),
                  );
                }
              }
            },
          ),
          SpeedDialChild(
            icon: Icons.image,
            label: 'صورة',
            backgroundColor: Colors.green.shade100,
            foregroundColor: Colors.green.shade700,
            onPressed: () {
              // TODO: إضافة صورة
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('قريباً: إضافة صورة')),
              );
            },
          ),
          SpeedDialChild(
            icon: Icons.mic,
            label: 'تسجيل صوتي',
            backgroundColor: Colors.red.shade100,
            foregroundColor: Colors.red.shade700,
            onPressed: () {
              // TODO: إضافة تسجيل صوتي
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('قريباً: تسجيل صوتي')),
              );
            },
          ),
          SpeedDialChild(
            icon: Icons.checklist,
            label: 'قائمة مهام',
            backgroundColor: Colors.orange.shade100,
            foregroundColor: Colors.orange.shade700,
            onPressed: () {
              // TODO: إضافة قائمة مهام
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('قريباً: قائمة مهام')),
              );
            },
          ),
        ],
        ),
      ),
    );
  }
}
