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
  final void Function()? onLongPress; // للضغط المطول

  const NoteCard({super.key, required this.note, this.onPin, this.onArchive, this.onDelete, this.onShare, this.onTap, this.onLongPress});

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
          onLongPress: onLongPress,
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
                // إظهار أيقونات الحالة فقط (مثبت/مؤرشف) بدون التاريخ والقائمة
                if (note.isPinned || note.isArchived) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (note.isPinned) 
                        Icon(Icons.push_pin, size: 14, color: textColor.withOpacity(0.6)),
                      if (note.isPinned && note.isArchived)
                        const SizedBox(width: 6),
                      if (note.isArchived) 
                        Icon(Icons.archive, size: 14, color: textColor.withOpacity(0.6)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
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
