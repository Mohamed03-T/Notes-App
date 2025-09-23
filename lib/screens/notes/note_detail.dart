import 'package:flutter/material.dart';
import '../../models/note_model.dart';
import '../../repositories/notes_repository.dart';
import '../../components/color_picker/dialog_color_picker.dart';
import '../../components/attachment/attachment_picker.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../utils/responsive.dart';

class NoteDetailScreen extends StatefulWidget {
  final String pageId;
  final String folderId;
  final NoteModel note;

  const NoteDetailScreen({super.key, required this.pageId, required this.folderId, required this.note});

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  late TextEditingController _controller;
  int? _color;
  List<String> _attachments = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.note.content);
    _color = widget.note.colorValue;
    _attachments = List<String>.from(widget.note.attachments ?? []);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final repo = await NotesRepository.instance;
    final success = await repo.updateNote(widget.pageId, widget.folderId, widget.note.id, content: _controller.text.trim(), colorValue: _color, attachments: _attachments);
    setState(() => _saving = false);
    if (success) Navigator.pop(context, true);
    else ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.error)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.save),
        actions: [
          IconButton(onPressed: _save, icon: _saving ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.save)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    final picked = await showColorPickerDialog(context, initialColor: _color);
                    if (picked != null) setState(() => _color = picked);
                  },
                  icon: const Icon(Icons.palette),
                  label: Text(l10n.selectBackgroundColor),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    final path = await showAttachmentPathDialog(context);
                    if (path != null && path.isNotEmpty) setState(() => _attachments.add(path));
                  },
                  icon: const Icon(Icons.attach_file),
                  label: Text(l10n.composerOptionSimple),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                style: TextStyle(fontSize: Responsive.sp(context, 1.9)),
              ),
            ),
            if (_attachments.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _attachments.map((p) => Chip(label: Text(p), onDeleted: () => setState(() => _attachments.remove(p)))).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
