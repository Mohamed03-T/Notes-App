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
  final String? existingNoteId; // معرّف الملاحظة الموجودة للتعديل

  const RichNoteEditor({
    super.key,
    this.pageId,
    this.folderId,
    this.initialTitle,
    this.initialContent,
    this.initialColor,
    this.existingNoteId,
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
  bool _showColorToolbar = false; // إظهار/إخفاء شريط الألوان
  bool _hasBeenSaved = false; // تتبع ما إذا تم الحفظ
  String? _savedNoteId; // معرّف الملاحظة المحفوظة

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
    _contentController = TextEditingController(text: widget.initialContent ?? '');
    _backgroundColor = widget.initialColor;
    
    // إذا كان هناك معرف ملاحظة موجود، استخدمه
    if (widget.existingNoteId != null) {
      _savedNoteId = widget.existingNoteId;
      debugPrint('📝 RichNoteEditor: فتح ملاحظة موجودة للتعديل - noteId: $_savedNoteId');
    }
    
    // إعادة تعيين حالة الحفظ عند الكتابة
    _titleController.addListener(() {
      if (_hasBeenSaved) {
        setState(() => _hasBeenSaved = false);
      }
    });
    _contentController.addListener(() {
      if (_hasBeenSaved) {
        setState(() => _hasBeenSaved = false);
      }
    });
    
    // الحفظ التلقائي كل 5 ثواني
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 5), (_) {
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
    setState(() {
      _hasBeenSaved = true;
    });
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

      String? savedId;
      bool success = false;
      
      if (widget.pageId != null && widget.folderId != null) {
        debugPrint('💾 RichNoteEditor: حفظ الملاحظة - noteId الحالي: $_savedNoteId');
        savedId = await repo.saveNoteToFolder(
          fullContent,
          widget.pageId!,
          widget.folderId!,
          noteId: _savedNoteId, // استخدام معرّف الملاحظة المحفوظة
          colorValue: _backgroundColor,
        );
        success = savedId != null;
        
        // حفظ معرّف الملاحظة للمرة القادمة
        if (savedId != null) {
          _savedNoteId = savedId;
          debugPrint('✅ RichNoteEditor: تم الحفظ بنجاح - noteId = $_savedNoteId');
        } else {
          debugPrint('❌ RichNoteEditor: فشل الحفظ');
        }
      } else {
        success = await repo.saveNoteSimple(
          fullContent,
          colorValue: _backgroundColor,
        );
      }

      setState(() {
        _isSaving = false;
        _hasBeenSaved = true;
      });

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
        debugPrint('🚪 RichNoteEditor: onWillPop called');
        // إلغاء مؤقت الحفظ التلقائي
        _autoSaveTimer?.cancel();
        
        // حفظ تلقائي عند الخروج إذا كان هناك محتوى
        if (_hasContent) {
          debugPrint('💾 RichNoteEditor: حفظ قبل الخروج...');
          await _saveNote(showMessage: false);
          debugPrint('✅ RichNoteEditor: تم الحفظ، إغلاق الصفحة مع result=true');
          // إرجاع true للإشارة إلى أنه تم حفظ البيانات
          Navigator.pop(context, true);
          return false; // منع الإغلاق التلقائي لأننا أغلقنا يدوياً
        }
        debugPrint('⚠️ RichNoteEditor: لا يوجد محتوى، إغلاق عادي');
        return true;
      },
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: bgColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black87),
            onPressed: () async {
              debugPrint('🔙 زر الرجوع في AppBar تم الضغط عليه');
              _autoSaveTimer?.cancel();
              if (_hasContent) {
                await _saveNote(showMessage: false);
              }
              Navigator.pop(context, true);
            },
          ),
          title: Text(
            widget.initialTitle != null ? 'تعديل الملاحظة' : 'ملاحظة جديدة',
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          ),
          actions: [
            // مؤشر الحفظ التلقائي
            if (_isSaving)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'جاري الحفظ...',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              )
            else if (_hasContent && _hasBeenSaved)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.cloud_done,
                      size: 16,
                      color: Colors.green,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'محفوظ',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: isDark ? Colors.white : Colors.black87),
              onSelected: (value) {
                switch (value) {
                  case 'clear':
                    _clearAll();
                    break;
                }
              },
              itemBuilder: (context) => [
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
            // الأزرار الأساسية (Aa و 🎨)
            if (!_showFormatToolbar && !_showColorToolbar)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.wp(context, 2),
                  vertical: Responsive.hp(context, 0.8),
                ),
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // زر Aa
                    ElevatedButton(
                      onPressed: () => setState(() => _showFormatToolbar = true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Aa',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    
                    SizedBox(width: 12),
                    
                    // زر الألوان 🎨
                    ElevatedButton(
                      onPressed: () => setState(() => _showColorToolbar = true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Icon(Icons.palette, size: 20),
                    ),
                  ],
                ),
              ),
            
            // شريط أدوات التنسيق (Toolbar)
            if (_showFormatToolbar) _buildToolbar(isDark),
            
            // شريط أدوات الألوان
            if (_showColorToolbar) _buildColorToolbar(isDark),
            
            if (_showFormatToolbar || _showColorToolbar)
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
                        hintText: 'العنوان',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                      maxLines: null,
                    ),
                    
                    // حقل المحتوى (بدون فاصل)
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
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
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
      child: Row(
        children: [
          // الأدوات في شريط قابل للتمرير
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
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
          ),
          
          // زر إغلاق ثابت (×)
          Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  width: 1,
                ),
              ),
            ),
            child: IconButton(
              icon: Icon(Icons.close, size: 18),
              onPressed: () => setState(() => _showFormatToolbar = false),
              tooltip: 'إخفاء',
              color: Colors.red.shade400,
              padding: EdgeInsets.all(8),
              constraints: BoxConstraints(minWidth: 40, minHeight: 40),
            ),
          ),
        ],
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

  Widget _buildColorToolbar(bool isDark) {
    final backgroundColors = [
      {'color': null, 'label': 'بدون لون'},
      {'color': Colors.red.shade100.value, 'label': 'أحمر'},
      {'color': Colors.blue.shade100.value, 'label': 'أزرق'},
      {'color': Colors.green.shade100.value, 'label': 'أخضر'},
      {'color': Colors.yellow.shade100.value, 'label': 'أصفر'},
      {'color': Colors.purple.shade100.value, 'label': 'بنفسجي'},
      {'color': Colors.orange.shade100.value, 'label': 'برتقالي'},
      {'color': Colors.pink.shade100.value, 'label': 'وردي'},
      {'color': Colors.teal.shade100.value, 'label': 'تيل'},
    ];

    final textColors = [
      {'color': Colors.black87, 'label': 'أسود'},
      {'color': Colors.red, 'label': 'أحمر'},
      {'color': Colors.blue, 'label': 'أزرق'},
      {'color': Colors.green, 'label': 'أخضر'},
      {'color': Colors.orange, 'label': 'برتقالي'},
      {'color': Colors.purple, 'label': 'بنفسجي'},
    ];

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.wp(context, 2),
        vertical: Responsive.hp(context, 1),
      ),
      color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
      child: Row(
        children: [
          // قسم ألوان الخلفية
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 4),
                    child: Text(
                      'لون الخلفية:',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Row(
                    children: backgroundColors.map((item) {
                      final colorValue = item['color'] as int?;
                      final isSelected = _backgroundColor == colorValue;
                      
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _backgroundColor = colorValue),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: colorValue != null ? Color(colorValue) : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? Colors.blue : Colors.grey.shade400,
                                width: isSelected ? 3 : 1,
                              ),
                            ),
                            child: colorValue == null 
                                ? Icon(Icons.block, color: Colors.grey, size: 20) 
                                : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 4),
                    child: Text(
                      'لون النص:',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Row(
                    children: textColors.map((item) {
                      final color = item['color'] as Color;
                      final isSelected = _textColor == color;
                      
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _textColor = color),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? Colors.blue : Colors.grey.shade400,
                                width: isSelected ? 3 : 1,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          
          // زر إغلاق ثابت (×)
          Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  width: 1,
                ),
              ),
            ),
            child: IconButton(
              icon: Icon(Icons.close, size: 18),
              onPressed: () => setState(() => _showColorToolbar = false),
              tooltip: 'إخفاء',
              color: Colors.red.shade400,
              padding: EdgeInsets.all(8),
              constraints: BoxConstraints(minWidth: 40, minHeight: 40),
            ),
          ),
        ],
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
