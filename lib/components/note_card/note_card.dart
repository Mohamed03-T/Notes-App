import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import '../../models/note_model.dart';
import '../../utils/responsive.dart';
import '../../generated/l10n/app_localizations.dart';

class NoteCard extends StatefulWidget {
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
  State<NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<NoteCard> {
  bool _longPressMoved = false;
  Offset? _initialPointerPos;
  Timer? _longPressTimer;
  bool _dragActive = false; // set when LongPressDraggable reports onDragStarted
  static const int _actionHoldDelayMs = 300; // الوقت قبل إظهار قائمة الإجراءات
  static const int _dragHoldDelayMs = 900; // يجب أن يطابق delay الخاص بـ LongPressDraggable
  final double _moveThreshold = 6.0; // pixels to consider as movement

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final note = widget.note;

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
  margin: const EdgeInsets.symmetric(vertical: 1.5, horizontal: 4),
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
          onTap: widget.onTap,
          // سنعالج الضغط الطويل يدويًا لتمييز بين السحب وفتح القائمة
          onLongPress: null,
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
                              softWrap: true,
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
                    // إزالة زر الثلاث نقاط: سنفتح قائمة الإجراءات عبر الضغط المطول
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

  // إذا لم يتم تمرير onReorder، نعرض الكارد مباشرة ولكن نحتاج أيضاً لمعالجة الضغط الطويل
  if (widget.onReorder == null) {
    // بدون سحب، نحتاج فقط لمعالجة التفاعل الطويل الافتراضي
    return GestureDetector(
      onLongPressStart: (_) {
        _longPressMoved = false;
      },
      onLongPressMoveUpdate: (_) {
        _longPressMoved = true;
      },
      onLongPressEnd: (_) {
        final moved = _longPressMoved;
        _longPressMoved = false;
        if (!moved) {
          widget.onLongPress?.call();
        }
      },
      behavior: HitTestBehavior.translucent,
      child: cardWidget,
    );
  }

  // تغليف بـ DragTarget لاستقبال السحب (نفس طريقة المجلدات)
  return DragTarget<String>(
    onWillAcceptWithDetails: (details) => details.data != note.id,
    onAcceptWithDetails: (details) async {
      final draggedNoteId = details.data;
      debugPrint('🎯 تم قبول السحب: $draggedNoteId → ${note.id}');
      HapticFeedback.heavyImpact();
      widget.onReorder!(draggedNoteId, note.id);
    },
    builder: (context, candidateData, rejectedData) {
      final isTarget = candidateData.isNotEmpty;
      
      return LongPressDraggable<String>(
  data: note.id,
  delay: const Duration(milliseconds: _dragHoldDelayMs), // نفس delay المجلدات
        onDragStarted: () {
          HapticFeedback.mediumImpact();
          if (widget.onDragStart != null) widget.onDragStart!();
          // إذا بدأ السحب نلغي أي حالة ضغط مطول معلقة
          _longPressMoved = true;
          _dragActive = true;
          _longPressTimer?.cancel();
          debugPrint('🎯 بدأ السحب للملاحظة: ${note.id}');
        },
        onDragEnd: (_) {
          if (widget.onDragEnd != null) widget.onDragEnd!();
          // إعادة تهيئة الحالة بعد انتهاء السحب
          _longPressMoved = false;
          _dragActive = false;
          _longPressTimer?.cancel();
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
          // نلتف حول الكارد بمستقبل إيماءات لنميز بين السحب وفتح القائمة عند الضغط المطول
          child: Opacity(
            opacity: isTarget ? 0.7 : 1.0,
            // Listener فقط - لا نستخدم GestureDetector داخل Draggable لكي لا نمنع
            // LongPressDraggable من الحصول على الإيماءة. نستخدم أحداث المؤشر
            // لتحديد ما إذا كان المستخدم حرك العنصر بعد الضغط الطويل.
            child: Listener(
              onPointerDown: (ev) {
                _initialPointerPos = ev.position;
                _longPressMoved = false;
                _dragActive = false;
                // بدء مؤقت الضغط الطويل؛ بعد انتهاء المؤقت نشغل الميزتين معًا
                _longPressTimer?.cancel();
                _longPressTimer = Timer(const Duration(milliseconds: _actionHoldDelayMs), () {
                  if (!_longPressMoved && !_dragActive) {
                    widget.onLongPress?.call();
                  }
                });
              },
              onPointerMove: (ev) {
                if (_initialPointerPos != null) {
                  final dx = (ev.position.dx - _initialPointerPos!.dx).abs();
                  final dy = (ev.position.dy - _initialPointerPos!.dy).abs();
                  if (dx > _moveThreshold || dy > _moveThreshold) {
                    _longPressMoved = true;
                    // إذا تحرك المستخدم نلغي المؤقت ونعطل جاهزية الضغط الطويل
                    _longPressTimer?.cancel();
                  }
                }
              },
              onPointerUp: (ev) {
                _longPressTimer?.cancel();
                _initialPointerPos = null;
                _longPressMoved = false;
              },
              behavior: HitTestBehavior.translucent,
              child: cardWidget,
            ),
          ),
        ),
      );
    },
  );
  }

  @override
  void dispose() {
    _longPressTimer?.cancel();
    super.dispose();
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
