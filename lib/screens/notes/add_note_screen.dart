import 'package:flutter/material.dart';
import '../../core/layout/layout_helpers.dart';
import '../../generated/l10n/app_localizations.dart';

enum NoteType { simple, article, email, checklist }

class AddNoteScreen extends StatelessWidget {
	final NoteType noteType;

	const AddNoteScreen({Key? key, this.noteType = NoteType.simple}) : super(key: key);

		String _titleForType(BuildContext context) {
			final l10n = AppLocalizations.of(context)!;
			switch (noteType) {
				case NoteType.article:
					return l10n.addNoteTitleArticle;
				case NoteType.email:
					return l10n.addNoteTitleEmail;
				case NoteType.checklist:
					return l10n.addNoteTitleChecklist;
				case NoteType.simple:
				default:
					return l10n.addNoteTitleSimple;
			}
		}

	@override
	Widget build(BuildContext context) {
		final controller = TextEditingController();
			final reserved = kToolbarHeight + MediaQuery.of(context).padding.top + 24; // appbar + status + margins
			final avail = Layout.availableHeight(context, reservedHeight: reserved);

					return Scaffold(
						appBar: AppBar(title: Text(_titleForType(context))),
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
														child: ElevatedButton(onPressed: () {}, child: Text(AppLocalizations.of(context)!.save, style: TextStyle(fontSize: Layout.bodyFont(context)))),
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
