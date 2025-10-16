# نظام قاعدة البيانات SQLite - دليل الترحيل والاستخدام

## 📋 نظرة عامة

تم تحويل نظام التخزين من **SharedPreferences** إلى **SQLite** لتحسين الأداء والقدرة على إدارة البيانات بشكل أفضل.

## 🏗️ معمارية النظام

### 1. طبقات النظام (Layers)

```
┌─────────────────────────────────────┐
│     UI Layer (Screens/Widgets)      │
├─────────────────────────────────────┤
│    Repository Layer (Business)      │
├─────────────────────────────────────┤
│  Storage Interface (INotesStore)    │ ← عقد موحد
├─────────────────────────────────────┤
│   SQLite Implementation             │
├─────────────────────────────────────┤
│   Database Helper & Contract        │
└─────────────────────────────────────┘
```

### 2. مكونات النظام

#### أ. Database Contract (`database_contract.dart`)
- **المسؤولية**: تعريف جميع الثوابت والجداول
- **يحتوي على**:
  - أسماء الجداول والأعمدة
  - أوامر إنشاء الجداول
  - Indexes لتحسين الأداء
  - الثوابت العامة

#### ب. Database Helper (`database_helper.dart`)
- **المسؤولية**: إدارة قاعدة البيانات
- **الوظائف**:
  - إنشاء وفتح قاعدة البيانات
  - الترقية بين الإصدارات
  - التحقق من السلامة
  - إحصائيات قاعدة البيانات

#### ج. Storage Interface (`i_notes_store.dart`)
- **المسؤولية**: تعريف العقد الموحد
- **الفوائد**:
  - سهولة الاختبار (Mock)
  - إمكانية تبديل التنفيذ
  - توحيد الأخطاء والنتائج

#### د. SQLite Store (`sqlite_notes_store.dart`)
- **المسؤولية**: تنفيذ العمليات على SQLite
- **العمليات**:
  - CRUD للصفحات والمجلدات والملاحظات
  - إدارة المرفقات
  - النسخ الاحتياطي والاسترداد

#### هـ. ملاحظة حول الترحيل (مُحدّث)

- هذا المشروع الآن يعمل بنظام SQLite-only. ملفات الترحيل القديمة (التي كانت تعتمد على SharedPreferences) أزيلت من الشيفرة التنفيذية.
- إذا كانت لديك بيانات قديمة خارجياً، استعمل آلية الاستيراد عبر JSON الموجودة في شاشة الإعدادات أو أدوات النسخ الاحتياطي (`NotesRepository.exportBackupJson` / `importBackupJson`).

> ملحوظة: لا حاجة لآلية الترحيل داخل التطبيق عند بدء قاعدة بيانات جديدة (من الصفر).

## 📊 مخطط الجداول

### جدول Pages (الصفحات)
```sql
CREATE TABLE pages (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  sort_order INTEGER DEFAULT 0
)
```

### جدول Folders (المجلدات)
```sql
CREATE TABLE folders (
  id TEXT PRIMARY KEY,
  page_id TEXT NOT NULL,
  title TEXT NOT NULL,
  is_pinned INTEGER DEFAULT 0,
  background_color INTEGER,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  sort_order INTEGER DEFAULT 0,
  FOREIGN KEY (page_id) REFERENCES pages(id) ON DELETE CASCADE
)
```

### جدول Notes (الملاحظات)
```sql
CREATE TABLE notes (
  id TEXT PRIMARY KEY,
  page_id TEXT NOT NULL,
  folder_id TEXT NOT NULL,
  type TEXT NOT NULL,
  content TEXT NOT NULL,
  color_value INTEGER,
  is_pinned INTEGER DEFAULT 0,
  is_archived INTEGER DEFAULT 0,
  is_deleted INTEGER DEFAULT 0,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  FOREIGN KEY (page_id) REFERENCES pages(id) ON DELETE CASCADE,
  FOREIGN KEY (folder_id) REFERENCES folders(id) ON DELETE CASCADE
)
```

### جدول Attachments (المرفقات)
```sql
CREATE TABLE attachments (
  id TEXT PRIMARY KEY,
  note_id TEXT NOT NULL,
  type TEXT NOT NULL,
  path TEXT NOT NULL,
  file_name TEXT,
  file_size INTEGER,
  created_at INTEGER NOT NULL,
  FOREIGN KEY (note_id) REFERENCES notes(id) ON DELETE CASCADE
)
```

### جدول Meta (البيانات الوصفية)
```sql
CREATE TABLE meta (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  updated_at INTEGER NOT NULL
)
```

### جدول Backups (النسخ الاحتياطية)
```sql
CREATE TABLE backups (
  id TEXT PRIMARY KEY,
  type TEXT NOT NULL,
  data TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  note TEXT
)
```

## 🔑 العقد (Contract) - Operation Result

جميع العمليات ترجع `OperationResult<T>`:

```dart
class OperationResult<T> {
  final bool success;        // نجحت أم فشلت
  final T? data;            // البيانات المُرجعة
  final String? error;      // رسالة الخطأ
  final OperationResultCode code;  // رمز النتيجة
}
```

### رموز النتائج:
- `success`: نجحت العملية
- `error`: خطأ عام
- `notFound`: عنصر غير موجود
- `alreadyExists`: العنصر موجود مسبقاً
- `invalidInput`: مدخلات غير صالحة
- `databaseError`: خطأ في قاعدة البيانات
- `exception`: استثناء غير متوقع

## 🚀 خطوات الترحيل

### 1. التحضير
```dart
final migrationService = MigrationService();
final status = await migrationService.checkMigrationStatus();
```

### 2. بدء الترحيل
```dart
final result = await migrationService.startMigration();

if (result.success) {
  final report = result.data!;
  print('تم الترحيل بنجاح!');
  print('الملاحظات: ${report.oldNotesCount} → ${report.newNotesCount}');
} else {
  print('فشل الترحيل: ${result.error}');
}
```

### 3. الاسترداد من النسخة الاحتياطية (إذا لزم الأمر)
```dart
final restoreResult = await migrationService.restoreFromPreMigrationBackup();
```

## 💡 أمثلة الاستخدام

### حفظ ملاحظة جديدة
```dart
final store = SqliteNotesStore();

final note = NoteModel(
  id: Uuid().v4(),
  type: NoteType.text,
  content: 'محتوى الملاحظة',
);

final result = await store.saveNote(note, 'p1', 'f1');

if (result.success) {
  print('تم الحفظ! ID: ${result.data}');
} else {
  print('خطأ: ${result.error}');
}
```

### قراءة ملاحظات مجلد
```dart
final result = await store.getNotesByFolderId('f1');

if (result.success) {
  final notes = result.data!;
  for (final note in notes) {
    print('${note.id}: ${note.content}');
  }
}
```

### إنشاء نسخة احتياطية
```dart
final backupResult = await store.createFullBackup();

if (backupResult.success) {
  final backupJson = backupResult.data!;
  // حفظ JSON في ملف أو السحابة
}
```

## 🔍 التحقق من السلامة

```dart
final integrityResult = await store.validateIntegrity();

if (integrityResult.success) {
  print('✅ قاعدة البيانات سليمة');
} else {
  print('❌ مشكلة: ${integrityResult.error}');
}
```

## 📈 الإحصائيات

```dart
final statsResult = await store.getStatistics();

if (statsResult.success) {
  final stats = statsResult.data!;
  print('الصفحات: ${stats['pages']}');
  print('المجلدات: ${stats['folders']}');
  print('الملاحظات: ${stats['notes']}');
  print('المرفقات: ${stats['attachments']}');
}
```

## ✅ المزايا الجديدة

### 1. الأداء
- ✅ استعلامات SQL محسّنة
- ✅ Indexes على الحقول المهمة
- ✅ Transactions للعمليات المتعددة

### 2. السلامة
- ✅ Foreign Keys للعلاقات
- ✅ Cascade Delete تلقائي
- ✅ نسخ احتياطية تلقائية

### 3. القدرات
- ✅ البحث المتقدم
- ✅ الترتيب والتصفية
- ✅ الحذف المنطقي (Soft Delete)
- ✅ تتبع التغييرات (Timestamps)

### 4. الصيانة
- ✅ Migrations سهلة
- ✅ Rollback آمن
- ✅ Integrity Checks

## 🔮 خارطة الطريق المستقبلية

### المرحلة 1: الأساسيات ✅ (مكتملة)
- [x] تصميم الجداول
- [x] Database Helper
- [x] SQLite Store
- [x] Migration Service

### المرحلة 2: التحسينات (قريباً)
- [ ] Full-text search
- [ ] محرك البحث المتقدم
- [ ] التزامن مع السحابة
- [ ] Export/Import JSON

### المرحلة 3: المستقبل
- [ ] الترحيل إلى Drift (إن احتجنا)
- [ ] دعم Tags
- [ ] دعم Reminders
- [ ] سجل التغييرات (History)

## ⚠️ ملاحظات مهمة

### 1. النسخ الاحتياطي
- يتم إنشاء نسخة احتياطية قبل الترحيل
- مفتاح النسخة: `backup_notes_v2_before_migration`
- يجب الاحتفاظ بها لمدة 30 يوم على الأقل

### 2. التحقق من الترحيل
- يتم فحص:
  - سلامة قاعدة البيانات
  - عدد السجلات
  - أول وآخر 5 ملاحظات
  - العلاقات بين الجداول

### 3. معالجة الأخطاء
- جميع العمليات آمنة (لا ترمي Exceptions)
- يجب التحقق من `result.success` دائماً
- استخدام `result.code` لتحديد نوع الخطأ

## 🧪 الاختبارات

### Unit Tests
```dart
// test/database/sqlite_store_test.dart
test('should save note successfully', () async {
  final store = SqliteNotesStore();
  final note = NoteModel(/* ... */);
  
  final result = await store.saveNote(note, 'p1', 'f1');
  
  expect(result.success, true);
  expect(result.data, isNotNull);
});
```

### Integration Tests
```dart
// integration_test/migration_test.dart
testWidgets('should migrate data successfully', (tester) async {
  final service = MigrationService();
  final result = await service.startMigration();
  
  expect(result.success, true);
  expect(result.data!.validated, true);
});
```

## 📞 الدعم

إذا واجهت أي مشاكل:
1. تحقق من logs: `debugPrint` messages
2. فحص السلامة: `validateIntegrity()`
3. مراجعة النسخة الاحتياطية
4. استخدام `restoreFromPreMigrationBackup()`

---

**تاريخ الإنشاء**: 1 أكتوبر 2025  
**الإصدار**: 1.0.0  
**الحالة**: جاهز للترحيل
