import 'package:flutter/material.dart';
import 'note_model.dart';

class FolderModel {
  final String id;
  String title;
  final List<NoteModel> notes;
  bool isPinned;
  Color? backgroundColor;
  final DateTime updatedAt;

  FolderModel({
    required this.id,
    required this.title,
    List<NoteModel>? notes,
    DateTime? updatedAt,
    this.isPinned = false,
    this.backgroundColor,
  })  : notes = notes ?? [],
        updatedAt = updatedAt ?? DateTime.now();
}
