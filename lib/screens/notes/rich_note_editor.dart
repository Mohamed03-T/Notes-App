import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../repositories/notes_repository.dart';
import '../../utils/responsive.dart';
import '../../core/layout/layout_helpers.dart';
import 'dart:async';

/// محرر نصوص غني (Rich Text Editor) للملاحظات
class RichNoteEditor extends StatefulWidget {
  final String? pageId;
  final String? folderId;
  final String? initialTitle;
  final String? initialContent;
  final int? initialColor;

  const RichNoteEditor({
    super.key,
    this.pageId,
    this.folderId,
    this.initialTitle,
    this.initialContent,
    this.initialColor,
  });

  @override
  State<RichNoteEditor> createState() => _RichNoteEditorState();
}

class _RichNoteEditorState extends State<RichNoteEditor> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  
  bool _isBold = false;
  bool _isItalic = false;
  bool _isUnderline = false;
  double _fontSize = 16.0;
  Color _textColor = Colors.black87;
  TextAlign _textAlign = TextAlign.start;
  int? _backgroundColor;
  
  bool _isSaving = false;
  Timer? _autoSaveTimer;
  bool _showFormatToolbar = false; // إظهار/إخفاء شريط التنسيق

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
    _contentController = TextEditingController(text: widget.initialContent ?? '');
    _backgroundColor = widget.initialColor;
    
    // الحفظ التلقائي كل 30 ثانية
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_hasContent) _autoSave();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _autoSaveTimer?.cancel();
    super.dispose();
  }

  bool get _hasContent =>
      _titleController.text.trim().isNotEmpty ||
      _contentController.text.trim().isNotEmpty;

  Future<void> _autoSave() async {
    if (!_hasContent) return;
    await _saveNote(showMessage: false);
  }

  Future<void> _saveNote({bool showMessage = true}) async {
    if (!_hasContent) {
      if (showMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.composerError('لا يوجد محتوى للحفظ'))),
        );
      }
      return;
    }

    setState(() => _isSaving = true);

    try {
      final repo = await NotesRepository.instance;
      final title = _titleController.text.trim();
      final content = _contentController.text.trim();
      
      // دمج العنوان مع المحتوى
      final fullContent = title.isEmpty ? content : '$title\n$content';

      bool success;
      if (widget.pageId != null && widget.folderId != null) {
        success = await repo.saveNoteToFolder(
          fullContent,
          widget.pageId!,
          widget.folderId!,
          colorValue: _backgroundColor,
        );
      } else {
        success = await repo.saveNoteSimple(
          fullContent,
          colorValue: _backgroundColor,
        );
      }

      setState(() => _isSaving = false);

      if (success) {
        if (showMessage) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.composerSavedSuccess),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.composerSavedFailure),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.composerError(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  TextStyle get _currentTextStyle {
    return TextStyle(
      fontSize: _fontSize,
      fontWeight: _isBold ? FontWeight.bold : FontWeight.normal,
      fontStyle: _isItalic ? FontStyle.italic : FontStyle.normal,
      decoration: _isUnderline ? TextDecoration.underline : TextDecoration.none,
      color: _textColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = _backgroundColor != null 
        ? Color(_backgroundColor!) 
        : (isDark ? Colors.grey.shade900 : Colors.white);

    return WillPopScope(
      onWillPop: () async {
        if (_hasContent) {
          final shouldSave = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('حفظ التغييرات؟'),
              content: Text('هل تريد حفظ الملاحظة قبل الخروج؟'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('خروج بدون حفظ'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text('حفظ'),
                ),
              ],
            ),
          );
          
          if (shouldSave == true) {
            await _saveNote(showMessage: false);
          }
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: bgColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            widget.initialTitle != null ? 'تعديل الملاحظة' : 'ملاحظة جديدة',
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          ),
          actions: [
            if (_isSaving)
              Container(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              IconButton(
                icon: Icon(Icons.save, color: Colors.blue),
                onPressed: _saveNote,
                tooltip: 'حفظ',
              ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: isDark ? Colors.white : Colors.black87),
              onSelected: (value) {
                switch (value) {
                  case 'color':
                    _showColorPicker();
                    break;
                  case 'clear':
                    _clearAll();
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'color',
                  child: Row(
                    children: [
                      Icon(Icons.palette, size: 20),
                      SizedBox(width: 12),
                      Text('تغيير اللون'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 20, color: Colors.red),
                      SizedBox(width: 12),
                      Text('مسح الكل', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            // زر Aa لإظهار شريط الأدوات
            if (!_showFormatToolbar)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.wp(context, 2),
                  vertical: Responsive.hp(context, 1),
                ),
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                child: Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => setState(() => _showFormatToolbar = true),
                      icon: Icon(Icons.text_fields, size: 20),
                      label: Text('Aa'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                    Spacer(),
                    Text(
                      'أدوات التنسيق',
                      style: TextStyle(
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            
            // شريط الأدوات الكامل (Toolbar)
            if (_showFormatToolbar) _buildToolbar(isDark),
            
            if (_showFormatToolbar)
              Divider(height: 1, color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
            
            // منطقة التحرير
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(Layout.horizontalPadding(context)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // حقل العنوان
                    TextField(
                      controller: _titleController,
                      style: TextStyle(
                        fontSize: Responsive.sp(context, 3.2),
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: 'العنوان...',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                        ),
                        border: InputBorder.none,
                      ),
                      maxLines: null,
                    ),
                    
                    SizedBox(height: Layout.smallGap(context)),
                    
                    // حقل المحتوى
                    TextField(
                      controller: _contentController,
                      style: _currentTextStyle.copyWith(
                        color: isDark ? Colors.white : _textColor,
                      ),
                      decoration: InputDecoration(
                        hintText: 'ابدأ الكتابة...',
                        hintStyle: TextStyle(
                          fontSize: _fontSize,
                          color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                        ),
                        border: InputBorder.none,
                      ),
                      maxLines: null,
                      minLines: 15,
                      textAlign: _textAlign,
                      keyboardType: TextInputType.multiline,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar(bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.wp(context, 2),
        vertical: Responsive.hp(context, 1),
      ),
      color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // زر إغلاق (×)
            IconButton(
              icon: Icon(Icons.close, size: 24),
              onPressed: () => setState(() => _showFormatToolbar = false),
              tooltip: 'إخفاء الأدوات',
              color: Colors.red,
              padding: EdgeInsets.all(4),
            ),
            
            VerticalDivider(width: 16, color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
            
            // Bold
            _buildToolbarButton(
              icon: Icons.format_bold,
              isActive: _isBold,
              onPressed: () => setState(() => _isBold = !_isBold),
              tooltip: 'عريض',
              isDark: isDark,
            ),
            
            // Italic
            _buildToolbarButton(
              icon: Icons.format_italic,
              isActive: _isItalic,
              onPressed: () => setState(() => _isItalic = !_isItalic),
              tooltip: 'مائل',
              isDark: isDark,
            ),
            
            // Underline
            _buildToolbarButton(
              icon: Icons.format_underline,
              isActive: _isUnderline,
              onPressed: () => setState(() => _isUnderline = !_isUnderline),
              tooltip: 'تسطير',
              isDark: isDark,
            ),
            
            VerticalDivider(width: 20, color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
            
            // Font Size
            _buildToolbarButton(
              icon: Icons.text_increase,
              onPressed: () => setState(() {
                if (_fontSize < 32) _fontSize += 2;
              }),
              tooltip: 'تكبير الخط',
              isDark: isDark,
            ),
            
            _buildToolbarButton(
              icon: Icons.text_decrease,
              onPressed: () => setState(() {
                if (_fontSize > 12) _fontSize -= 2;
              }),
              tooltip: 'تصغير الخط',
              isDark: isDark,
            ),
            
            VerticalDivider(width: 20, color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
            
            // Text Align
            _buildToolbarButton(
              icon: Icons.format_align_right,
              isActive: _textAlign == TextAlign.right,
              onPressed: () => setState(() => _textAlign = TextAlign.right),
              tooltip: 'يمين',
              isDark: isDark,
            ),
            
            _buildToolbarButton(
              icon: Icons.format_align_center,
              isActive: _textAlign == TextAlign.center,
              onPressed: () => setState(() => _textAlign = TextAlign.center),
              tooltip: 'وسط',
              isDark: isDark,
            ),
            
            _buildToolbarButton(
              icon: Icons.format_align_left,
              isActive: _textAlign == TextAlign.left,
              onPressed: () => setState(() => _textAlign = TextAlign.left),
              tooltip: 'يسار',
              isDark: isDark,
            ),
            
            VerticalDivider(width: 20, color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
            
            // Text Color
            _buildColorButton(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    required bool isDark,
    bool isActive = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: isActive 
            ? (isDark ? Colors.blue.shade700 : Colors.blue.shade100)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              size: 24,
              color: isActive 
                  ? Colors.blue 
                  : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColorButton(bool isDark) {
    return PopupMenuButton<Color>(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.format_color_text,
              size: 24,
              color: _textColor,
            ),
            SizedBox(width: 4),
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: _textColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade400),
              ),
            ),
          ],
        ),
      ),
      itemBuilder: (context) => [
        _buildColorMenuItem(Colors.black87, 'أسود'),
        _buildColorMenuItem(Colors.red, 'أحمر'),
        _buildColorMenuItem(Colors.blue, 'أزرق'),
        _buildColorMenuItem(Colors.green, 'أخضر'),
        _buildColorMenuItem(Colors.orange, 'برتقالي'),
        _buildColorMenuItem(Colors.purple, 'بنفسجي'),
      ],
      onSelected: (color) => setState(() => _textColor = color),
    );
  }

  PopupMenuItem<Color> _buildColorMenuItem(Color color, String label) {
    return PopupMenuItem(
      value: color,
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade400),
            ),
          ),
          SizedBox(width: 12),
          Text(label),
        ],
      ),
    );
  }

  void _showColorPicker() {
    final colors = [
      null, // No color
      Colors.red.shade100.value,
      Colors.blue.shade100.value,
      Colors.green.shade100.value,
      Colors.yellow.shade100.value,
      Colors.purple.shade100.value,
      Colors.orange.shade100.value,
      Colors.pink.shade100.value,
      Colors.teal.shade100.value,
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('اختر لون الخلفية'),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: colors.map((colorValue) {
            return GestureDetector(
              onTap: () {
                setState(() => _backgroundColor = colorValue);
                Navigator.pop(context);
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorValue != null ? Color(colorValue) : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _backgroundColor == colorValue 
                        ? Colors.blue 
                        : Colors.grey.shade300,
                    width: _backgroundColor == colorValue ? 3 : 1,
                  ),
                ),
                child: colorValue == null 
                    ? Icon(Icons.block, color: Colors.grey) 
                    : null,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _clearAll() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تأكيد المسح'),
        content: Text('هل أنت متأكد من مسح جميع المحتويات؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _titleController.clear();
                _contentController.clear();
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('مسح'),
          ),
        ],
      ),
    );
  }
}
