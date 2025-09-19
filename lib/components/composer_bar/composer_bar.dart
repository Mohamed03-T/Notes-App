import 'package:flutter/material.dart';
import '../../screens/notes/add_note_screen.dart';
import '../../repositories/notes_repository.dart';
import '../../core/layout/layout_helpers.dart';
import '../../utils/responsive.dart';

class ComposerBar extends StatefulWidget {
  final void Function(String)? onSend;
  final List<dynamic>? attachments;
  // دالة callback تستدعى عند تغيير حالة النص (موجود/غير موجود)
  final void Function(bool)? onTextChanged;

  const ComposerBar({Key? key, this.onSend, this.attachments, this.onTextChanged}) : super(key: key);

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
      print('🎯 تغيير النص: "$hasText" (كان: $_hasText)');
      if (hasText != _hasText) {
        setState(() => _hasText = hasText);
        print('🔄 تم تحديث الحالة: _hasText = $_hasText');
        
        // استدعاء callback عند تغيير حالة النص
        if (widget.onTextChanged != null) {
          widget.onTextChanged!(hasText);
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
    print('🔥 زر الإرسال تم الضغط عليه!');
    print('🔥 النص موجود: $_hasText');
    print('🔥 المرفقات موجودة: $_hasAttachments');
    print('🔥 النص الحالي: "${_controller.text}"');
    
    if (_hasText || _hasAttachments) {
      print('🚀 محاولة إرسال الملاحظة...');
      final content = _controller.text.trim();
      
      if (content.isEmpty) {
        print('❌ النص فارغ بعد trim!');
        return;
      }

      // استدعاء callback function إذا كانت متوفرة
      if (widget.onSend != null) {
        print('📞 استدعاء onSend callback...');
        
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
        // في حالة عدم توفر callback، استخدم الطريقة القديمة
        try {
          print('💾 استدعاء NotesRepository...');
          final repo = NotesRepository();
          final success = await repo.saveNoteSimple(content);
          print('✅ نتيجة الحفظ: $success');
          
          if (success) {
            print('🎉 تم الحفظ بنجاح!');
            _controller.clear();
            setState(() {
              _hasText = false;
            });
            // إبلاغ الـ parent أن النص تم مسحه
            if (widget.onTextChanged != null) {
              widget.onTextChanged!(false);
            }
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم حفظ الملاحظة بنجاح! ✅'))
              );
            }
          } else {
            print('❌ فشل الحفظ');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('فشل في حفظ الملاحظة ❌'))
              );
            }
          }
        } catch (e) {
          print('💥 خطأ: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('خطأ: $e'))
            );
          }
        }
      }
    } else {
      print('➕ فتح خيارات الإضافة...');
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
                title: const Text('Simple note'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddNoteScreen(noteType: NoteType.simple)));
                },
              ),
              ListTile(
                leading: const Icon(Icons.article),
                title: const Text('Article / long note'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddNoteScreen(noteType: NoteType.article)));
                },
              ),
              ListTile(
                leading: const Icon(Icons.email),
                title: const Text('Email / formatted message'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddNoteScreen(noteType: NoteType.email)));
                },
              ),
              ListTile(
                leading: const Icon(Icons.check_box),
                title: const Text('Checklist / tasks'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddNoteScreen(noteType: NoteType.checklist)));
                },
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Cancel'),
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
    debugPrint('ComposerBar: build called, _hasText = $_hasText');
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
                  hintText: 'اكتب ملاحظة سريعة... (أو اضغط على أيقونة الكتابة للخيارات المتقدمة)',
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
                tooltip: _hasText || _hasAttachments ? 'إرسال' : 'إنشاء ملاحظة',
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
