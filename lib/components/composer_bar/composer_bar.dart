import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../screens/notes/add_note_screen.dart';
import '../../repositories/notes_repository.dart';
import '../../core/layout/layout_helpers.dart';
import '../../utils/responsive.dart';

class ComposerBar extends StatefulWidget {
  final void Function(String)? onSend;
  final List<dynamic>? attachments;
  // دالة callback تستدعى عند تغيير حالة النص (موجود/غير موجود)
  final void Function(bool)? onTextChanged;

  const ComposerBar({super.key, this.onSend, this.attachments, this.onTextChanged});

  @override
  ComposerBarState createState() => ComposerBarState();
}

class ComposerBarState extends State<ComposerBar> {
  late TextEditingController _controller;
  bool _hasText = false;

  /// Public getter so parent widgets can query current text state synchronously.
  bool get hasText => _hasText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _hasText = _controller.text.trim().isNotEmpty;
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _hasText) {
        setState(() => _hasText = hasText);
        if (widget.onTextChanged != null) {
          widget.onTextChanged!(hasText);
        }
        if (kDebugMode) {
          debugPrint('ComposerBar: text state changed: $_hasText');
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _hasAttachments => (widget.attachments?.isNotEmpty ?? false);

  /// دالة لمسح النص من الخارج (تستدعى من الشاشة الأب عند الضغط على زر الرجوع)
  void clearText() {
    _controller.clear();
    setState(() {
      _hasText = false;
    });
    // إبلاغ الشاشة الأب أن النص تم مسحه
    if (widget.onTextChanged != null) {
      widget.onTextChanged!(false);
    }
  }

  Future<void> _handlePrimaryAction() async {
  if (kDebugMode) debugPrint('ComposerBar: primary action pressed, hasText=$_hasText, hasAttachments=$_hasAttachments');
    
    if (_hasText || _hasAttachments) {
  if (kDebugMode) debugPrint('🚀 محاولة إرسال الملاحظة...');
      final content = _controller.text.trim();
      
      if (content.isEmpty) {
  if (kDebugMode) debugPrint('❌ النص فارغ بعد trim!');
        return;
      }

      // استدعاء callback function إذا كانت متوفرة
      if (widget.onSend != null) {
  if (kDebugMode) debugPrint('📞 استدعاء onSend callback...');
        
        // مسح النص وإبلاغ الـ parent فوراً قبل استدعاء onSend
        _controller.clear();
        setState(() {
          _hasText = false;
        });
        // إبلاغ الـ parent أن النص تم مسحه
        if (widget.onTextChanged != null) {
          widget.onTextChanged!(false);
        }
        
        // الآن استدعاء onSend
        widget.onSend!(content);
      } else {
        try {
          final repo = NotesRepository();
          final success = await repo.saveNoteSimple(content);

          if (success) {
            _controller.clear();
            setState(() {
              _hasText = false;
            });
            if (widget.onTextChanged != null) {
              widget.onTextChanged!(false);
            }
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context)!.composerSavedSuccess))
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context)!.composerSavedFailure))
              );
            }
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppLocalizations.of(context)!.composerError(e.toString())))
            );
          }
        }
      }
    } else {
  if (kDebugMode) debugPrint('➕ فتح خيارات الإضافة...');
      _showAddOptions();
    }
  }

  void _openAddNote() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddNoteScreen()));
  }

  void _showAddOptions() {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.note),
                title: Text(AppLocalizations.of(context)!.composerOptionSimple),
                onTap: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddNoteScreen(noteType: NoteType.simple)));
                },
              ),
              ListTile(
                leading: const Icon(Icons.article),
                title: Text(AppLocalizations.of(context)!.composerOptionArticle),
                onTap: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddNoteScreen(noteType: NoteType.article)));
                },
              ),
              ListTile(
                leading: const Icon(Icons.email),
                title: Text(AppLocalizations.of(context)!.composerOptionEmail),
                onTap: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddNoteScreen(noteType: NoteType.email)));
                },
              ),
              ListTile(
                leading: const Icon(Icons.check_box),
                title: Text(AppLocalizations.of(context)!.composerOptionChecklist),
                onTap: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddNoteScreen(noteType: NoteType.checklist)));
                },
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: Text(AppLocalizations.of(context)!.composerOptionCancel),
                onTap: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
  if (kDebugMode) debugPrint('ComposerBar: build called, _hasText = $_hasText');
    return SafeArea(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: Layout.horizontalPadding(context) * 0.5, vertical: Responsive.hp(context, 1.2)),
        color: Colors.white,
        child: Row(
          children: [
            IconButton(onPressed: () {}, icon: Icon(Icons.photo, size: Layout.iconSize(context))),
            IconButton(onPressed: () {}, icon: Icon(Icons.mic, size: Layout.iconSize(context))),
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration.collapsed(
                  hintText: AppLocalizations.of(context)!.composerHint,
                ),
                style: TextStyle(fontSize: Layout.bodyFont(context)),
                onSubmitted: (text) {
                  if (text.trim().isNotEmpty) {
                    _handlePrimaryAction();
                  }
                },
              ),
            ),
            GestureDetector(
              onLongPress: _openAddNote,
              child: IconButton(
                  tooltip: _hasText || _hasAttachments ? AppLocalizations.of(context)!.composerSend : AppLocalizations.of(context)!.composerCreate,
                onPressed: () {
                  debugPrint('ComposerBar: IconButton pressed');
                  _handlePrimaryAction();
                },
                icon: Icon(_hasText || _hasAttachments ? Icons.send : Icons.edit_note, size: Layout.iconSize(context)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
