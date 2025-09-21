import 'package:flutter/material.dart';
import '../../repositories/notes_repository.dart';
import '../../models/page_model.dart';
import '../../core/layout/layout_helpers.dart';
import '../../utils/responsive.dart';
import '../../generated/l10n/app_localizations.dart';

class AddFolderScreen extends StatefulWidget {
  final String pageId;
  final PageModel page;

  const AddFolderScreen({Key? key, required this.pageId, required this.page}) : super(key: key);

  @override
  _AddFolderScreenState createState() => _AddFolderScreenState();
}

class _AddFolderScreenState extends State<AddFolderScreen> {
  final TextEditingController _titleController = TextEditingController();
  bool _isCreating = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _createFolder() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      // SnackBar for empty folder name removed per request
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      final repo = NotesRepository();
      final folderId = repo.addNewFolder(widget.pageId, title);
      
      if (mounted) {
        // SnackBar for folder creation success removed per request
        Navigator.pop(context, folderId);
      }
    } catch (e) {
      if (mounted) {
        // SnackBar for folder creation error removed per request
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reserved = kToolbarHeight + MediaQuery.of(context).padding.top + 32;
    final avail = Layout.availableHeight(context, reservedHeight: reserved);

    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.addFolderTitle),
        backgroundColor: Colors.blue.shade50,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(Layout.horizontalPadding(context)),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: avail),
          child: IntrinsicHeight(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: EdgeInsets.all(Responsive.wp(context, 4)),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.create_new_folder,
                        size: Responsive.sp(context, 4.2),
                        color: Colors.blue.shade600,
                      ),
                      SizedBox(height: Layout.smallGap(context)),
                      Text(
                        l10n.createFolder,
                        style: TextStyle(
                          fontSize: Responsive.sp(context, 2.4),
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      SizedBox(height: Layout.smallGap(context) * 0.8),
                      Text(
                        l10n.inPage(widget.page.title),
                        style: TextStyle(
                          fontSize: Layout.bodyFont(context),
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: Layout.smallGap(context) * 0.6),
                      Text(
                        l10n.addFolderDescription,
                        style: TextStyle(
                          fontSize: Layout.bodyFont(context) * 0.95,
                          color: Colors.blue.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: Layout.sectionSpacing(context)),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: l10n.folderName,
                    hintText: l10n.folderNameHint,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: Icon(Icons.folder, size: Layout.iconSize(context)),
                  ),
                  onSubmitted: (_) => _createFolder(),
                  textInputAction: TextInputAction.done,
                ),
                SizedBox(height: Layout.sectionSpacing(context)),
                ElevatedButton(
                  onPressed: _isCreating ? null : _createFolder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: Responsive.hp(context, 1.6)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isCreating
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: Responsive.wp(context, 5),
                              height: Responsive.wp(context, 5),
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: Layout.smallGap(context)),
                            Text(l10n.creatingFolder, style: TextStyle(fontSize: Layout.bodyFont(context))),
                          ],
                        )
                      : Text(
                          l10n.createFolder,
                          style: TextStyle(fontSize: Layout.bodyFont(context), fontWeight: FontWeight.bold),
                        ),
                ),
                SizedBox(height: Layout.smallGap(context)),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    l10n.cancel,
                    style: TextStyle(fontSize: Layout.bodyFont(context)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
