import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';

class PageCard extends StatelessWidget {
  final String title;
  final int foldersCount;
  final VoidCallback? onTap;

  const PageCard({Key? key, required this.title, this.foldersCount = 0, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.borderRadius)),
      child: ListTile(
        title: Text(title),
        subtitle: Text('$foldersCount folders'),
        onTap: onTap,
      ),
    );
  }
}
