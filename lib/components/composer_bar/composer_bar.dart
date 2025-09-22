import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../screens/notes/add_note_screen.dart';
import '../../repositories/notes_repository.dart';
import '../../core/layout/layout_helpers.dart';
import '../../utils/responsive.dart';

class ComposerBar extends StatefulWidget {
  final void Function(String, int?)? onSend;
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

  int? _selectedColor;

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
        
        // الآن استدعاء onSend مع لون إن اختير
        widget.onSend!(content, _selectedColor);
      } else {
        try {
          final repo = NotesRepository();
          final success = await repo.saveNoteSimple(content, colorValue: _selectedColor);

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
            // Simple inline color picker
            PopupMenuButton<int?>(
              tooltip: AppLocalizations.of(context)!.composerOptionSimple,
              onSelected: (v) => setState(() => _selectedColor = v),
              itemBuilder: (_) => [
                PopupMenuItem(child: Text(AppLocalizations.of(context)!.composerOptionCancel), value: null),
                PopupMenuItem(child: Wrap(spacing:8, children: [
                  _colorCircle(Colors.white), _colorCircle(0xFFFFCDD2), _colorCircle(0xFFFFE0B2), _colorCircle(0xFFFFF9C4), _colorCircle(0xFFC8E6C9), _colorCircle(0xFFBBDEFB), _colorCircle(0xFFD1C4E9)
                ]), value: -1),
              ],
              child: Icon(Icons.palette, size: Layout.iconSize(context)),
            ),
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

  Widget _colorCircle(dynamic c) {
    Color color;
    if (c is int) color = Color(c);
    else if (c is Color) color = c;
    else color = Colors.transparent;

    return GestureDetector(
      onTap: () => setState(() => _selectedColor = color.value),
      child: Container(
        width: 28,
        height: 28,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300),
        ),
      ),
    );
  }
}
