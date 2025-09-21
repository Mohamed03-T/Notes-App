import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';
import '../../core/layout/layout_helpers.dart';
import '../../utils/responsive.dart';

class PageCard extends StatelessWidget {
  final String title;
  final int foldersCount;
  final VoidCallback? onTap;

  const PageCard({super.key, required this.title, this.foldersCount = 0, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.borderRadius)),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: Layout.horizontalPadding(context) * 0.6, vertical: Responsive.hp(context, 1.2)),
        title: Text(title, style: TextStyle(fontSize: Layout.titleFont(context))),
        subtitle: Text('$foldersCount folders', style: TextStyle(fontSize: Layout.bodyFont(context) * 0.9)),
        onTap: onTap,
      ),
    );
  }
}
