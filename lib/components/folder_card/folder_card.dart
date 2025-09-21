import 'package:flutter/material.dart';
import '../../models/folder_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/layout/layout_helpers.dart';
import '../../utils/responsive.dart';
import '../../generated/l10n/app_localizations.dart';

class FolderCard extends StatefulWidget {
  final FolderModel folder;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onDoubleTap; // إضافة callback للنقر المزدوج
  final bool isDragging;  // add flag

  const FolderCard({Key? key, required this.folder, this.onTap, this.onDelete, this.onDoubleTap, this.isDragging = false}) : super(key: key);

  @override
  State<FolderCard> createState() => _FolderCardState();
}

class _FolderCardState extends State<FolderCard> with SingleTickerProviderStateMixin {
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
    if (updatedAt == null) return AppLocalizations.of(context)!.now; // fall back
    
    try {
      final now = DateTime.now();
      final difference = now.difference(updatedAt);
      
      if (difference.inDays > 0) {
        return AppLocalizations.of(context)!.daysAgo(difference.inDays);
      } else if (difference.inHours > 0) {
        return AppLocalizations.of(context)!.hoursAgo(difference.inHours);
      } else if (difference.inMinutes > 0) {
        return AppLocalizations.of(context)!.minutesAgo(difference.inMinutes);
      } else {
        return AppLocalizations.of(context)!.now;
      }
    } catch (e) {
      return 'وقت غير محدد';
    }
  }

  @override
  Widget build(BuildContext context) {
    final notesCount = widget.folder.notes.length;
    final hasNotes = notesCount > 0;
    final timeAgo = _getTimeAgo(widget.folder.updatedAt);
  final baseBg = widget.folder.backgroundColor ?? AppTheme.getCardColor(context);
  final bgColor = Color.fromRGBO((baseBg.r * 255).round(), (baseBg.g * 255).round(), (baseBg.b * 255).round(), widget.isDragging ? 0.5 : 1.0);
    
    Widget card = AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            // تعطيل التفاعل عندما يكون في وضع السحب
            onTap: widget.isDragging ? null : () {
              // Handle single tap
              if (widget.onTap != null) {
                widget.onTap!();
              }
            },
            onDoubleTap: widget.isDragging ? null : () {
              // Handle double tap - show context menu
              if (widget.onDoubleTap != null) {
                widget.onDoubleTap!();
              }
            },
            onTapDown: widget.isDragging ? null : (details) {
              _animationController.forward();
            },
            onTapUp: widget.isDragging ? null : (_) {
              _animationController.reverse();
            },
            onTapCancel: widget.isDragging ? null : () {
              _animationController.reverse();
            },
                child: Container(
              margin: EdgeInsets.all(Responsive.wp(context, 2)),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.getCardShadow(context),
                border: Border.all(
                  color: Color.fromRGBO((AppTheme.getBorderColor(context).r * 255).round(), (AppTheme.getBorderColor(context).g * 255).round(), (AppTheme.getBorderColor(context).b * 255).round(), 0.1),
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
                    padding: EdgeInsets.symmetric(vertical: Responsive.hp(context, 1.2), horizontal: Layout.horizontalPadding(context)),
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
                              fontSize: Layout.titleFont(context),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (widget.folder.isPinned) ...[
                          SizedBox(width: Layout.smallGap(context)),
                          Icon(
                            Icons.push_pin,
                            size: Layout.iconSize(context),
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ],
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: Responsive.wp(context, 2.2), vertical: Responsive.hp(context, 0.6)),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Color.fromRGBO((Theme.of(context).colorScheme.primary.r * 255).round(), (Theme.of(context).colorScheme.primary.g * 255).round(), (Theme.of(context).colorScheme.primary.b * 255).round(), 0.3),
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
                              fontSize: Layout.bodyFont(context),
                            ),
                          ),
                        ),
                        // Three-dot menu for folder actions
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert, color: AppTheme.getTextSecondary(context), size: Layout.iconSize(context)),
                          onSelected: (value) async {
                            switch (value) {
                              case 'pin':
                                setState(() {
                                  widget.folder.isPinned = !widget.folder.isPinned;
                                });
                                break;
                              case 'rename':
                                final newName = await showDialog<String>(
                                  context: context,
                                  builder: (ctx) {
                                    final controller = TextEditingController(text: widget.folder.title);
                                    return AlertDialog(
                                      title: Text(AppLocalizations.of(context)!.renameFolder),
                                      content: TextField(controller: controller),
                                      actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.of(context)!.cancel)),
                                          TextButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: Text(AppLocalizations.of(context)!.confirm)),
                                      ],
                                    );
                                  },
                                );
                                if (newName != null && newName.isNotEmpty) {
                                  setState(() { widget.folder.title = newName; });
                                }
                                break;
                              case 'color':
                                final colors = [Colors.red, Colors.orange, Colors.yellow, Colors.green, Colors.blue, Colors.indigo, Colors.purple, Colors.pink, Colors.teal, Colors.brown];
                                final chosen = await showDialog<Color>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: Text(AppLocalizations.of(context)!.selectBackgroundColor),
                                    content: SingleChildScrollView(
                                      child: Wrap(
                                        spacing: 8, runSpacing: 8,
                                        children: colors.map((c) => GestureDetector(
                                          onTap: () => Navigator.pop(ctx, c),
                        child: Container(width: Responsive.wp(context, 8), height: Responsive.wp(context, 8), decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: widget.folder.backgroundColor == c ? Border.all(color: Colors.white, width: 2) : null)),
                                        )).toList(),
                                      ),
                                    ),
                                  ),
                                );
                                if (chosen != null) setState(() { widget.folder.backgroundColor = chosen; });
                                break;
                              case 'delete':
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: Text(AppLocalizations.of(context)!.confirmDelete),
                                    content: Text(AppLocalizations.of(context)!.deleteConfirmMessage(widget.folder.title)),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.of(context)!.cancel)),
                                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(AppLocalizations.of(context)!.delete, style: const TextStyle(color: Colors.red))),
                                    ],
                                  ),
                                );
                                if (confirm == true && widget.onDelete != null) widget.onDelete!();
                                break;
                            }
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(value: 'pin', child: Text(widget.folder.isPinned ? AppLocalizations.of(context)!.unpinFolder : AppLocalizations.of(context)!.pinFolder)),
                            PopupMenuItem(value: 'rename', child: Text(AppLocalizations.of(context)!.renameFolder)),
                            PopupMenuItem(value: 'color', child: Text(AppLocalizations.of(context)!.changeBackgroundColor)),
                            PopupMenuItem(value: 'delete', child: Text(AppLocalizations.of(context)!.delete, style: const TextStyle(color: Colors.red))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Preview content area  
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(Responsive.wp(context, 1)),
                    child: hasNotes ? _buildNotesPreview() : _buildEmptyState(),
                  ),
                  
                  // Footer with timestamp
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: Layout.horizontalPadding(context) * 0.6, vertical: Responsive.hp(context, 1.0)),
                    decoration: BoxDecoration(
                      color: Color.fromRGBO((AppTheme.getDividerColor(context).r * 255).round(), (AppTheme.getDividerColor(context).g * 255).round(), (AppTheme.getDividerColor(context).b * 255).round(), 0.3),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: Responsive.sp(context, 1.4),
                          color: AppTheme.getTextSecondary(context),
                        ),
                        SizedBox(width: Layout.smallGap(context)),
                        Text(
                          timeAgo,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.getTextSecondary(context),
                            fontSize: Layout.bodyFont(context),
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: Responsive.sp(context, 1.1),
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

    return card;
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
              color: Color.fromRGBO((Theme.of(context).colorScheme.primary.r * 255).round(), (Theme.of(context).colorScheme.primary.g * 255).round(), (Theme.of(context).colorScheme.primary.b * 255).round(), 0.05),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: Color.fromRGBO((Theme.of(context).colorScheme.primary.r * 255).round(), (Theme.of(context).colorScheme.primary.g * 255).round(), (Theme.of(context).colorScheme.primary.b * 255).round(), 0.1),
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
                    color: Color.fromRGBO((Theme.of(context).colorScheme.primary.r * 255).round(), (Theme.of(context).colorScheme.primary.g * 255).round(), (Theme.of(context).colorScheme.primary.b * 255).round(), 0.6),
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
            color: Color.fromRGBO((Theme.of(context).colorScheme.primary.r * 255).round(), (Theme.of(context).colorScheme.primary.g * 255).round(), (Theme.of(context).colorScheme.primary.b * 255).round(), 0.6),
          ),
          const SizedBox(height: 2),
          Text(
            AppLocalizations.of(context)!.noNotes,
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
