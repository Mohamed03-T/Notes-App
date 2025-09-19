import 'package:flutter/widgets.dart';
import 'dart:math' as math;

/// Small responsive helpers that return sizes as percentages of the
/// current screen dimensions. Use `Responsive.wp(context, 10)` to get
/// 10% of the screen width, `Responsive.hp(context, 5)` for 5% of height,
/// and `Responsive.sp(context, 1.6)` for a scalable text size heuristic.
class Responsive {
  /// Width percentage of the screen. Example: `wp(context, 50)` -> 50% width.
  static double wp(BuildContext context, double percent) {
    final w = MediaQuery.of(context).size.width;
    return w * (percent / 100);
  }

  /// Height percentage of the screen. Example: `hp(context, 20)` -> 20% height.
  static double hp(BuildContext context, double percent) {
    final h = MediaQuery.of(context).size.height;
    return h * (percent / 100);
  }

  /// Scaled font size based on screen diagonal as a simple heuristic.
  /// Example: `sp(context, 1.6)` returns ~1.6% of the screen diagonal.
  static double sp(BuildContext context, double percent) {
    final size = MediaQuery.of(context).size;
    final diag = math.sqrt(size.width * size.width + size.height * size.height);
    return diag * (percent / 100);
  }
}
