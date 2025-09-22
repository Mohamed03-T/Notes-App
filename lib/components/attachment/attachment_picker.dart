import 'package:flutter/material.dart';

Future<String?> showAttachmentPathDialog(BuildContext context) async {
  final controller = TextEditingController();
  return showDialog<String?>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Add attachment path'),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(hintText: 'C:\\path\\to\\file.jpg'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Add')),
      ],
    ),
  );
}
