import 'package:flutter/material.dart';
import '../../core/layout/layout_helpers.dart';
import '../../generated/l10n/app_localizations.dart';

enum NoteType { simple, article, email, checklist }

class AddNoteScreen extends StatefulWidget {
	final NoteType noteType;

	const AddNoteScreen({super.key, this.noteType = NoteType.simple});

	@override
	State<AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends State<AddNoteScreen> {
	late final TextEditingController _controller;

	@override
	void initState() {
		super.initState();
		_controller = TextEditingController();
	}

	@override
	void dispose() {
		_controller.dispose();
		super.dispose();
	}

	String _titleForType(BuildContext context) {
			final l10n = AppLocalizations.of(context);
			if (l10n == null) {
				// fallback titles in case localization isn't available yet
				switch (widget.noteType) {
					case NoteType.article:
						return 'Add Article';
					case NoteType.email:
						return 'Add Email';
					case NoteType.checklist:
						return 'Add Checklist';
					case NoteType.simple:
						return 'Add Note';
				}
			}

			switch (widget.noteType) {
				case NoteType.article:
					return l10n.addNoteTitleArticle;
				case NoteType.email:
					return l10n.addNoteTitleEmail;
				case NoteType.checklist:
					return l10n.addNoteTitleChecklist;
				case NoteType.simple:
					return l10n.addNoteTitleSimple;
			}
		}

	@override
	Widget build(BuildContext context) {
		final reserved = kToolbarHeight + MediaQuery.of(context).padding.top + 24; // appbar + status + margins
		final avail = Layout.availableHeight(context, reservedHeight: reserved);

		return Scaffold(
			appBar: AppBar(title: Text(_titleForType(context))),
			body: Padding(
				padding: EdgeInsets.all(Layout.horizontalPadding(context)),
				child: SizedBox(
					height: avail,
					child: Column(
						children: [
							Expanded(
								child: TextField(
									controller: _controller,
									maxLines: null,
									expands: true,
									decoration: const InputDecoration(border: OutlineInputBorder()),
									style: TextStyle(fontSize: Layout.bodyFont(context)),
								),
							),
							SizedBox(height: Layout.smallGap(context)),
							SizedBox(
								width: double.infinity,
												child: ElevatedButton(
													onPressed: () {},
													child: Builder(builder: (ctx) {
														final l10n = AppLocalizations.of(ctx);
														return Text(
															l10n?.save ?? 'Save',
															style: TextStyle(fontSize: Layout.bodyFont(context)),
														);
													}),
												),
							),
						],
					),
				),
			),
		);
	}
}
//*** End Patch
