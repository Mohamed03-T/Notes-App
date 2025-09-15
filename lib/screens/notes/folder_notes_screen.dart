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
  late NotesRepository repo;
  
  @override
  void initState() {
    super.initState();
    repo = NotesRepository();
    // طباعة حالة المجلد عند الفتح
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final folder = repo.getFolder(widget.pageId, widget.folderId);
      debugPrint('🔍 فتح مجلد: ${folder?.title} - عدد الملاحظات: ${folder?.notes.length}');
    });
  }

  Future<void> _saveNote(String text) async {
    // حفظ الملاحظة في المجلد المحدد
    debugPrint('💾 حفظ ملاحظة في المجلد: ${widget.folderId}');
    debugPrint('📝 النص: $text');

    final success = await repo.saveNoteToFolder(text, widget.pageId, widget.folderId);
    
    if (success) {
      setState(() {
        // تحديث الواجهة
      });
      
      debugPrint('✅ تم حفظ الملاحظة بنجاح');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ الملاحظة بنجاح! ✅')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل في حفظ الملاحظة ❌')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final folder = repo.getFolder(widget.pageId, widget.folderId)!;
    
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
