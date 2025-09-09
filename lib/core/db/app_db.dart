import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_db.g.dart';

class Notes extends Table {
  TextColumn get id => text()();
  TextColumn get content => text().withLength(min: 0, max: 10000)();
  TextColumn get type => text().withDefault(const Constant('simple'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Notes])
class AppDb extends _$AppDb {
  AppDb._(QueryExecutor e) : super(e);

  static Future<AppDb> create() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'notes.sqlite'));
    return AppDb._(NativeDatabase(file));
  }

  @override
  int get schemaVersion => 1;

  Future<void> insertNote(NotesCompanion note) => into(notes).insert(note);

  Future<List<Note>> getAllNotes() async {
  return await select(notes).get();
  }
}

