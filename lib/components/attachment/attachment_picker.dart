import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;

Future<String?> showAttachmentPathDialog(BuildContext context) async {
  try {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Storage permission denied')),
          );
        }
        return null;
      }
    }
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.isEmpty) return null;
    final path = result.files.single.path;
    return path;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to pick file')),
      );
    }
    return null;
  }
}
