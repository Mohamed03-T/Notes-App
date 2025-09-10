import 'package:flutter/material.dart';
import '../../repositories/notes_repository.dart';

class AllPagesScreen extends StatelessWidget {
  const AllPagesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final repo = NotesRepository();
    final pages = repo.getPages();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('جميع الصفحات'),
        backgroundColor: Colors.blue.shade50,
      ),
      body: Container(
        color: Colors.grey.shade50,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: pages.length,
          itemBuilder: (context, index) {
            final page = pages[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getPageColor(index),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getPageIcon(page.title),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                title: Text(
                  page.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      '${page.folders.length} ${page.folders.length == 1 ? 'مجلد' : 'مجلدات'}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'آخر تحديث: ${_getTimeAgo(page.folders)}',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey.shade400,
                  size: 16,
                ),
                onTap: () {
                  Navigator.pop(context, index);
                },
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: إضافة صفحة جديدة
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('سيتم إضافة هذه الميزة قريباً')),
          );
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Color _getPageColor(int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
    ];
    return colors[index % colors.length];
  }

  IconData _getPageIcon(String title) {
    switch (title.toLowerCase()) {
      case 'شخصي':
        return Icons.person;
      case 'العمل':
        return Icons.work;
      case 'الدراسة':
        return Icons.school;
      case 'المشاريع':
        return Icons.code;
      case 'الصحة':
        return Icons.favorite;
      default:
        return Icons.folder;
    }
  }

  String _getTimeAgo(List folders) {
    if (folders.isEmpty) return 'لا توجد مجلدات';
    
    // العثور على أحدث وقت تحديث
    DateTime latestUpdate = folders.first.updatedAt;
    for (final folder in folders) {
      if (folder.updatedAt.isAfter(latestUpdate)) {
        latestUpdate = folder.updatedAt;
      }
    }
    
    final now = DateTime.now();
    final difference = now.difference(latestUpdate);
    
    if (difference.inDays > 0) {
      return 'منذ ${difference.inDays} ${difference.inDays == 1 ? 'يوم' : 'أيام'}';
    } else if (difference.inHours > 0) {
      return 'منذ ${difference.inHours} ${difference.inHours == 1 ? 'ساعة' : 'ساعات'}';
    } else if (difference.inMinutes > 0) {
      return 'منذ ${difference.inMinutes} ${difference.inMinutes == 1 ? 'دقيقة' : 'دقائق'}';
    } else {
      return 'الآن';
    }
  }
}
