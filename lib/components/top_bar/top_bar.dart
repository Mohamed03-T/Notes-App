import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';
import '../../widgets/app_logo.dart';

// Class مساعد لبيانات الصفحات المرئية
class _VisiblePagesData {
  final List<String> visiblePages;
  final List<int> visibleIndices;

  _VisiblePagesData({
    required this.visiblePages,
    required this.visibleIndices,
  });
}

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  final List<String> pages;
  final int currentPageIndex;
  final Function(int)? onPageSelected;
  final List<int>? originalIndices; // mapping from displayed pages to original indices
  final VoidCallback? onMorePressed;
  final VoidCallback? onAddPagePressed; // زر إضافة صفحة جديدة
  final VoidCallback? onSettingsPressed; // زر الإعدادات
  final int? totalPagesCount; // العدد الكلي للصفحات

  const TopBar({
    Key? key,
    this.pages = const [],
    this.currentPageIndex = 0,
    this.onPageSelected,
    this.originalIndices,
    this.onMorePressed,
    this.onAddPagePressed,
    this.onSettingsPressed,
    this.totalPagesCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // حساب المساحة المتاحة للصفحات
    const double buttonSpacing = 8.0;
    const double sideMargin = 16.0;
    const double menuButtonWidth = 40.0; // عرض زر القائمة المنسدلة
    const double moreButtonWidth = 40.0; // عرض زر المزيد الجديد
    
    // المساحة المتاحة للصفحات
    double availableWidth = screenWidth - (sideMargin * 2);
    
    // خصم مساحة الأزرار الإضافية
    if (onAddPagePressed != null || onSettingsPressed != null) {
      availableWidth -= (menuButtonWidth + buttonSpacing);
    }
    
    final actualTotalPagesCount = totalPagesCount ?? pages.length;
    final bool hasMorePages = actualTotalPagesCount > pages.length;
    if (hasMorePages) {
      availableWidth -= (moreButtonWidth + buttonSpacing);
    }
    
    // حساب عدد الصفحات التي يمكن عرضها
    final estimatedPageButtonWidth = _estimatePageButtonWidth(pages);
    final maxVisiblePages = _calculateMaxVisiblePages(availableWidth, estimatedPageButtonWidth, buttonSpacing);
    
    // اختيار الصفحات المرئية بذكاء
    final visiblePagesData = _selectVisiblePages(pages, currentPageIndex, maxVisiblePages, originalIndices);
    
    final hiddenCount = (actualTotalPagesCount - visiblePagesData.visiblePages.length).clamp(0, double.infinity).toInt();
    
    return AppBar(
      toolbarHeight: AppTokens.topBarHeight,
  backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                Theme.of(context).dividerColor,
                Colors.transparent,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
      ),
      title: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            // الشعار الصغير
            const AppLogoSmall(size: 28),
            const SizedBox(width: 12),
            
            // الصفحات المرئية - تتوسع لملء المساحة المتاحة
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    for (var i = 0; i < visiblePagesData.visiblePages.length; i++)
                      _buildPageButton(
                        visiblePagesData.visiblePages[i],
                        visiblePagesData.visibleIndices[i],
                        i == 0 ? 0 : buttonSpacing,
                      ),
                  ],
                ),
              ),
            ),
            
            // زر القائمة المنسدلة
            if (onAddPagePressed != null || onSettingsPressed != null) ...[
              const SizedBox(width: buttonSpacing),
              _buildMenuButton(context),
            ],
            
            // زر "المزيد" إذا كان هناك صفحات إضافية
            if (hiddenCount > 0) ...[
              const SizedBox(width: buttonSpacing),
              _buildMoreButton(hiddenCount),
            ],
          ],
        ),
      ),
    );
  }

  // حساب عرض زر الصفحة المقدر
  double _estimatePageButtonWidth(List<String> pages) {
    if (pages.isEmpty) return 60.0;
    
    // متوسط عدد الأحرف في أسماء الصفحات
    final avgLength = pages.fold<int>(0, (sum, page) => sum + page.length) / pages.length;
    
    // تقدير العرض بناءً على عدد الأحرف (تقريباً 8 pixels لكل حرف + padding)
    return (avgLength * 8) + 20; // 20 للpadding
  }

  // حساب عدد الصفحات التي يمكن عرضها
  int _calculateMaxVisiblePages(double availableWidth, double estimatedButtonWidth, double spacing) {
    if (availableWidth <= 0) return 1;
    
    int maxPages = ((availableWidth + spacing) / (estimatedButtonWidth + spacing)).floor();
    return maxPages.clamp(1, pages.length); // على الأقل صفحة واحدة
  }

  // اختيار الصفحات المرئية بذكاء
  _VisiblePagesData _selectVisiblePages(List<String> allPages, int currentIndex, int maxVisible, List<int>? originalIndices) {
    if (allPages.length <= maxVisible) {
      return _VisiblePagesData(
        visiblePages: List.from(allPages),
        visibleIndices: List.generate(allPages.length, (index) => index),
      );
    }
    
    // تأكد من أن الصفحة الحالية ظاهرة دائماً
    List<String> visible = [];
    List<int> indices = [];
    
    // ابدأ بالصفحة الحالية
    if (currentIndex < allPages.length) {
      visible.add(allPages[currentIndex]);
      indices.add(currentIndex);
    }
    
    // أضف الصفحات المجاورة
    int leftIndex = currentIndex - 1;
    int rightIndex = currentIndex + 1;
    
    while (visible.length < maxVisible && (leftIndex >= 0 || rightIndex < allPages.length)) {
      // أضف من اليمين إذا كان متاحاً
      if (rightIndex < allPages.length && visible.length < maxVisible) {
        visible.add(allPages[rightIndex]);
        indices.add(rightIndex);
        rightIndex++;
      }
      
      // أضف من اليسار إذا كان متاحاً
      if (leftIndex >= 0 && visible.length < maxVisible) {
        visible.insert(visible.length - 1, allPages[leftIndex]);
        indices.insert(indices.length - 1, leftIndex);
        leftIndex--;
      }
    }
    
    // رتب حسب الفهرس الأصلي
    final sortedData = List.generate(visible.length, (i) => {'page': visible[i], 'index': indices[i]});
    sortedData.sort((a, b) => (a['index'] as int).compareTo(b['index'] as int));
    
    return _VisiblePagesData(
      visiblePages: sortedData.map((e) => e['page'] as String).toList(),
      visibleIndices: sortedData.map((e) => e['index'] as int).toList(),
    );
  }

  Widget _buildPageButton(String pageTitle, int pageIndex, double leftMargin) {
    final isSelected = ((originalIndices != null && pageIndex < originalIndices!.length)
        ? (originalIndices![pageIndex] == currentPageIndex)
        : (pageIndex == currentPageIndex));
    
    return Container(
      margin: EdgeInsets.only(left: leftMargin),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            final int mappedOriginal = (originalIndices != null && pageIndex < originalIndices!.length)
                ? originalIndices![pageIndex]
                : pageIndex;
            onPageSelected?.call(mappedOriginal);
          },
          borderRadius: BorderRadius.circular(20),
          splashColor: Colors.blue.withOpacity(0.1),
          highlightColor: Colors.blue.withOpacity(0.05),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [
                        Colors.blue.shade400,
                        Colors.blue.shade600,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : LinearGradient(
                      colors: [
                        Colors.grey.shade50,
                        Colors.grey.shade100,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              borderRadius: BorderRadius.circular(20),
              border: isSelected 
                  ? null 
                  : Border.all(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.blue.shade200.withOpacity(0.5),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: Colors.blue.shade100.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                        spreadRadius: 0,
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.grey.shade200.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                        spreadRadius: 0,
                      ),
                    ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected) ...[
                  Icon(
                    Icons.radio_button_checked,
                    size: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  pageTitle,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: 13,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (String value) {
        switch (value) {
          case 'add_page':
            onAddPagePressed?.call();
            break;
          case 'settings':
            onSettingsPressed?.call();
            break;
          case 'language':
            // TODO: تنفيذ اختيار اللغة
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('سيتم إضافة اختيار اللغة قريباً')),
            );
            break;
          case 'notifications':
            // TODO: تنفيذ إعدادات الإشعارات
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('سيتم إضافة إعدادات الإشعارات قريباً')),
            );
            break;
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        if (onAddPagePressed != null)
          const PopupMenuItem<String>(
            value: 'add_page',
            child: ListTile(
              leading: Icon(Icons.add, color: Colors.green),
              title: Text('إضافة صفحة جديدة'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        if (onSettingsPressed != null)
          const PopupMenuItem<String>(
            value: 'settings',
            child: ListTile(
              leading: Icon(Icons.settings, color: Colors.grey),
              title: Text('الإعدادات'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        const PopupMenuItem<String>(
          value: 'language',
          child: ListTile(
            leading: Icon(Icons.language, color: Colors.blue),
            title: Text('اللغة'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem<String>(
          value: 'notifications',
          child: ListTile(
            leading: Icon(Icons.notifications, color: Colors.orange),
            title: Text('الإشعارات'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.grey.shade400,
                  Colors.grey.shade500,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Icon(
              Icons.more_vert,
              size: 20,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMoreButton(int hiddenCount) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onMorePressed,
        borderRadius: BorderRadius.circular(20),
        splashColor: Colors.orange.withOpacity(0.1),
        highlightColor: Colors.orange.withOpacity(0.05),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.orange.shade400,
                Colors.orange.shade500,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.shade200.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 3),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Center(
            child: Text(
              '$hiddenCount',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(AppTokens.topBarHeight);
}
