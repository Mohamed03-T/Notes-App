import 'package:flutter/material.dart';
import '../../repositories/notes_repository.dart';
import '../../core/layout/layout_helpers.dart';
import '../../utils/responsive.dart';

class AddPageScreen extends StatefulWidget {
  const AddPageScreen({Key? key}) : super(key: key);

  @override
  _AddPageScreenState createState() => _AddPageScreenState();
}

class _AddPageScreenState extends State<AddPageScreen> {
  final TextEditingController _titleController = TextEditingController();
  bool _isCreating = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _createPage() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      // SnackBar for empty title removed
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      final repo = NotesRepository();
      final pageId = repo.addNewPage(title);
      
      if (mounted) {
        // SnackBar for success removed
        Navigator.pop(context, pageId);
      }
    } catch (e) {
      if (mounted) {
        // SnackBar for error removed
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('إضافة صفحة جديدة', style: TextStyle(fontSize: Layout.titleFont(context))),
        backgroundColor: Colors.grey.shade800,
        foregroundColor: Colors.grey.shade200,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final reserved = MediaQuery.of(context).viewPadding.top + kToolbarHeight + MediaQuery.of(context).viewInsets.bottom;
          final available = Layout.availableHeight(context, reservedHeight: reserved);

          return SingleChildScrollView(
            padding: EdgeInsets.all(Layout.horizontalPadding(context)),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: available),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: EdgeInsets.all(Responsive.wp(context, 4)),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade700),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.pages,
                            size: Responsive.wp(context, 12),
                            color: Colors.grey.shade200,
                          ),
                          SizedBox(height: Layout.smallGap(context)),
                          Text(
                            'إنشاء صفحة جديدة',
                            style: TextStyle(
                              fontSize: Responsive.sp(context, 2.8),
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade100,
                            ),
                          ),
                          SizedBox(height: Layout.smallGap(context) * 0.6),
                          Text(
                            'أضف صفحة جديدة لتنظيم ملاحظاتك بشكل أفضل',
                            style: TextStyle(
                              fontSize: Layout.bodyFont(context),
                              color: Colors.grey.shade300,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: Layout.sectionSpacing(context)),
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'اسم الصفحة',
                        hintText: 'مثال: مشاريع، أفكار، مهام...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: Icon(Icons.title, size: Layout.iconSize(context)),
                      ),
                      onSubmitted: (_) => _createPage(),
                      textInputAction: TextInputAction.done,
                    ),
                    SizedBox(height: Layout.sectionSpacing(context)),
                    ElevatedButton(
                      onPressed: _isCreating ? null : _createPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: Responsive.hp(context, 1.8)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isCreating
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: Responsive.wp(context, 5),
                                  height: Responsive.wp(context, 5),
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                                SizedBox(width: Responsive.wp(context, 2.4)),
                                Text('جاري الإنشاء...', style: TextStyle(fontSize: Layout.bodyFont(context))),
                              ],
                            )
                          : Text(
                              'إنشاء الصفحة',
                              style: TextStyle(fontSize: Layout.bodyFont(context), fontWeight: FontWeight.bold),
                            ),
                    ),
                    SizedBox(height: Layout.smallGap(context)),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'إلغاء',
                        style: TextStyle(fontSize: Layout.bodyFont(context)),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
