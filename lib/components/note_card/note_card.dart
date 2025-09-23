import 'dart:io';

import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../../models/note_model.dart';
import '../../utils/responsive.dart';
import '../../generated/l10n/app_localizations.dart';

class NoteCard extends StatelessWidget {
  final NoteModel note;
  final void Function()? onPin;
  final void Function()? onArchive;
  final void Function()? onDelete;
  final void Function()? onShare;
  final void Function()? onTap;

  const NoteCard({super.key, required this.note, this.onPin, this.onArchive, this.onDelete, this.onShare, this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    String titleText;
    switch (note.type) {
      case NoteType.text:
        titleText = note.content.split('\n').firstWhere((_) => true, orElse: () => note.content);
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
    final textColor = (bgColor.computeLuminance() > 0.6) ? Colors.black : Colors.white;

  return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 18, offset: const Offset(0, 8)),
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            titleText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: Responsive.sp(context, 2.1), fontWeight: FontWeight.w700, color: textColor),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _getSnippet(note.content),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: Responsive.sp(context, 1.8), color: textColor.withOpacity(0.92)),
                          ),
                        ],
                      ),
                    ),
                    if ((note.attachments ?? []).isNotEmpty) ...[
                      const SizedBox(width: 12),
                      _buildThumbnail(note.attachments!.first),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (note.isPinned) Icon(Icons.push_pin, size: 16, color: textColor.withOpacity(0.9)),
                    if (note.isArchived) Icon(Icons.archive, size: 16, color: textColor.withOpacity(0.9)),
                    Expanded(child: Container()),
                    Text(formatted, style: TextStyle(fontSize: Responsive.sp(context, 1.6), color: textColor.withOpacity(0.75))),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
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
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _getSnippet(String content) {
    final lines = content.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) return '';
    final snippet = lines.length > 1 ? lines.sublist(0, 2).join(' ') : lines.first;
    return snippet;
  }

  Widget _buildThumbnail(String path) {
    try {
      final file = File(path);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(file, width: 72, height: 72, fit: BoxFit.cover),
        );
      }
    } catch (_) {}
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.image, size: 36, color: Colors.black.withOpacity(0.2)),
    );
  }
}
