import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  final List<String> pages;
  final VoidCallback? onMorePressed;

  const TopBar({Key? key, this.pages = const [], this.onMorePressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: AppTokens.topBarHeight,
      title: Row(
        children: [
          for (var i = 0; i < (pages.length > 3 ? 3 : pages.length); i++)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Chip(label: Text(pages[i])),
            ),
          if (pages.length > 3)
            GestureDetector(
              onTap: onMorePressed,
              child: Chip(label: Text('+${pages.length - 3}')),
            ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(AppTokens.topBarHeight);
}
