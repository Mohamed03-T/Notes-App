import 'folder_model.dart';

class PageModel {
  final String id;
  final String title;
  final List<FolderModel> folders;

  PageModel({required this.id, required this.title, List<FolderModel>? folders}) : folders = folders ?? [];
}
