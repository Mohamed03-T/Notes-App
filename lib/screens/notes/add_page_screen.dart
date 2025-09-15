import 'package:flutter/material.dart';
import '../../repositories/notes_repository.dart';

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
        title: const Text('إضافة صفحة جديدة'),
        backgroundColor: Colors.grey.shade800,
        foregroundColor: Colors.grey.shade200,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade700),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.pages,
                    size: 48,
                    color: Colors.grey.shade200,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'إنشاء صفحة جديدة',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade100,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'أضف صفحة جديدة لتنظيم ملاحظاتك بشكل أفضل',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade300,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'اسم الصفحة',
                hintText: 'مثال: مشاريع، أفكار، مهام...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.title),
              ),
              onSubmitted: (_) => _createPage(),
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isCreating ? null : _createPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isCreating
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('جاري الإنشاء...'),
                      ],
                    )
                  : const Text(
                      'إنشاء الصفحة',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'إلغاء',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
