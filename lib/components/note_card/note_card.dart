import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../../models/note_model.dart';
import '../../core/layout/layout_helpers.dart';
import '../../generated/l10n/app_localizations.dart';

class NoteCard extends StatelessWidget {
  final NoteModel note;

  const NoteCard({super.key, required this.note});

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
      ),
    );
  }
}
