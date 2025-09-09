import 'package:flutter/material.dart';

enum NoteType { simple, article, email, checklist }

class AddNoteScreen extends StatelessWidget {
	final NoteType noteType;

	const AddNoteScreen({Key? key, this.noteType = NoteType.simple}) : super(key: key);

	String _titleForType() {
		switch (noteType) {
			case NoteType.article:
				return 'New Article';
			case NoteType.email:
				return 'New Email';
			case NoteType.checklist:
				return 'New Checklist';
			case NoteType.simple:
			default:
				return 'Add Note';
		}
	}

	@override
	Widget build(BuildContext context) {
		final controller = TextEditingController();
		return Scaffold(
			appBar: AppBar(title: Text(_titleForType())),
			body: Padding(
				padding: const EdgeInsets.all(12.0),
				child: Column(
					children: [
						TextField(controller: controller, maxLines: 8, decoration: const InputDecoration(border: OutlineInputBorder())),
						const SizedBox(height: 12),
						ElevatedButton(onPressed: () {}, child: const Text('Save'))
					],
				),
			),
		);
	}
}
//*** End Patch
