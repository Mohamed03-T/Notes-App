import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  final List<String> pages;
  final int currentPageIndex;
  final Function(int)? onPageSelected;
  final VoidCallback? onMorePressed;

  const TopBar({
    Key? key, 
    this.pages = const [], 
    this.currentPageIndex = 0,
    this.onPageSelected,
    this.onMorePressed
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const maxVisiblePages = 2; // إظهار صفحتين فقط في الشريط
    
    return AppBar(
      toolbarHeight: AppTokens.topBarHeight,
      title: Row(
        children: [
          // إظهار الصفحات المرئية
          for (var i = 0; i < (pages.length > maxVisiblePages ? maxVisiblePages : pages.length); i++)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: GestureDetector(
                onTap: () => onPageSelected?.call(i),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: i == currentPageIndex ? Colors.blue.shade100 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: i == currentPageIndex ? Colors.blue.shade300 : Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    pages[i],
                    style: TextStyle(
                      color: i == currentPageIndex ? Colors.blue.shade700 : Colors.grey.shade700,
                      fontWeight: i == currentPageIndex ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          
          // زر "المزيد" إذا كان هناك صفحات إضافية
          if (pages.length > maxVisiblePages)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: GestureDetector(
                onTap: onMorePressed,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.orange.shade200,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.apps,
                        size: 16,
                        color: Colors.orange.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '+${pages.length - maxVisiblePages}',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(AppTokens.topBarHeight);
}
