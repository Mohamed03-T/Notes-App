import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final void Function(String draggedNoteId, String targetNoteId)? onReorder; // لإعادة الترتيب
  final void Function()? onDragStart; // عند بدء السحب
  final void Function()? onDragEnd; // عند انتهاء السحب

  const NoteCard({super.key, required this.note, this.onPin, this.onArchive, this.onDelete, this.onShare, this.onTap, this.onLongPress, this.onReorder, this.onDragStart, this.onDragEnd});

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

  // تغليف الـ Card بـ Draggable و DragTarget
  final cardWidget = AnimatedContainer(
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
          // تعطيل onLongPress عندما يكون onReorder موجود (لتفعيل السحب)
          onLongPress: onReorder == null ? onLongPress : null,
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // تقليص الحجم حسب المحتوى
              children: [
                // أيقونة السحب (تظهر فقط إذا كان onReorder موجود)
                if (onReorder != null)
                  Center(
                    child: Container(
                      width: 32,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: textColor.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
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
                // إظهار أيقونات الحالة وزر القائمة
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (note.isPinned) 
                      Icon(Icons.push_pin, size: 14, color: textColor.withOpacity(0.6)),
                    if (note.isPinned && note.isArchived)
                      const SizedBox(width: 6),
                    if (note.isArchived) 
                      Icon(Icons.archive, size: 14, color: textColor.withOpacity(0.6)),
                    const Spacer(),
                    // زر القائمة (يظهر فقط عندما يكون onReorder موجود)
                    if (onReorder != null && onLongPress != null)
                      InkWell(
                        onTap: onLongPress,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Icon(
                            Icons.more_vert,
                            size: 18,
                            color: textColor.withOpacity(0.6),
                          ),
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

  // إذا لم يتم تمرير onReorder، نعرض الكارد مباشرة
  if (onReorder == null) {
    return cardWidget;
  }

  // تغليف بـ DragTarget لاستقبال السحب (نفس طريقة المجلدات)
  return DragTarget<String>(
    onWillAcceptWithDetails: (details) => details.data != note.id,
    onAcceptWithDetails: (details) async {
      final draggedNoteId = details.data;
      debugPrint('🎯 تم قبول السحب: $draggedNoteId → ${note.id}');
      HapticFeedback.heavyImpact();
      onReorder!(draggedNoteId, note.id);
    },
    builder: (context, candidateData, rejectedData) {
      final isTarget = candidateData.isNotEmpty;
      
      return LongPressDraggable<String>(
        data: note.id,
        delay: const Duration(milliseconds: 600), // نفس delay المجلدات
        onDragStarted: () {
          HapticFeedback.mediumImpact();
          if (onDragStart != null) onDragStart!();
          debugPrint('🎯 بدأ السحب للملاحظة: ${note.id}');
        },
        onDragEnd: (_) {
          if (onDragEnd != null) onDragEnd!();
          debugPrint('✅ انتهى السحب');
        },
        feedback: Material(
          elevation: 12.0,
          color: Colors.transparent,
          child: Transform.scale(
            scale: 1.03,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Color.fromRGBO(59, 130, 246, 0.4),
                    blurRadius: 16,
                    spreadRadius: 4,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: note.color ?? Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.blue.shade300,
                    width: 2,
                  ),
                ),
                child: cardWidget,
              ),
            ),
          ),
        ),
        childWhenDragging: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Color.fromRGBO(59, 130, 246, 0.5),
              width: 2,
              style: BorderStyle.solid,
            ),
            color: Color.fromRGBO(59, 130, 246, 0.1),
          ),
          child: Center(
            child: Icon(
              Icons.drag_indicator,
              size: 36,
              color: Colors.blue,
            ),
          ),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: isTarget 
              ? Border.all(color: Colors.blue.withOpacity(0.5), width: 2)
              : null,
          ),
          child: Opacity(
            opacity: isTarget ? 0.7 : 1.0,
            child: cardWidget,
          ),
        ),
      );
    },
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
