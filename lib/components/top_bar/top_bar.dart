import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  final List<String> pages;
  final int currentPageIndex;
  final Function(int)? onPageSelected;
  final List<int>? originalIndices; // mapping from displayed pages to original indices
  final VoidCallback? onMorePressed;

  const TopBar({
    Key? key,
    this.pages = const [],
    this.currentPageIndex = 0,
    this.onPageSelected,
    this.originalIndices,
    this.onMorePressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const maxVisiblePages = 3; // إظهار 3 صفحات في الشريط
    
  // ترتيب الصفحات بحيث تظهر الصفحة الحالية دائماً
  List<String> visiblePages = [];
  List<int> visibleIndices = [];
    
    if (pages.length <= maxVisiblePages) {
      // إذا كان عدد الصفحات أقل من أو يساوي 3، اظهرها جميعاً
      visiblePages = List.from(pages);
      visibleIndices = List.generate(pages.length, (index) => index);
    } else {
      // إذا كان هناك أكثر من 3 صفحات، اظهر الصفحة الحالية و الصفحتين التاليتين
      visibleIndices.add(currentPageIndex);
      visiblePages.add(pages[currentPageIndex]);
      
      // إضافة صفحتين إضافيتين
      int added = 1;
      for (int i = 0; i < pages.length && added < maxVisiblePages; i++) {
        if (i != currentPageIndex) {
          visibleIndices.add(i);
          visiblePages.add(pages[i]);
          added++;
        }
      }
    }
    
    return AppBar(
      toolbarHeight: AppTokens.topBarHeight,
      title: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // إظهار الصفحات المرئية
            for (var i = 0; i < visiblePages.length; i++)
              Padding(
                padding: const EdgeInsets.only(left: 6.0),
                child: GestureDetector(
                  onTap: () {
                    // map the displayed index back to the original index if provided
                    final int originalIndex = (originalIndices != null && visibleIndices[i] < originalIndices!.length)
                        ? originalIndices![visibleIndices[i]]
                        : visibleIndices[i];
                    onPageSelected?.call(originalIndex);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      // determine if this displayed page corresponds to the selected original index
                      color: ((originalIndices != null && visibleIndices[i] < originalIndices!.length)
                              ? (originalIndices![visibleIndices[i]] == currentPageIndex)
                              : (visibleIndices[i] == currentPageIndex))
                          ? Colors.blue.shade100
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: ((originalIndices != null && visibleIndices[i] < originalIndices!.length)
                                ? (originalIndices![visibleIndices[i]] == currentPageIndex)
                                : (visibleIndices[i] == currentPageIndex))
                            ? Colors.blue.shade300
                            : Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      visiblePages[i],
                      style: TextStyle(
                        color: ((originalIndices != null && visibleIndices[i] < originalIndices!.length)
                                ? (originalIndices![visibleIndices[i]] == currentPageIndex)
                                : (visibleIndices[i] == currentPageIndex))
                            ? Colors.blue.shade700
                            : Colors.grey.shade700,
                        fontWeight: ((originalIndices != null && visibleIndices[i] < originalIndices!.length)
                                ? (originalIndices![visibleIndices[i]] == currentPageIndex)
                                : (visibleIndices[i] == currentPageIndex))
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            
            // زر "المزيد" إذا كان هناك صفحات إضافية
            if (pages.length > maxVisiblePages)
              Padding(
                padding: const EdgeInsets.only(left: 6.0),
                child: GestureDetector(
                  onTap: onMorePressed,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
                          size: 14,
                          color: Colors.orange.shade700,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '+${pages.length - maxVisiblePages}',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(AppTokens.topBarHeight);
}
