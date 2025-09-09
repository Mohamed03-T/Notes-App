Notes App scaffold

This is a minimal Flutter scaffold created by the assistant. It contains:

- core/theme (tokens, app_theme)
- models (page, folder, note)
- repositories (mock notes_repository)
- components (TopBar, PageCard, FolderCard, NoteCard, ComposerBar, TimeSeparator, FullScreenModal)
- screens (NotesHome, AllPagesScreen, PageFoldersScreen, FolderNotesScreen, AddNoteScreen)

How to run

1. Install Flutter SDK
2. From project root run:

```powershell
flutter pub get
flutter run
```

Next steps

- Wire navigation and state management
- Replace mock repository with a real DB
- Add real media handling (images/audio)
