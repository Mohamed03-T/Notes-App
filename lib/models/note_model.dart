import 'package:flutter/material.dart';

enum NoteType { text, image, audio }

class NoteModel {
  final String id;
  final NoteType type;
  final String content; // simple representation: text or path
  final DateTime createdAt;
  final int? colorValue; // ARGB color stored as int
  final bool isPinned;
  final bool isArchived;
  final bool isDeleted;
  final DateTime? updatedAt;

  NoteModel({
    required this.id,
    required this.type,
    required this.content,
    DateTime? createdAt,
    this.colorValue,
    this.isPinned = false,
    this.isArchived = false,
    this.isDeleted = false,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Color? get color => colorValue != null ? Color(colorValue!) : null;
}
