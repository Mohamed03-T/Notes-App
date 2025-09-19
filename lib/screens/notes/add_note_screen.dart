import 'package:flutter/material.dart';
import '../../core/layout/layout_helpers.dart';

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
					return 'Add Note';
			}
	}

	@override
	Widget build(BuildContext context) {
		final controller = TextEditingController();
			final reserved = kToolbarHeight + MediaQuery.of(context).padding.top + 24; // appbar + status + margins
			final avail = Layout.availableHeight(context, reservedHeight: reserved);

			return Scaffold(
				appBar: AppBar(title: Text(_titleForType())),
				body: SingleChildScrollView(
					padding: EdgeInsets.all(Layout.horizontalPadding(context)),
					child: ConstrainedBox(
						constraints: BoxConstraints(minHeight: avail),
						child: IntrinsicHeight(
							child: Column(
								children: [
									Expanded(
										child: TextField(
											controller: controller,
											maxLines: null,
											expands: true,
											decoration: const InputDecoration(border: OutlineInputBorder()),
											style: TextStyle(fontSize: Layout.bodyFont(context)),
										),
									),
									SizedBox(height: Layout.smallGap(context)),
									SizedBox(
										width: double.infinity,
										child: ElevatedButton(onPressed: () {}, child: Text('Save', style: TextStyle(fontSize: Layout.bodyFont(context)))),
									)
								],
							),
						),
					),
				),
			);
	}
}
//*** End Patch
