enum NoteType { text, image, audio }

class NoteModel {
  final String id;
  final NoteType type;
  final String content; // simple representation: text or path
  final DateTime createdAt;

  NoteModel({required this.id, required this.type, required this.content, DateTime? createdAt})
      : createdAt = createdAt ?? DateTime.now();
}
