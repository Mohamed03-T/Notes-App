import 'package:flutter/material.dart';
import '../../repositories/notes_repository.dart';
import '../../components/note_card/note_card.dart';
import '../../components/composer_bar/composer_bar.dart';

/// شاشة عرض الملاحظات داخل مجلد معين
/// زر الرجوع يخرج من الشاشة بضغطة واحدة
class FolderNotesScreen extends StatefulWidget {
  final String pageId;
  final String folderId;

  const FolderNotesScreen({Key? key, required this.pageId, required this.folderId}) : super(key: key);

  @override
  _FolderNotesScreenState createState() => _FolderNotesScreenState();
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

  Future<void> _saveNote(String text) async {
    if (repo == null) return;
    
    // حفظ الملاحظة في المجلد المحدد
    debugPrint('💾 حفظ ملاحظة في المجلد: ${widget.folderId}');
    debugPrint('📝 النص: $text');

    final success = await repo!.saveNoteToFolder(text, widget.pageId, widget.folderId);
    
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
    if (repo == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('تحميل...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    final folder = repo!.getFolder(widget.pageId, widget.folderId);
    
    if (folder == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('خطأ')),
        body: const Center(child: Text('المجلد غير موجود')),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(folder.title),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: folder.notes.map((n) => NoteCard(note: n)).toList(),
            ),
          ),
          ComposerBar(
            onSend: _saveNote,
          ),
        ],
      ),
    );
  }
}
