import 'package:flutter/material.dart';

enum NoteType { text, image, audio }

class NoteModel {
  final String id;
  final NoteType type;
  final String content; // simple representation: text or path
  final DateTime createdAt;
  final int? colorValue; // ARGB color stored as int

  NoteModel({
    required this.id,
    required this.type,
    required this.content,
    DateTime? createdAt,
    this.colorValue,
  }) : createdAt = createdAt ?? DateTime.now();

  Color? get color => colorValue != null ? Color(colorValue!) : null;
}
