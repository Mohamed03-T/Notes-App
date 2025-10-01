/// Database Contract - عقد قاعدة البيانات
/// يحدد جميع الثوابت والهياكل المستخدمة في قاعدة البيانات
library;

/// إصدار قاعدة البيانات الحالي
const int kDatabaseVersion = 1;

/// اسم ملف قاعدة البيانات
const String kDatabaseName = 'notes_app.db';

/// جدول البيانات الوصفية (Metadata)
abstract class MetaTable {
  static const String tableName = 'meta';
  static const String columnKey = 'key';
  static const String columnValue = 'value';
  static const String columnUpdatedAt = 'updated_at';

  /// مفاتيح البيانات الوصفية
  static const String keyDataVersion = 'data_version';
  static const String keyMigrationStatus = 'migration_status';
  static const String keyLastBackup = 'last_backup';
  static const String keyAppVersion = 'app_version';

  static const String createTable = '''
    CREATE TABLE $tableName (
      $columnKey TEXT PRIMARY KEY NOT NULL,
      $columnValue TEXT NOT NULL,
      $columnUpdatedAt INTEGER NOT NULL
    )
  ''';
}

/// جدول الصفحات (Pages)
abstract class PagesTable {
  static const String tableName = 'pages';
  static const String columnId = 'id';
  static const String columnTitle = 'title';
  static const String columnCreatedAt = 'created_at';
  static const String columnUpdatedAt = 'updated_at';
  static const String columnSortOrder = 'sort_order';

  static const String createTable = '''
    CREATE TABLE $tableName (
      $columnId TEXT PRIMARY KEY NOT NULL,
      $columnTitle TEXT NOT NULL,
      $columnCreatedAt INTEGER NOT NULL,
      $columnUpdatedAt INTEGER NOT NULL,
      $columnSortOrder INTEGER DEFAULT 0
    )
  ''';

  static const String indexUpdatedAt = '''
    CREATE INDEX idx_pages_updated_at ON $tableName($columnUpdatedAt DESC)
  ''';
}

/// جدول المجلدات (Folders)
abstract class FoldersTable {
  static const String tableName = 'folders';
  static const String columnId = 'id';
  static const String columnPageId = 'page_id';
  static const String columnTitle = 'title';
  static const String columnIsPinned = 'is_pinned';
  static const String columnBackgroundColor = 'background_color';
  static const String columnCreatedAt = 'created_at';
  static const String columnUpdatedAt = 'updated_at';
  static const String columnSortOrder = 'sort_order';

  static const String createTable = '''
    CREATE TABLE $tableName (
      $columnId TEXT PRIMARY KEY NOT NULL,
      $columnPageId TEXT NOT NULL,
      $columnTitle TEXT NOT NULL,
      $columnIsPinned INTEGER NOT NULL DEFAULT 0,
      $columnBackgroundColor INTEGER,
      $columnCreatedAt INTEGER NOT NULL,
      $columnUpdatedAt INTEGER NOT NULL,
      $columnSortOrder INTEGER DEFAULT 0,
      FOREIGN KEY ($columnPageId) REFERENCES ${PagesTable.tableName}(${PagesTable.columnId}) ON DELETE CASCADE
    )
  ''';

  static const String indexPageId = '''
    CREATE INDEX idx_folders_page_id ON $tableName($columnPageId)
  ''';

  static const String indexUpdatedAt = '''
    CREATE INDEX idx_folders_updated_at ON $tableName($columnUpdatedAt DESC)
  ''';
}

/// جدول الملاحظات (Notes)
abstract class NotesTable {
  static const String tableName = 'notes';
  static const String columnId = 'id';
  static const String columnPageId = 'page_id';
  static const String columnFolderId = 'folder_id';
  static const String columnType = 'type';
  static const String columnContent = 'content';
  static const String columnColorValue = 'color_value';
  static const String columnIsPinned = 'is_pinned';
  static const String columnIsArchived = 'is_archived';
  static const String columnIsDeleted = 'is_deleted';
  static const String columnCreatedAt = 'created_at';
  static const String columnUpdatedAt = 'updated_at';

  static const String createTable = '''
    CREATE TABLE $tableName (
      $columnId TEXT PRIMARY KEY NOT NULL,
      $columnPageId TEXT NOT NULL,
      $columnFolderId TEXT NOT NULL,
      $columnType TEXT NOT NULL,
      $columnContent TEXT NOT NULL,
      $columnColorValue INTEGER,
      $columnIsPinned INTEGER NOT NULL DEFAULT 0,
      $columnIsArchived INTEGER NOT NULL DEFAULT 0,
      $columnIsDeleted INTEGER NOT NULL DEFAULT 0,
      $columnCreatedAt INTEGER NOT NULL,
      $columnUpdatedAt INTEGER NOT NULL,
      FOREIGN KEY ($columnPageId) REFERENCES ${PagesTable.tableName}(${PagesTable.columnId}) ON DELETE CASCADE,
      FOREIGN KEY ($columnFolderId) REFERENCES ${FoldersTable.tableName}(${FoldersTable.columnId}) ON DELETE CASCADE
    )
  ''';

  static const String indexPageId = '''
    CREATE INDEX idx_notes_page_id ON $tableName($columnPageId)
  ''';

  static const String indexFolderId = '''
    CREATE INDEX idx_notes_folder_id ON $tableName($columnFolderId)
  ''';

  static const String indexCreatedAt = '''
    CREATE INDEX idx_notes_created_at ON $tableName($columnCreatedAt DESC)
  ''';

  static const String indexDeleted = '''
    CREATE INDEX idx_notes_deleted ON $tableName($columnIsDeleted, $columnIsArchived)
  ''';
}

/// جدول المرفقات (Attachments)
abstract class AttachmentsTable {
  static const String tableName = 'attachments';
  static const String columnId = 'id';
  static const String columnNoteId = 'note_id';
  static const String columnType = 'type';
  static const String columnPath = 'path';
  static const String columnFileName = 'file_name';
  static const String columnFileSize = 'file_size';
  static const String columnCreatedAt = 'created_at';

  static const String createTable = '''
    CREATE TABLE $tableName (
      $columnId TEXT PRIMARY KEY NOT NULL,
      $columnNoteId TEXT NOT NULL,
      $columnType TEXT NOT NULL,
      $columnPath TEXT NOT NULL,
      $columnFileName TEXT,
      $columnFileSize INTEGER,
      $columnCreatedAt INTEGER NOT NULL,
      FOREIGN KEY ($columnNoteId) REFERENCES ${NotesTable.tableName}(${NotesTable.columnId}) ON DELETE CASCADE
    )
  ''';

  static const String indexNoteId = '''
    CREATE INDEX idx_attachments_note_id ON $tableName($columnNoteId)
  ''';

  static const String indexCreatedAt = '''
    CREATE INDEX idx_attachments_created_at ON $tableName($columnCreatedAt DESC)
  ''';
}

/// جدول النسخ الاحتياطية (للترحيل والاسترداد)
abstract class BackupsTable {
  static const String tableName = 'backups';
  static const String columnId = 'id';
  static const String columnType = 'type';
  static const String columnData = 'data';
  static const String columnCreatedAt = 'created_at';
  static const String columnNote = 'note';

  static const String createTable = '''
    CREATE TABLE $tableName (
      $columnId TEXT PRIMARY KEY NOT NULL,
      $columnType TEXT NOT NULL,
      $columnData TEXT NOT NULL,
      $columnCreatedAt INTEGER NOT NULL,
      $columnNote TEXT
    )
  ''';

  static const String indexCreatedAt = '''
    CREATE INDEX idx_backups_created_at ON $tableName($columnCreatedAt DESC)
  ''';
}

/// أنواع الملاحظات
abstract class NoteTypes {
  static const String text = 'text';
  static const String image = 'image';
  static const String audio = 'audio';
}

/// أنواع المرفقات
abstract class AttachmentTypes {
  static const String image = 'image';
  static const String audio = 'audio';
  static const String video = 'video';
  static const String document = 'document';
  static const String other = 'other';
}

/// حالات الترحيل
abstract class MigrationStatus {
  static const String notStarted = 'not_started';
  static const String inProgress = 'in_progress';
  static const String completed = 'completed';
  static const String failed = 'failed';
  static const String rolledBack = 'rolled_back';
}
