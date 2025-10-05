import 'package:flutter/material.dart';
import '../../repositories/notes_repository.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../components/note_card/note_card.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/layout/layout_helpers.dart';
import 'note_detail.dart';
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

class _FolderNotesScreenState extends State<FolderNotesScreen> {
  NotesRepository? repo;
  
  @override
  void initState() {
    super.initState();
    _initializeRepository();
  }
  
  Future<void> _initializeRepository() async {
    repo = await NotesRepository.instance;
    setState(() {});
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
      ),
      body: SafeArea(
        child: SizedBox(
          height: avail,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: Layout.horizontalPadding(context) * 0.6),
            child: ListView(
              children: folder.notes.map((n) => Padding(
                padding: EdgeInsets.only(bottom: Layout.smallGap(context)),
                child: NoteCard(
                  note: n,
                  onTap: () async {
                    final changed = await Navigator.push<bool?>(
                      context,
                      MaterialPageRoute(builder: (_) => NoteDetailScreen(pageId: widget.pageId, folderId: widget.folderId, note: n)),
                    );
                    if (changed == true) {
                      if (!mounted) return;
                      setState(() {});
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
              )).toList(),
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
                debugPrint('🟡 نتيجة الإغلاق: $result');
                if (result == true && mounted) {
                  // تحديث الواجهة لعرض الملاحظات المحفوظة
                  debugPrint('🔄 تحديث الواجهة...');
                  setState(() {});
                }
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
