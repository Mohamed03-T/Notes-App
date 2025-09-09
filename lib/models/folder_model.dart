import 'note_model.dart';

class FolderModel {
  final String id;
  final String title;
  final List<NoteModel> notes;
  final DateTime updatedAt;

  FolderModel({required this.id, required this.title, List<NoteModel>? notes, DateTime? updatedAt})
      : notes = notes ?? [],
        updatedAt = updatedAt ?? DateTime.now();
}
