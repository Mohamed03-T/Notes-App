import 'package:flutter/material.dart';
import '../../models/folder_model.dart';

class FolderCard extends StatelessWidget {
  final FolderModel folder;
  final VoidCallback? onTap;

  const FolderCard({Key? key, required this.folder, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(folder.title),
        subtitle: Text('${folder.notes.length} notes • ${folder.updatedAt}'),
        onTap: onTap,
      ),
    );
  }
}
