import 'package:flutter/material.dart';
import '../../repositories/notes_repository.dart';
import 'add_page_screen.dart';
import '../../core/layout/layout_helpers.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../utils/responsive.dart';

class AllPagesScreen extends StatefulWidget {
  const AllPagesScreen({Key? key}) : super(key: key);

  @override
  _AllPagesScreenState createState() => _AllPagesScreenState();
}

class _AllPagesScreenState extends State<AllPagesScreen> {

  @override
  Widget build(BuildContext context) {
    final repo = NotesRepository();
    final allPages = repo.getPages();
    final sortedPages = repo.getPagesSortedByActivity();
    
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.allPagesTitle),
        backgroundColor: Colors.blue.shade50,
        actions: [
          IconButton(
            onPressed: () async {
              final result = await Navigator.push<String>(
                context,
                MaterialPageRoute(builder: (context) => const AddPageScreen()),
              );
              
              if (result != null) {
                // تحديث الشاشة بعد إضافة صفحة جديدة
                setState(() {});
              }
            },
            icon: const Icon(Icons.add),
            tooltip: l10n.addNewPage,
          ),
        ],
      ),
      body: Container(
        color: Colors.grey.shade50,
        child: ListView.builder(
          padding: EdgeInsets.all(Layout.horizontalPadding(context)),
          itemCount: sortedPages.length,
          itemBuilder: (context, index) {
            final page = sortedPages[index];
            final originalIndex = allPages.indexWhere((p) => p.id == page.id);
            
            return Container(
              margin: EdgeInsets.only(bottom: Layout.sectionSpacing(context) * 0.6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Color.fromRGBO(128, 128, 128, 0.1),
                    spreadRadius: 1,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: EdgeInsets.all(Layout.horizontalPadding(context) * 0.6),
                leading: Container(
                  width: Responsive.wp(context, 10),
                  height: Responsive.wp(context, 10),
                  decoration: BoxDecoration(
                    color: _getPageColor(index),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getPageIcon(page.title),
                    color: Colors.white,
                    size: Responsive.sp(context, 2.4),
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        page.title,
                        style: TextStyle(
                          fontSize: Responsive.sp(context, 2.6),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (index == 0)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: Responsive.wp(context, 2.2), vertical: Responsive.hp(context, 0.8)),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          l10n.latest,
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: Layout.bodyFont(context) * 0.9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: Layout.smallGap(context) * 0.4),
                    Text(
                      l10n.foldersCount(page.folders.length),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: Layout.bodyFont(context),
                      ),
                    ),
                    SizedBox(height: Layout.smallGap(context) * 0.4),
                    Text(
                      l10n.lastUpdated(_getTimeAgo(page.folders)),
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: Layout.bodyFont(context) * 0.9,
                      ),
                    ),
                  ],
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey.shade400,
                  size: Responsive.sp(context, 1.6),
                ),
                onTap: () {
                  Navigator.pop(context, originalIndex);
                },
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<String>(
            context,
            MaterialPageRoute(builder: (context) => const AddPageScreen()),
          );
          
          if (result != null) {
            // تحديث الشاشة بعد إضافة صفحة جديدة
            setState(() {});
          }
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
