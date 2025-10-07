import 'dart:io';

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

    // تحديد ما إذا كان هناك عنوان منفصل أم لا
    String? titleText;
    String contentText;
    
    switch (note.type) {
      case NoteType.text:
        final lines = note.content.split('\n').where((l) => l.trim().isNotEmpty).toList();
        
        if (lines.isEmpty) {
          // لا يوجد محتوى
          titleText = null;
          contentText = '';
        } else if (lines.length == 1) {
          // سطر واحد فقط - لا نعرض عنوان منفصل
          titleText = null;
          contentText = lines.first;
        } else {
          // عدة أسطر - نتحقق إذا كان السطر الأول قصير (عنوان محتمل)
          final firstLine = lines.first.trim();
          if (firstLine.length <= 50 && !firstLine.endsWith('.') && !firstLine.endsWith('،')) {
            // السطر الأول قصير ولا ينتهي بنقطة → نعتبره عنوان
            titleText = firstLine;
            contentText = lines.skip(1).join('\n');
          } else {
            // السطر الأول طويل أو ينتهي بنقطة → لا نعرض عنوان منفصل
            titleText = null;
            contentText = note.content;
          }
        }
        break;
      case NoteType.image:
        titleText = '[${l10n.noteTypeImage}]';
        contentText = '';
        break;
      case NoteType.audio:
        titleText = '[${l10n.noteTypeAudio}]';
        contentText = '';
        break;
    }

    final formatted = _getShortTimeAgo(note.updatedAt ?? note.createdAt);
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
              mainAxisSize: MainAxisSize.min, // تقليص الحجم حسب المحتوى
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min, // إضافة هنا أيضاً
                        children: [
                          // عرض العنوان فقط إذا كان موجوداً
                          if (titleText != null) ...[
                            Text(
                              titleText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: Responsive.sp(context, 2.1),
                                fontWeight: FontWeight.w700,
                                color: textColor,
                                height: 1.3, // تقليل المسافة بين الأسطر
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          // عرض المحتوى
                          if (contentText.isNotEmpty || note.content.isNotEmpty)
                            Text(
                              titleText != null ? contentText : note.content,
                              maxLines: 15, // زيادة إلى 15 سطر
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: Responsive.sp(context, titleText != null ? 1.8 : 2.0),
                                fontWeight: titleText != null ? FontWeight.normal : FontWeight.w500,
                                color: textColor.withOpacity(titleText != null ? 0.92 : 1.0),
                                height: 1.4, // ارتفاع مناسب للأسطر
                              ),
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
                    if (note.isPinned) 
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Icon(Icons.push_pin, size: 14, color: textColor.withOpacity(0.8)),
                      ),
                    if (note.isArchived) 
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Icon(Icons.archive, size: 14, color: textColor.withOpacity(0.8)),
                      ),
                    const Spacer(),
                    Text(
                      formatted, 
                      style: TextStyle(
                        fontSize: Responsive.sp(context, 1.5), 
                        color: textColor.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        icon: Icon(Icons.more_vert, size: 18, color: textColor.withOpacity(0.7)),
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
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _getShortTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inSeconds < 60) {
      return 'الآن';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}د';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}س';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}ي';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks}أ';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '${months}ش';
    } else {
      final years = (difference.inDays / 365).floor();
      return '${years}س';
    }
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
