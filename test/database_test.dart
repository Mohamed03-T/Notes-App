import 'package:flutter_test/flutter_test.dart';
import 'package:note_app/core/database/database_contract.dart';
import 'package:note_app/core/database/i_notes_store.dart';
import 'package:note_app/models/note_model.dart';
import 'package:note_app/models/folder_model.dart';
import 'package:note_app/models/page_model.dart';
import 'package:uuid/uuid.dart';

void main() {
  group('Database Contract Tests', () {
    test('should have correct table names', () {
      expect(PagesTable.tableName, 'pages');
      expect(FoldersTable.tableName, 'folders');
      expect(NotesTable.tableName, 'notes');
      expect(AttachmentsTable.tableName, 'attachments');
      expect(MetaTable.tableName, 'meta');
      expect(BackupsTable.tableName, 'backups');
    });

    test('should have correct column names for notes', () {
      expect(NotesTable.columnId, 'id');
      expect(NotesTable.columnPageId, 'page_id');
      expect(NotesTable.columnFolderId, 'folder_id');
      expect(NotesTable.columnType, 'type');
      expect(NotesTable.columnContent, 'content');
      expect(NotesTable.columnColorValue, 'color_value');
      expect(NotesTable.columnIsPinned, 'is_pinned');
      expect(NotesTable.columnIsArchived, 'is_archived');
      expect(NotesTable.columnIsDeleted, 'is_deleted');
      expect(NotesTable.columnCreatedAt, 'created_at');
      expect(NotesTable.columnUpdatedAt, 'updated_at');
    });

    test('should have CREATE TABLE statements', () {
      expect(PagesTable.createTable, contains('CREATE TABLE'));
      expect(FoldersTable.createTable, contains('CREATE TABLE'));
      expect(NotesTable.createTable, contains('CREATE TABLE'));
      expect(AttachmentsTable.createTable, contains('FOREIGN KEY'));
      expect(NotesTable.createTable, contains('ON DELETE CASCADE'));
    });

    test('should have indexes', () {
      expect(NotesTable.indexPageId, contains('CREATE INDEX'));
      expect(NotesTable.indexFolderId, contains('CREATE INDEX'));
      expect(FoldersTable.indexPageId, contains('CREATE INDEX'));
    });
  });

  group('OperationResult Tests', () {
    test('should create success result', () {
      final result = OperationResult.successWith('test data');
      
      expect(result.success, true);
      expect(result.data, 'test data');
      expect(result.error, null);
      expect(result.code, OperationResultCode.success);
    });

    test('should create failure result', () {
      final result = OperationResult<String>.failure('error message');
      
      expect(result.success, false);
      expect(result.data, null);
      expect(result.error, 'error message');
      expect(result.code, OperationResultCode.error);
    });

    test('should create not found result', () {
      final result = OperationResult<String>.notFound('item not found');
      
      expect(result.success, false);
      expect(result.error, 'item not found');
      expect(result.code, OperationResultCode.notFound);
    });

    test('should create exception result', () {
      final exception = Exception('test exception');
      final result = OperationResult<String>.exception(exception);
      
      expect(result.success, false);
      expect(result.error, contains('test exception'));
      expect(result.code, OperationResultCode.exception);
    });
  });

  group('Migration Status Tests', () {
    test('should have correct migration status values', () {
      expect(MigrationStatus.notStarted, 'not_started');
      expect(MigrationStatus.inProgress, 'in_progress');
      expect(MigrationStatus.completed, 'completed');
      expect(MigrationStatus.failed, 'failed');
      expect(MigrationStatus.rolledBack, 'rolled_back');
    });
  });

  group('Note Types Tests', () {
    test('should have correct note types', () {
      expect(NoteTypes.text, 'text');
      expect(NoteTypes.image, 'image');
      expect(NoteTypes.audio, 'audio');
    });
  });

  group('Attachment Types Tests', () {
    test('should have correct attachment types', () {
      expect(AttachmentTypes.image, 'image');
      expect(AttachmentTypes.audio, 'audio');
      expect(AttachmentTypes.video, 'video');
      expect(AttachmentTypes.document, 'document');
      expect(AttachmentTypes.other, 'other');
    });
  });

  group('Model Tests', () {
    test('should create note model', () {
      final note = NoteModel(
        id: const Uuid().v4(),
        type: NoteType.text,
        content: 'Test note',
      );

      expect(note.id, isNotEmpty);
      expect(note.type, NoteType.text);
      expect(note.content, 'Test note');
      expect(note.isPinned, false);
      expect(note.isArchived, false);
      expect(note.isDeleted, false);
    });

    test('should create folder model', () {
      final folder = FolderModel(
        id: 'f1',
        title: 'Test Folder',
      );

      expect(folder.id, 'f1');
      expect(folder.title, 'Test Folder');
      expect(folder.notes, isEmpty);
      expect(folder.isPinned, false);
    });

    test('should create page model', () {
      final page = PageModel(
        id: 'p1',
        title: 'Test Page',
      );

      expect(page.id, 'p1');
      expect(page.title, 'Test Page');
      expect(page.folders, isEmpty);
    });
  });
}
