import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';
import '../../core/layout/layout_helpers.dart';
import '../../utils/responsive.dart';
import '../../generated/l10n/app_localizations.dart';

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
  final VoidCallback? onAllPagesPressed; // زر عرض جميع الصفحات
  final VoidCallback? onAddPagePressed; // زر إضافة صفحة جديدة
  final VoidCallback? onSettingsPressed; // زر الإعدادات
  final int? totalPagesCount; // العدد الكلي للصفحات

  const TopBar({
    super.key,
    this.pages = const [],
    this.currentPageIndex = 0,
    this.onPageSelected,
    this.originalIndices,
    this.onAllPagesPressed,
    this.onAddPagePressed,
    this.onSettingsPressed,
    this.totalPagesCount,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
  // حساب المساحة المتاحة للصفحات
  final double buttonSpacing = Layout.smallGap(context);
  final double sideMargin = Layout.horizontalPadding(context);
  final double menuButtonWidth = Responsive.wp(context, 9); // عرض زر القائمة المنسدلة
  final double moreButtonWidth = Responsive.wp(context, 9); // عرض زر المزيد الجديد
    
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
        preferredSize: const Size.fromHeight(0.5),
        child: Container(
          height: 0.5,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                Theme.of(context).dividerColor.withOpacity(0.2),
                Colors.transparent,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
      ),
      title: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: Layout.horizontalPadding(context) * 0.5),
        child: Row(
          children: [
            // الصفحات المرئية - تتوسع لملء المساحة المتاحة
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    for (var i = 0; i < visiblePagesData.visiblePages.length; i++)
                      _buildPageButton(
                        context,
                        visiblePagesData.visiblePages[i],
                        visiblePagesData.visibleIndices[i],
                        i == 0 ? 0 : buttonSpacing,
                      ),
                  ],
                ),
              ),
            ),
            
            // زر القائمة المنسدلة
            if (onAddPagePressed != null || onSettingsPressed != null || onAllPagesPressed != null) ...[
              SizedBox(width: buttonSpacing),
              _buildMenuButton(context, hiddenCount),
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

  Widget _buildPageButton(BuildContext context, String pageTitle, int pageIndex, double leftMargin) {
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
          borderRadius: BorderRadius.circular(16),
          splashColor: Theme.of(context).primaryColor.withOpacity(0.1),
          highlightColor: Theme.of(context).primaryColor.withOpacity(0.05),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.wp(context, 3.5), 
              vertical: Responsive.hp(context, 1.1)
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected 
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).dividerColor.withOpacity(0.3),
                width: isSelected ? 0 : 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                        spreadRadius: -2,
                      ),
                    ]
                  : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOutCubic,
                  width: isSelected ? 6 : 0,
                  height: isSelected ? 6 : 0,
                  margin: EdgeInsets.only(right: isSelected ? 8 : 0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                Text(
                  pageTitle,
                  style: TextStyle(
                    color: isSelected 
                        ? Colors.white 
                        : Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.8),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: Responsive.sp(context, 1.55),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context, int hiddenCount) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      color: Theme.of(context).cardColor,
      onSelected: (String value) {
        switch (value) {
          case 'all_pages':
            onAllPagesPressed?.call();
            break;
          case 'add_page':
            onAddPagePressed?.call();
            break;
          case 'settings':
            onSettingsPressed?.call();
            break;
          case 'language':
            // TODO: تنفيذ اختيار اللغة
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.helpComingSoon),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
            break;
          case 'notifications':
            // TODO: تنفيذ إعدادات الإشعارات
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.notificationSoundsComingSoon),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
            break;
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        if (onAllPagesPressed != null && hiddenCount > 0)
          PopupMenuItem<String>(
            value: 'all_pages',
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(Icons.apps_rounded, color: Theme.of(context).primaryColor, size: 20),
                      if (hiddenCount > 0)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$hiddenCount',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 8,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)!.allPagesTitle,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        if (onAddPagePressed != null)
          PopupMenuItem<String>(
            value: 'add_page',
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.add_rounded, color: Colors.green, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)!.addNewPage,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        if (onSettingsPressed != null)
          PopupMenuItem<String>(
            value: 'settings',
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.settings_rounded, color: Colors.grey, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)!.settings,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        PopupMenuItem<String>(
          value: 'language',
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.language_rounded, color: Colors.blue, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context)!.selectLanguage,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'notifications',
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.notifications_rounded, color: Colors.orange, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context)!.notifications,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
      child: Container(
        width: Responsive.wp(context, 9),
        height: Responsive.wp(context, 9),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.more_vert_rounded,
          size: Layout.iconSize(context) * 0.9,
          color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.7),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(AppTokens.topBarHeight);
}
