import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'screens/notes/notes_home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NotesApp());
}

class NotesApp extends StatelessWidget {
  const NotesApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notes',
      theme: AppTheme.lightTheme,
      home: const NotesHome(),
    );
  }
}
