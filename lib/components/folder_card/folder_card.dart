import 'package:flutter/material.dart';
import '../../models/folder_model.dart';
import '../../core/theme/app_theme.dart';

class FolderCard extends StatefulWidget {
  final FolderModel folder;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const FolderCard({Key? key, required this.folder, this.onTap, this.onDelete}) : super(key: key);

  @override
  State<FolderCard> createState() => _FolderCardState();
}

class _FolderCardState extends State<FolderCard> with SingleTickerProviderStateMixin {
  // store the position where the user long-pressed
  Offset _tapPosition = Offset.zero;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  // Removed unused _isPressed flag

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _getTimeAgo(DateTime? updatedAt) {
    if (updatedAt == null) return 'لم يتم التحديث';
    
    try {
      final now = DateTime.now();
      final difference = now.difference(updatedAt);
      
      if (difference.inDays > 0) {
        return 'منذ ${difference.inDays} ${difference.inDays == 1 ? 'يوم' : 'أيام'}';
      } else if (difference.inHours > 0) {
        return 'منذ ${difference.inHours} ${difference.inHours == 1 ? 'ساعة' : 'ساعات'}';
      } else if (difference.inMinutes > 0) {
        return 'منذ ${difference.inMinutes} ${difference.inMinutes == 1 ? 'دقيقة' : 'دقائق'}';
      } else {
        return 'الآن';
      }
    } catch (e) {
      return 'وقت غير محدد';
    }
  }

  void _onTapDown(TapDownDetails details) {
    // Start press animation
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    // Reverse press animation
    _animationController.reverse();
    if (widget.onTap != null) {
      widget.onTap!();
    }
  }

  void _onTapCancel() {
    // Reverse press animation when tap is cancelled
    _animationController.reverse();
  }
  
  // Show a popup menu at tap position
  Future<void> _showContextMenu(Offset position) async {
    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      items: [
        PopupMenuItem(value: 'pin', child: Row(children: [const Icon(Icons.push_pin), const SizedBox(width: 8), const Text('تثبيت المجلد')])),
        PopupMenuItem(value: 'rename', child: Row(children: [const Icon(Icons.edit), const SizedBox(width: 8), const Text('تغيير اسم المجلد')])),
        PopupMenuItem(value: 'color', child: Row(children: [const Icon(Icons.format_paint), const SizedBox(width: 8), const Text('تغيير لون الخلفية')])),
        PopupMenuItem(value: 'delete', child: Row(children: [const Icon(Icons.delete, color: Colors.red), const SizedBox(width: 8), const Text('حذف المجلد', style: TextStyle(color: Colors.red))])),
      ],
    );
    switch (selected) {
      case 'pin':
        setState(() {
          widget.folder.isPinned = !widget.folder.isPinned;
        });
        debugPrint(widget.folder.isPinned
            ? '🔖 تم تثبيت المجلد: ${widget.folder.id}'
            : '📌 تم إلغاء تثبيت المجلد: ${widget.folder.id}');
        break;
      case 'rename':
        // Rename folder
        final newName = await showDialog<String>(
          context: context,
          builder: (ctx) {
            final controller = TextEditingController(text: widget.folder.title);
            return AlertDialog(
              title: const Text('تغيير اسم المجلد'),
              content: TextField(
                controller: controller,
                decoration: const InputDecoration(hintText: 'ادخل الاسم الجديد'),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
                TextButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('تأكيد')),
              ],
            );
          },
        );
        if (newName != null && newName.isNotEmpty) {
          setState(() { widget.folder.title = newName; });
        }
        break;
      case 'color':
        // Pick from 10 predefined colors
        final colors = <Color>[
          Colors.red,
          Colors.orange,
          Colors.yellow,
          Colors.green,
          Colors.blue,
          Colors.indigo,
          Colors.purple,
          Colors.pink,
          Colors.teal,
          Colors.brown,
        ];
        final chosen = await showDialog<Color>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('اختر لون الخلفية'),
            content: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: colors.map((c) => GestureDetector(
                  onTap: () => Navigator.pop(ctx, c),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: widget.folder.backgroundColor == c
                          ? Border.all(color: Colors.white, width: 2)
                          : null,
                    ),
                  ),
                )).toList(),
              ),
            ),
          ),
        );
        if (chosen != null) {
          setState(() { widget.folder.backgroundColor = chosen; });
        }
        break;
      case 'delete':
        // Confirm deletion
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('تأكيد الحذف'),
            content: const Text('هل تريد حذف هذا المجلد؟ لا يمكن التراجع.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف', style: TextStyle(color: Colors.red))),
            ],
          ),
        );
        if (confirm == true && widget.onDelete != null) {
          widget.onDelete!();
        }
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final notesCount = widget.folder.notes.length;
    final hasNotes = notesCount > 0;
    final timeAgo = _getTimeAgo(widget.folder.updatedAt);
    
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTap: widget.onTap,
            onTapDown: (details) {
              _onTapDown(details);
              _tapPosition = details.globalPosition;
            },
            onTapUp: _onTapUp,
            onTapCancel: _onTapCancel,
            onLongPress: () => _showContextMenu(_tapPosition),
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: widget.folder.backgroundColor ?? AppTheme.getCardColor(context),
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.getCardShadow(context),
                border: Border.all(
                  color: AppTheme.getBorderColor(context).withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with folder name and count (uses folder's backgroundColor)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    decoration: BoxDecoration(
                      color: widget.folder.backgroundColor ?? AppTheme.getCardColor(context),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.folder.title,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.getTextPrimary(context),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (widget.folder.isPinned) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.push_pin,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            '$notesCount',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Preview content area  
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(4),
                    child: hasNotes ? _buildNotesPreview() : _buildEmptyState(),
                  ),
                  
                  // Footer with timestamp
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.getDividerColor(context).withOpacity(0.3),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: AppTheme.getTextSecondary(context),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          timeAgo,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.getTextSecondary(context),
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 12,
                          color: AppTheme.getTextSecondary(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotesPreview() {
    final notesToShow = widget.folder.notes.take(3).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ...notesToShow.asMap().entries.map((entry) {
          final index = entry.key;
          final note = entry.value;
          final isLast = index == notesToShow.length - 1;
          
          return Container(
            margin: EdgeInsets.only(bottom: isLast ? 0 : 1),
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 1),
                  width: 3,
                  height: 3,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    note.content.split(' ').take(3).join(' ')
                      + (note.content.split(' ').length > 3 ? '...' : ''),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.getTextPrimary(context),
                     
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        
        // إزالة عنصر "المزيد" لتجنب overflow
        // if (widget.folder.notes.length > 2)
        //   Padding(
        //     padding: const EdgeInsets.only(top: 6),
        //     child: Container(
        //       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        //       decoration: BoxDecoration(
        //         color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
        //         borderRadius: BorderRadius.circular(12),
        //       ),
        //       child: Text(
        //         'و ${widget.folder.notes.length - 2} أخرى...',
        //         style: Theme.of(context).textTheme.bodySmall?.copyWith(
        //           color: Theme.of(context).colorScheme.secondary,
        //           fontWeight: FontWeight.w500,
        //           fontSize: 9,
        //         ),
        //       ),
        //     ),
        //   ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.note_add_outlined,
            size: 16,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
          ),
          const SizedBox(height: 2),
          Text(
            'لا توجد ملاحظات',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.getTextSecondary(context),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
