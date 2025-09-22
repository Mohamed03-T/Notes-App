import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../../models/note_model.dart';
import '../../core/layout/layout_helpers.dart';
import '../../generated/l10n/app_localizations.dart';

class NoteCard extends StatelessWidget {
  final NoteModel note;
  final void Function()? onPin;
  final void Function()? onArchive;
  final void Function()? onDelete;
  final void Function()? onShare;

  const NoteCard({super.key, required this.note, this.onPin, this.onArchive, this.onDelete, this.onShare});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    String titleText;
    switch (note.type) {
      case NoteType.text:
        titleText = note.content;
        break;
      case NoteType.image:
        titleText = '[${l10n.noteTypeImage}]';
        break;
      case NoteType.audio:
        titleText = '[${l10n.noteTypeAudio}]';
        break;
    }

    final formatted = DateFormat.yMMMd(l10n.localeName).add_jm().format(note.createdAt);

    final bgColor = note.color ?? Theme.of(context).cardColor;
    final textColor = (bgColor.computeLuminance() > 0.5) ? Colors.black : Colors.white;

    return Card(
      color: bgColor,
      child: ListTile(
        title: Text(titleText, style: TextStyle(fontSize: Layout.bodyFont(context), color: textColor)),
        subtitle: Text(formatted, style: TextStyle(fontSize: Layout.bodyFont(context) * 0.9, color: textColor.withOpacity(0.9))),
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            switch (v) {
              case 'pin':
                if (onPin != null) onPin!();
                break;
              case 'archive':
                if (onArchive != null) onArchive!();
                break;
              case 'delete':
                if (onDelete != null) onDelete!();
                break;
              case 'share':
                if (onShare != null) onShare!();
                break;
            }
          },
          itemBuilder: (ctx) => [
            PopupMenuItem(value: 'pin', child: Text(note.isPinned ? 'Unpin' : 'Pin')),
            PopupMenuItem(value: 'archive', child: Text(note.isArchived ? 'Unarchive' : 'Archive')),
            PopupMenuItem(value: 'delete', child: Text('Delete', style: const TextStyle(color: Colors.red))),
            PopupMenuItem(value: 'share', child: Text('Share')),
          ],
        ),
      ),
    );
  }
}
