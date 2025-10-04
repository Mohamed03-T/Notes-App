import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../screens/notes/add_note_screen.dart';
import '../../repositories/notes_repository.dart';
import '../color_picker/dialog_color_picker.dart';
import '../attachment/attachment_picker.dart';
import '../../core/layout/layout_helpers.dart';
import '../../utils/responsive.dart';

class ComposerBar extends StatefulWidget {
  final void Function(String, int?, List<String>?)? onSend;
  final List<dynamic>? attachments;
  // دالة callback تستدعى عند تغيير حالة النص (موجود/غير موجود)
  final void Function(bool)? onTextChanged;

  const ComposerBar({super.key, this.onSend, this.attachments, this.onTextChanged});

  @override
  ComposerBarState createState() => ComposerBarState();
}

class ComposerBarState extends State<ComposerBar> with SingleTickerProviderStateMixin {
  late TextEditingController _controller;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _hasText = false;
  bool _showStats = false;

  /// Public getter so parent widgets can query current text state synchronously.
  bool get hasText => _hasText;
  
  // إحصائيات النص
  int get _wordCount {
    if (_controller.text.trim().isEmpty) return 0;
    return _controller.text.trim().split(RegExp(r'\s+')).length;
  }
  
  int get _charCount => _controller.text.length;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _hasText = _controller.text.trim().isNotEmpty;
    
    // إعداد الأنيميشن
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _hasText) {
        setState(() => _hasText = hasText);
        if (widget.onTextChanged != null) {
          widget.onTextChanged!(hasText);
        }
        if (kDebugMode) {
          debugPrint('ComposerBar: text state changed: $_hasText');
        }
        // تشغيل أنيميشن عند تغيير الحالة
        if (hasText) {
          _animationController.forward().then((_) => _animationController.reverse());
        }
      } else {
        // تحديث العداد فقط
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  List<String> _attachments = [];
  bool get _hasAttachments => _attachments.isNotEmpty || (widget.attachments?.isNotEmpty ?? false);

  /// دالة لمسح النص من الخارج (تستدعى من الشاشة الأب عند الضغط على زر الرجوع)
  void clearText() {
    _controller.clear();
    setState(() {
      _hasText = false;
    });
    // إبلاغ الشاشة الأب أن النص تم مسحه
    if (widget.onTextChanged != null) {
      widget.onTextChanged!(false);
    }
  }

  int? _selectedColor;

  Future<void> _handlePrimaryAction() async {
  if (kDebugMode) debugPrint('ComposerBar: primary action pressed, hasText=$_hasText, hasAttachments=$_hasAttachments');
    
    if (_hasText || _hasAttachments) {
  if (kDebugMode) debugPrint('🚀 محاولة إرسال الملاحظة...');
      final content = _controller.text.trim();
      
      if (content.isEmpty) {
  if (kDebugMode) debugPrint('❌ النص فارغ بعد trim!');
        return;
      }

    // استدعاء callback function إذا كانت متوفرة
  if (widget.onSend != null) {
  if (kDebugMode) debugPrint('📞 استدعاء onSend callback...');
        
        // مسح النص وإبلاغ الـ parent فوراً قبل استدعاء onSend
        _controller.clear();
        setState(() {
          _hasText = false;
        });
        // إبلاغ الـ parent أن النص تم مسحه
        if (widget.onTextChanged != null) {
          widget.onTextChanged!(false);
        }
        
  // الآن استدعاء onSend مع لون وقائمة المرفقات
  final allAttachments = <String>[];
  if (widget.attachments != null) allAttachments.addAll(widget.attachments!.map((e) => e.toString()));
  allAttachments.addAll(_attachments);
  widget.onSend!(content, _selectedColor, allAttachments.isEmpty ? null : allAttachments);
      } else {
        try {
          final repo = NotesRepository();
          final success = await repo.saveNoteSimple(content, colorValue: _selectedColor);

          if (success) {
            _controller.clear();
            setState(() {
              _hasText = false;
            });
            if (widget.onTextChanged != null) {
              widget.onTextChanged!(false);
            }
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context)!.composerSavedSuccess))
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context)!.composerSavedFailure))
              );
            }
          }
            } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppLocalizations.of(context)!.composerError(e.toString())))
            );
          }
        }
      }
    } else {
  if (kDebugMode) debugPrint('➕ فتح خيارات الإضافة...');
      _showAddOptions();
    }
  }

  void _openAddNote() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddNoteScreen()));
  }

  void _showAddOptions() {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.note),
                title: Text(AppLocalizations.of(context)!.composerOptionSimple),
                onTap: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddNoteScreen(noteType: NoteType.simple)));
                },
              ),
              ListTile(
                leading: const Icon(Icons.article),
                title: Text(AppLocalizations.of(context)!.composerOptionArticle),
                onTap: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddNoteScreen(noteType: NoteType.article)));
                },
              ),
              ListTile(
                leading: const Icon(Icons.email),
                title: Text(AppLocalizations.of(context)!.composerOptionEmail),
                onTap: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddNoteScreen(noteType: NoteType.email)));
                },
              ),
              ListTile(
                leading: const Icon(Icons.check_box),
                title: Text(AppLocalizations.of(context)!.composerOptionChecklist),
                onTap: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddNoteScreen(noteType: NoteType.checklist)));
                },
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: Text(AppLocalizations.of(context)!.composerOptionCancel),
                onTap: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
  if (kDebugMode) debugPrint('ComposerBar: build called, _hasText = $_hasText');
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade900 : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // شريط الإحصائيات (يظهر عند الكتابة)
            if (_hasText && _showStats)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Layout.horizontalPadding(context),
                  vertical: Responsive.hp(context, 0.6),
                ),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatChip(
                      context,
                      Icons.text_fields,
                      '${AppLocalizations.of(context)!.noteTypeText}: $_charCount',
                      isDark,
                    ),
                    _buildStatChip(
                      context,
                      Icons.subject,
                      'كلمات: $_wordCount',
                      isDark,
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => setState(() => _showStats = false),
                      icon: Icon(
                        Icons.keyboard_arrow_down,
                        size: Responsive.sp(context, 2.0),
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            
            // معاينة المرفقات
            if (_attachments.isNotEmpty)
              Container(
                height: Responsive.hp(context, 8),
                padding: EdgeInsets.symmetric(
                  horizontal: Layout.horizontalPadding(context),
                  vertical: Responsive.hp(context, 0.8),
                ),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _attachments.length,
                  itemBuilder: (context, index) {
                    return _buildAttachmentPreview(context, _attachments[index], index, isDark);
                  },
                ),
              ),
            
            // شريط الأدوات الرئيسي
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: Layout.horizontalPadding(context) * 0.5,
                vertical: Responsive.hp(context, 1.2),
              ),
              child: Row(
                children: [
                  // زر اختيار اللون
                  _buildToolButton(
                    context,
                    icon: Icons.palette,
                    color: _selectedColor != null ? Color(_selectedColor!) : null,
                    onPressed: () async {
                      final picked = await showColorPickerDialog(context, initialColor: _selectedColor);
                      if (picked != null) setState(() => _selectedColor = picked);
                    },
                    isDark: isDark,
                  ),
                  
                  // زر إضافة صورة
                  _buildToolButton(
                    context,
                    icon: Icons.photo,
                    badge: _attachments.isNotEmpty ? _attachments.length.toString() : null,
                    onPressed: () async {
                      final path = await showAttachmentPathDialog(context);
                      if (path != null && path.isNotEmpty) {
                        setState(() => _attachments.add(path));
                      }
                    },
                    isDark: isDark,
                  ),
                  
                  // زر الميكروفون
                  _buildToolButton(
                    context,
                    icon: Icons.mic,
                    onPressed: () {
                      // TODO: إضافة ميزة التسجيل الصوتي
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('قريباً: التسجيل الصوتي')),
                      );
                    },
                    isDark: isDark,
                  ),
                  
                  // حقل النص
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.wp(context, 3),
                        vertical: Responsive.hp(context, 0.8),
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: TextField(
                        controller: _controller,
                        maxLines: 3,
                        minLines: 1,
                        decoration: InputDecoration.collapsed(
                          hintText: AppLocalizations.of(context)!.composerHint,
                          hintStyle: TextStyle(
                            color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                          ),
                        ),
                        style: TextStyle(
                          fontSize: Layout.bodyFont(context),
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        onSubmitted: (text) {
                          if (text.trim().isNotEmpty) {
                            _handlePrimaryAction();
                          }
                        },
                      ),
                    ),
                  ),
                  
                  SizedBox(width: Responsive.wp(context, 1)),
                  
                  // زر الإحصائيات (يظهر عند وجود نص)
                  if (_hasText && !_showStats)
                    _buildToolButton(
                      context,
                      icon: Icons.info_outline,
                      onPressed: () => setState(() => _showStats = true),
                      isDark: isDark,
                    ),
                  
                  // زر الإرسال مع أنيميشن
                  GestureDetector(
                    onLongPress: _openAddNote,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: (_hasText || _hasAttachments)
                              ? LinearGradient(
                                  colors: [
                                    theme.colorScheme.primary,
                                    theme.colorScheme.primary.withOpacity(0.8),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: (_hasText || _hasAttachments) ? null : Colors.grey.shade400,
                          shape: BoxShape.circle,
                          boxShadow: (_hasText || _hasAttachments)
                              ? [
                                  BoxShadow(
                                    color: theme.colorScheme.primary.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : [],
                        ),
                        child: IconButton(
                          tooltip: _hasText || _hasAttachments
                              ? AppLocalizations.of(context)!.composerSend
                              : AppLocalizations.of(context)!.composerCreate,
                          onPressed: () {
                            debugPrint('ComposerBar: IconButton pressed');
                            _handlePrimaryAction();
                          },
                          icon: Icon(
                            _hasText || _hasAttachments ? Icons.send_rounded : Icons.edit_note_rounded,
                            size: Layout.iconSize(context),
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // بناء زر أداة مخصص
  Widget _buildToolButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onPressed,
    required bool isDark,
    Color? color,
    String? badge,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Icon(
            icon,
            size: Layout.iconSize(context),
            color: color ?? (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
          ),
        ),
        if (badge != null)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
  
  // بناء شريحة الإحصائيات
  Widget _buildStatChip(BuildContext context, IconData icon, String text, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.wp(context, 2),
        vertical: Responsive.hp(context, 0.4),
      ),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade700 : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: Responsive.sp(context, 1.6),
            color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
          ),
          SizedBox(width: Responsive.wp(context, 1)),
          Text(
            text,
            style: TextStyle(
              fontSize: Responsive.sp(context, 1.4),
              color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  // بناء معاينة المرفق
  Widget _buildAttachmentPreview(BuildContext context, String path, int index, bool isDark) {
    final file = File(path);
    final isImage = path.toLowerCase().endsWith('.jpg') ||
        path.toLowerCase().endsWith('.jpeg') ||
        path.toLowerCase().endsWith('.png') ||
        path.toLowerCase().endsWith('.gif');
    
    return Container(
      width: Responsive.wp(context, 16),
      margin: EdgeInsets.only(right: Responsive.wp(context, 2)),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: isImage && file.existsSync()
                ? Image.file(
                    file,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildFileIcon(isDark),
                  )
                : _buildFileIcon(isDark),
          ),
          // زر الحذف
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => setState(() => _attachments.removeAt(index)),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFileIcon(bool isDark) {
    return Center(
      child: Icon(
        Icons.attach_file,
        color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
        size: 32,
      ),
    );
  }

  // ...existing code...
}
