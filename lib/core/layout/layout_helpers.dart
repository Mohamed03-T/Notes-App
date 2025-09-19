import 'package:flutter/widgets.dart';
import '../../utils/responsive.dart';

/// Centralized layout helpers using percentage-based Responsive helpers.
class Layout {
  /// Base horizontal padding used across screens (as % of width).
  static double horizontalPadding(BuildContext context) => Responsive.wp(context, 4);

  /// Base vertical spacing between sections (as % of height).
  static double sectionSpacing(BuildContext context) => Responsive.hp(context, 2);

  /// Small gap (e.g., between icon and text inside rows).
  static double smallGap(BuildContext context) => Responsive.wp(context, 1.5);

  /// Standard icon size in sp-percent.
  static double iconSize(BuildContext context) => Responsive.sp(context, 1.6);

  /// Standard body font using sp-percent.
  static double bodyFont(BuildContext context) => Responsive.sp(context, 1.6);

  /// Title font size.
  static double titleFont(BuildContext context) => Responsive.sp(context, 2.0);

  /// Returns the available vertical space excluding viewInsets (keyboard)
  /// and optional other reserved heights (e.g., app bars). Use this to
  /// size editors or scrollable areas so they won't overflow when the
  /// keyboard is visible.
  static double availableHeight(BuildContext context, {double reservedHeight = 0}) {
    final mq = MediaQuery.of(context);
    final total = mq.size.height;
    final bottomInset = mq.viewInsets.bottom; // keyboard height when visible
    final topPadding = mq.padding.top;
    final usable = total - bottomInset - topPadding - reservedHeight;
    return usable.clamp(0, total);
  }
}
