import 'package:flutter/material.dart';
import '../../screens/notes/add_note_screen.dart';
import '../../repositories/notes_repository.dart';

class ComposerBar extends StatefulWidget {
  final void Function(String)? onSend;
  final List<dynamic>? attachments;

  const ComposerBar({Key? key, this.onSend, this.attachments}) : super(key: key);

  @override
  _ComposerBarState createState() => _ComposerBarState();
}

class _ComposerBarState extends State<ComposerBar> {
  late TextEditingController _controller;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _hasText = _controller.text.trim().isNotEmpty;
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _hasText) {
        debugPrint('ComposerBar: hasText changed: $hasText');
        setState(() => _hasText = hasText);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _hasAttachments => (widget.attachments?.isNotEmpty ?? false);

  Future<void> _handlePrimaryAction() async {
    if (_hasText || _hasAttachments) {
      debugPrint('ComposerBar: send action with text=${_controller.text} attachments=${widget.attachments}');
      final content = _controller.text.trim();

      // Call repository to save locally
      final repo = NotesRepository();
      final success = await repo.saveNoteSimple(content);
      if (success) {
        if (widget.onSend != null) widget.onSend!(content);
        _controller.clear();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Note saved')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save note')));
      }
    } else {
      _showAddOptions();
    }
  }

  void _openAddNote() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddNoteScreen()));
  }

  void _showAddOptions() {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.note),
                title: const Text('Simple note'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddNoteScreen(noteType: NoteType.simple)));
                },
              ),
              ListTile(
                leading: const Icon(Icons.article),
                title: const Text('Article / long note'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddNoteScreen(noteType: NoteType.article)));
                },
              ),
              ListTile(
                leading: const Icon(Icons.email),
                title: const Text('Email / formatted message'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddNoteScreen(noteType: NoteType.email)));
                },
              ),
              ListTile(
                leading: const Icon(Icons.check_box),
                title: const Text('Checklist / tasks'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddNoteScreen(noteType: NoteType.checklist)));
                },
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Cancel'),
                onTap: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        color: Colors.white,
        child: Row(
          children: [
            IconButton(onPressed: () {}, icon: const Icon(Icons.photo)),
            IconButton(onPressed: () {}, icon: const Icon(Icons.mic)),
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration.collapsed(hintText: 'Write a note...'),
              ),
            ),
            GestureDetector(
              onLongPress: _openAddNote,
              child: IconButton(
                tooltip: _hasText || _hasAttachments ? 'Send' : 'Add',
                onPressed: _handlePrimaryAction,
                icon: Icon(_hasText || _hasAttachments ? Icons.send : Icons.add),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
