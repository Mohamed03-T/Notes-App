import 'package:flutter/material.dart';
import 'package:uuid/Uuid.dart';
import '../core/database/sqlite_notes_store.dart';
import '../models/note_model.dart';
import '../models/folder_model.dart';
import '../models/page_model.dart';

/// مثال على استخدام نظام SQLite الجديد
/// 
/// هذا الملف يوضح:
/// 1. كيفية استخدام SqliteNotesStore
/// 2. كيفية إجراء الترحيل
/// 3. أمثلة على العمليات المختلفة

class SqliteUsageExample {
  final SqliteNotesStore _store = SqliteNotesStore();

  /// مثال 1: التحقق من حالة الترحيل وإجرائه إن لزم الأمر
  Future<void> checkAndMigrate() async {
    print('ℹ️ Migration service removed — repository is SQLite-only.');
  }

  /// مثال 2: إنشاء صفحة جديدة مع مجلدات
  Future<void> createPageWithFolders() async {
    print('\n📄 إنشاء صفحة جديدة...');
    
    // 1. إنشاء صفحة
    final page = PageModel(
      id: const Uuid().v4(),
      title: 'صفحة المشاريع',
    );
    
    final pageResult = await _store.savePage(page);
    if (!pageResult.success) {
      print('❌ فشل في حفظ الصفحة: ${pageResult.error}');
      return;
    }
    print('✅ تم إنشاء الصفحة: ${page.title}');
    
    // 2. إنشاء مجلدات
    final folders = [
      FolderModel(
        id: const Uuid().v4(),
        title: 'مشاريع العمل',
        isPinned: true,
      ),
      FolderModel(
        id: const Uuid().v4(),
        title: 'مشاريع شخصية',
      ),
      FolderModel(
        id: const Uuid().v4(),
        title: 'أفكار',
      ),
    ];
    
    for (final folder in folders) {
      final folderResult = await _store.saveFolder(folder, page.id);
      if (folderResult.success) {
        print('  ✅ مجلد: ${folder.title}');
      }
    }
  }

  /// مثال 3: إضافة ملاحظات إلى مجلد
  Future<void> addNotesToFolder(String pageId, String folderId) async {
    print('\n📝 إضافة ملاحظات...');
    
    final notes = [
      NoteModel(
        id: const Uuid().v4(),
        type: NoteType.text,
        content: 'اجتماع مع الفريق يوم الإثنين الساعة 10 صباحاً',
        colorValue: Colors.blue.value,
        isPinned: true,
      ),
      NoteModel(
        id: const Uuid().v4(),
        type: NoteType.text,
        content: 'شراء مستلزمات المكتب:\n- أقلام\n- دفاتر\n- ملفات',
        colorValue: Colors.green.value,
      ),
      NoteModel(
        id: const Uuid().v4(),
        type: NoteType.text,
        content: 'فكرة: تطوير تطبيق للملاحظات الصوتية',
        colorValue: Colors.orange.value,
      ),
    ];
    
    for (final note in notes) {
      final result = await _store.saveNote(note, pageId, folderId);
      if (result.success) {
        print('  ✅ تم حفظ: ${note.content.substring(0, 30)}...');
      }
    }
  }

  /// مثال 4: قراءة جميع الصفحات والمجلدات
  Future<void> loadAllData() async {
    print('\n📖 قراءة جميع البيانات...');
    
    final pagesResult = await _store.getAllPages();
    
    if (!pagesResult.success) {
      print('❌ فشل في تحميل الصفحات: ${pagesResult.error}');
      return;
    }
    
    final pages = pagesResult.data!;
    print('✅ تم تحميل ${pages.length} صفحة\n');
    
    for (final page in pages) {
      print('📄 ${page.title}');
      
      for (final folder in page.folders) {
        print('  📁 ${folder.title} (${folder.notes.length} ملاحظة)');
        
        for (final note in folder.notes.take(3)) {
          final preview = note.content.length > 40 
              ? '${note.content.substring(0, 40)}...' 
              : note.content;
          print('    📝 $preview');
        }
        
        if (folder.notes.length > 3) {
          print('    ... و${folder.notes.length - 3} ملاحظة أخرى');
        }
      }
      print('');
    }
  }

  /// مثال 5: البحث عن ملاحظة وتحديثها
  Future<void> searchAndUpdateNote(String searchTerm) async {
    print('\n🔍 البحث عن ملاحظة تحتوي على: "$searchTerm"');
    
    // الحصول على جميع الصفحات
    final pagesResult = await _store.getAllPages();
    if (!pagesResult.success) return;
    
    // البحث في جميع الملاحظات
    for (final page in pagesResult.data!) {
      for (final folder in page.folders) {
        for (final note in folder.notes) {
          if (note.content.contains(searchTerm)) {
            print('✅ وجدت الملاحظة: ${note.content.substring(0, 50)}...');
            
            // تحديث الملاحظة
            final updatedNote = NoteModel(
              id: note.id,
              type: note.type,
              content: '${note.content}\n\n[تم التحديث: ${DateTime.now()}]',
              createdAt: note.createdAt,
              colorValue: Colors.purple.value,
              isPinned: true, // تثبيت الملاحظة
            );
            
            final updateResult = await _store.updateNote(updatedNote);
            if (updateResult.success) {
              print('✅ تم تحديث الملاحظة');
            }
            
            return;
          }
        }
      }
    }
    
    print('❌ لم يتم العثور على ملاحظة');
  }

  /// مثال 6: حذف ملاحظة (حذف منطقي)
  Future<void> deleteNote(String noteId) async {
    print('\n🗑️ حذف ملاحظة...');
    
    final result = await _store.deleteNote(noteId);
    
    if (result.success) {
      print('✅ تم حذف الملاحظة (حذف منطقي)');
    } else {
      print('❌ فشل في الحذف: ${result.error}');
    }
  }

  /// مثال 7: إنشاء نسخة احتياطية
  Future<void> createBackup() async {
    print('\n💾 إنشاء نسخة احتياطية...');
    
    final result = await _store.createFullBackup();
    
    if (result.success) {
      final backupJson = result.data!;
      print('✅ تم إنشاء النسخة الاحتياطية');
      print('📊 حجم البيانات: ${backupJson.length} حرف');
      
      // يمكنك حفظ JSON في ملف أو السحابة
      // await saveBackupToFile(backupJson);
      
      return;
    }
    
    print('❌ فشل في إنشاء النسخة: ${result.error}');
  }

  /// مثال 8: استرداد من نسخة احتياطية
  Future<void> restoreFromBackup(String backupJson) async {
    print('\n♻️ استرداد من نسخة احتياطية...');
    
    final result = await _store.restoreFromBackup(backupJson);
    
    if (result.success) {
      print('✅ تم الاسترداد بنجاح');
      
      // التحقق من البيانات المستردة
      final statsResult = await _store.getStatistics();
      if (statsResult.success) {
        final stats = statsResult.data!;
        print('📊 الإحصائيات بعد الاسترداد:');
        print('   - الصفحات: ${stats['pages']}');
        print('   - المجلدات: ${stats['folders']}');
        print('   - الملاحظات: ${stats['notes']}');
      }
    } else {
      print('❌ فشل في الاسترداد: ${result.error}');
    }
  }

  /// مثال 9: التحقق من سلامة البيانات
  Future<void> validateData() async {
    print('\n🔍 التحقق من سلامة البيانات...');
    
    final result = await _store.validateIntegrity();
    
    if (result.success) {
      print('✅ البيانات سليمة وخالية من الأخطاء');
    } else {
      print('❌ توجد مشكلة في البيانات: ${result.error}');
      print('💡 يُنصح بإنشاء نسخة احتياطية والاستعادة منها');
    }
  }

  /// مثال 10: الحصول على إحصائيات مفصلة
  Future<void> showStatistics() async {
    print('\n📊 الإحصائيات:');
    
    final result = await _store.getStatistics();
    
    if (result.success) {
      final stats = result.data!;
      
      print('╔═══════════════════════════════╗');
      print('║     إحصائيات التطبيق         ║');
      print('╠═══════════════════════════════╣');
      print('║ الصفحات:        ${stats['pages']?.toString().padLeft(12)} ║');
      print('║ المجلدات:       ${stats['folders']?.toString().padLeft(12)} ║');
      print('║ الملاحظات:      ${stats['notes']?.toString().padLeft(12)} ║');
      print('║ المرفقات:       ${stats['attachments']?.toString().padLeft(12)} ║');
      print('╚═══════════════════════════════╝');
    }
  }

  /// تشغيل جميع الأمثلة
  Future<void> runAllExamples() async {
    print('═══════════════════════════════════════════════════');
    print('      أمثلة استخدام نظام SQLite للملاحظات');
    print('═══════════════════════════════════════════════════\n');
    
    // 1. التحقق والترحيل
    await checkAndMigrate();
    
    // 2. إنشاء بيانات تجريبية
    await createPageWithFolders();
    
    // 3. قراءة البيانات
    await loadAllData();
    
    // 4. إحصائيات
    await showStatistics();
    
    // 5. التحقق من السلامة
    await validateData();
    
    // 6. نسخة احتياطية
    await createBackup();
    
    print('\n═══════════════════════════════════════════════════');
    print('                   انتهت الأمثلة');
    print('═══════════════════════════════════════════════════');
  }
}

/// دالة مساعدة لتشغيل الأمثلة
Future<void> runSqliteExamples() async {
  final example = SqliteUsageExample();
  await example.runAllExamples();
}
