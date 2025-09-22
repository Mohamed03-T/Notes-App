import 'package:flutter/material.dart';
import '../../repositories/notes_repository.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../components/note_card/note_card.dart';
import '../../components/composer_bar/composer_bar.dart';
import '../../core/layout/layout_helpers.dart';

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
    // طباعة حالة المجلد عند الفتح
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final folder = repo?.getFolder(widget.pageId, widget.folderId);
      debugPrint('🔍 فتح مجلد: ${folder?.title} - عدد الملاحظات: ${folder?.notes.length}');
    });
    setState(() {});
  }

  Future<void> _saveNote(String text, int? colorValue) async {
    if (repo == null) return;
    
    // حفظ الملاحظة في المجلد المحدد
    debugPrint('💾 حفظ ملاحظة في المجلد: ${widget.folderId}');
    debugPrint('📝 النص: $text');

  final success = await repo!.saveNoteToFolder(text, widget.pageId, widget.folderId, colorValue: colorValue);
    
    if (success) {
      setState(() {
        // تحديث الواجهة
      });
      
      debugPrint('✅ تم حفظ الملاحظة بنجاح');
    } else {
      debugPrint('❌ فشل في حفظ الملاحظة');
    }
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
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: Layout.horizontalPadding(context) * 0.6),
                  child: ListView(
                    children: folder.notes.map((n) => Padding(
                      padding: EdgeInsets.only(bottom: Layout.smallGap(context)),
                      child: NoteCard(note: n),
                    )).toList(),
                  ),
                ),
              ),
              ComposerBar(
                onSend: _saveNote,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
