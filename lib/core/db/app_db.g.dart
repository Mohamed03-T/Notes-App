// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_db.dart';

// ignore_for_file: type=lint
class $NotesTable extends Notes with TableInfo<$NotesTable, Note>{
@override final GeneratedDatabase attachedDatabase;
final String? _alias;
$NotesTable(this.attachedDatabase, [this._alias]);
static const VerificationMeta _idMeta = const VerificationMeta('id');
@override
late final GeneratedColumn<String> id = GeneratedColumn<String>('id', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: true);
static const VerificationMeta _contentMeta = const VerificationMeta('content');
@override
late final GeneratedColumn<String> content = GeneratedColumn<String>('content', aliasedName, false, additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 0,maxTextLength: 10000), type: DriftSqlType.string, requiredDuringInsert: true);
static const VerificationMeta _typeMeta = const VerificationMeta('type');
@override
late final GeneratedColumn<String> type = GeneratedColumn<String>('type', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: false, defaultValue: const Constant('simple'));
static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
@override
late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>('created_at', aliasedName, false, type: DriftSqlType.dateTime, requiredDuringInsert: false, defaultValue: currentDateAndTime);
@override
List<GeneratedColumn> get $columns => [id, content, type, createdAt];
@override
String get aliasedName => _alias ?? actualTableName;
@override
 String get actualTableName => $name;
static const String $name = 'notes';
@override
VerificationContext validateIntegrity(Insertable<Note> instance, {bool isInserting = false}) {
final context = VerificationContext();
final data = instance.toColumns(true);
if (data.containsKey('id')) {
context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));} else if (isInserting) {
context.missing(_idMeta);
}
if (data.containsKey('content')) {
context.handle(_contentMeta, content.isAcceptableOrUnknown(data['content']!, _contentMeta));} else if (isInserting) {
context.missing(_contentMeta);
}
if (data.containsKey('type')) {
context.handle(_typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));}if (data.containsKey('created_at')) {
context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));}return context;
}
@override
Set<GeneratedColumn> get $primaryKey => {id};
@override Note map(Map<String, dynamic> data, {String? tablePrefix})  {
final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';return Note(id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!, content: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}content'])!, type: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}type'])!, createdAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!, );
}
@override
$NotesTable createAlias(String alias) {
return $NotesTable(attachedDatabase, alias);}}class Note extends DataClass implements Insertable<Note> 
{
final String id;
final String content;
final String type;
final DateTime createdAt;
const Note({required this.id, required this.content, required this.type, required this.createdAt});@override
Map<String, Expression> toColumns(bool nullToAbsent) {
final map = <String, Expression> {};map['id'] = Variable<String>(id);
map['content'] = Variable<String>(content);
map['type'] = Variable<String>(type);
map['created_at'] = Variable<DateTime>(createdAt);
return map; 
}
NotesCompanion toCompanion(bool nullToAbsent) {
return NotesCompanion(id: Value(id),content: Value(content),type: Value(type),createdAt: Value(createdAt),);
}
factory Note.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
serializer ??= driftRuntimeOptions.defaultSerializer;
return Note(id: serializer.fromJson<String>(json['id']),content: serializer.fromJson<String>(json['content']),type: serializer.fromJson<String>(json['type']),createdAt: serializer.fromJson<DateTime>(json['createdAt']),);}
@override Map<String, dynamic> toJson({ValueSerializer? serializer}) {
serializer ??= driftRuntimeOptions.defaultSerializer;
return <String, dynamic>{
'id': serializer.toJson<String>(id),'content': serializer.toJson<String>(content),'type': serializer.toJson<String>(type),'createdAt': serializer.toJson<DateTime>(createdAt),};}Note copyWith({String? id,String? content,String? type,DateTime? createdAt}) => Note(id: id ?? this.id,content: content ?? this.content,type: type ?? this.type,createdAt: createdAt ?? this.createdAt,);Note copyWithCompanion(NotesCompanion data) {
return Note(
id: data.id.present ? data.id.value : this.id,content: data.content.present ? data.content.value : this.content,type: data.type.present ? data.type.value : this.type,createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,);
}
@override
String toString() {return (StringBuffer('Note(')..write('id: $id, ')..write('content: $content, ')..write('type: $type, ')..write('createdAt: $createdAt')..write(')')).toString();}
@override
 int get hashCode => Object.hash(id, content, type, createdAt);@override
bool operator ==(Object other) => identical(this, other) || (other is Note && other.id == this.id && other.content == this.content && other.type == this.type && other.createdAt == this.createdAt);
}class NotesCompanion extends UpdateCompanion<Note> {
final Value<String> id;
final Value<String> content;
final Value<String> type;
final Value<DateTime> createdAt;
final Value<int> rowid;
const NotesCompanion({this.id = const Value.absent(),this.content = const Value.absent(),this.type = const Value.absent(),this.createdAt = const Value.absent(),this.rowid = const Value.absent(),});
NotesCompanion.insert({required String id,required String content,this.type = const Value.absent(),this.createdAt = const Value.absent(),this.rowid = const Value.absent(),}): id = Value(id), content = Value(content);
static Insertable<Note> custom({Expression<String>? id, 
Expression<String>? content, 
Expression<String>? type, 
Expression<DateTime>? createdAt, 
Expression<int>? rowid, 
}) {
return RawValuesInsertable({if (id != null)'id': id,if (content != null)'content': content,if (type != null)'type': type,if (createdAt != null)'created_at': createdAt,if (rowid != null)'rowid': rowid,});
}NotesCompanion copyWith({Value<String>? id, Value<String>? content, Value<String>? type, Value<DateTime>? createdAt, Value<int>? rowid}) {
return NotesCompanion(id: id ?? this.id,content: content ?? this.content,type: type ?? this.type,createdAt: createdAt ?? this.createdAt,rowid: rowid ?? this.rowid,);
}
@override
Map<String, Expression> toColumns(bool nullToAbsent) {
final map = <String, Expression> {};if (id.present) {
map['id'] = Variable<String>(id.value);}
if (content.present) {
map['content'] = Variable<String>(content.value);}
if (type.present) {
map['type'] = Variable<String>(type.value);}
if (createdAt.present) {
map['created_at'] = Variable<DateTime>(createdAt.value);}
if (rowid.present) {
map['rowid'] = Variable<int>(rowid.value);}
return map; 
}
@override
String toString() {return (StringBuffer('NotesCompanion(')..write('id: $id, ')..write('content: $content, ')..write('type: $type, ')..write('createdAt: $createdAt, ')..write('rowid: $rowid')..write(')')).toString();}
}
abstract class _$AppDb extends GeneratedDatabase{
_$AppDb(QueryExecutor e): super(e);
$AppDbManager get managers => $AppDbManager(this);
late final $NotesTable notes = $NotesTable(this);
@override
Iterable<TableInfo<Table, Object?>> get allTables => allSchemaEntities.whereType<TableInfo<Table, Object?>>();
@override
List<DatabaseSchemaEntity> get allSchemaEntities => [notes];
}
typedef $$NotesTableCreateCompanionBuilder = NotesCompanion Function({required String id,required String content,Value<String> type,Value<DateTime> createdAt,Value<int> rowid,});
typedef $$NotesTableUpdateCompanionBuilder = NotesCompanion Function({Value<String> id,Value<String> content,Value<String> type,Value<DateTime> createdAt,Value<int> rowid,});
class $$NotesTableFilterComposer extends Composer<
        _$AppDb,
        $NotesTable> {
        $$NotesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
          ColumnFilters<String> get id => $composableBuilder(
      column: $table.id,
      builder: (column) =>
      ColumnFilters(column));
      
ColumnFilters<String> get content => $composableBuilder(
      column: $table.content,
      builder: (column) =>
      ColumnFilters(column));
      
ColumnFilters<String> get type => $composableBuilder(
      column: $table.type,
      builder: (column) =>
      ColumnFilters(column));
      
ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt,
      builder: (column) =>
      ColumnFilters(column));
      
        }
      class $$NotesTableOrderingComposer extends Composer<
        _$AppDb,
        $NotesTable> {
        $$NotesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
          ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id,
      builder: (column) =>
      ColumnOrderings(column));
      
ColumnOrderings<String> get content => $composableBuilder(
      column: $table.content,
      builder: (column) =>
      ColumnOrderings(column));
      
ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type,
      builder: (column) =>
      ColumnOrderings(column));
      
ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt,
      builder: (column) =>
      ColumnOrderings(column));
      
        }
      class $$NotesTableAnnotationComposer extends Composer<
        _$AppDb,
        $NotesTable> {
        $$NotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
          GeneratedColumn<String> get id => $composableBuilder(
      column: $table.id,
      builder: (column) => column);
      
GeneratedColumn<String> get content => $composableBuilder(
      column: $table.content,
      builder: (column) => column);
      
GeneratedColumn<String> get type => $composableBuilder(
      column: $table.type,
      builder: (column) => column);
      
GeneratedColumn<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt,
      builder: (column) => column);
      
        }
      class $$NotesTableTableManager extends RootTableManager    <_$AppDb,
    $NotesTable,
    Note,
    $$NotesTableFilterComposer,
    $$NotesTableOrderingComposer,
    $$NotesTableAnnotationComposer,
    $$NotesTableCreateCompanionBuilder,
    $$NotesTableUpdateCompanionBuilder,
    (Note,BaseReferences<_$AppDb,$NotesTable,Note>),
    Note,
    PrefetchHooks Function()
    > {
    $$NotesTableTableManager(_$AppDb db, $NotesTable table) : super(
      TableManagerState(
        db: db,
        table: table,
        createFilteringComposer: () => $$NotesTableFilterComposer($db: db,$table:table),
        createOrderingComposer: () => $$NotesTableOrderingComposer($db: db,$table:table),
        createComputedFieldComposer: () => $$NotesTableAnnotationComposer($db: db,$table:table),
        updateCompanionCallback: ({Value<String> id = const Value.absent(),Value<String> content = const Value.absent(),Value<String> type = const Value.absent(),Value<DateTime> createdAt = const Value.absent(),Value<int> rowid = const Value.absent(),})=> NotesCompanion(id: id,content: content,type: type,createdAt: createdAt,rowid: rowid,),
        createCompanionCallback: ({required String id,required String content,Value<String> type = const Value.absent(),Value<DateTime> createdAt = const Value.absent(),Value<int> rowid = const Value.absent(),})=> NotesCompanion.insert(id: id,content: content,type: type,createdAt: createdAt,rowid: rowid,),
        withReferenceMapper: (p0) => p0
              .map(
                  (e) =>
                     (e.readTable(table), BaseReferences(db, table, e))
                  )
              .toList(),
        prefetchHooksCallback: null,
        ));
        }
    typedef $$NotesTableProcessedTableManager = ProcessedTableManager    <_$AppDb,
    $NotesTable,
    Note,
    $$NotesTableFilterComposer,
    $$NotesTableOrderingComposer,
    $$NotesTableAnnotationComposer,
    $$NotesTableCreateCompanionBuilder,
    $$NotesTableUpdateCompanionBuilder,
    (Note,BaseReferences<_$AppDb,$NotesTable,Note>),
    Note,
    PrefetchHooks Function()
    >;class $AppDbManager {
final _$AppDb _db;
$AppDbManager(this._db);
$$NotesTableTableManager get notes => $$NotesTableTableManager(_db, _db.notes);
}
