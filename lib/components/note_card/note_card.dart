import 'package:flutter/material.dart';
import '../../models/note_model.dart';

class NoteCard extends StatelessWidget {
  final NoteModel note;

  const NoteCard({Key? key, required this.note}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(note.type == NoteType.text ? note.content : '[${note.type.name}]'),
        subtitle: Text(note.createdAt.toIso8601String()),
      ),
    );
  }
}
