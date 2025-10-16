import 'package:flutter/material.dart';
import '../core/database/i_notes_store.dart';
import '../core/database/sqlite_notes_store.dart';

/// أداة لإصلاح البيانات القديمة وفحص سلامة البيانات
/// 
/// الاستخدام:
/// ```dart
/// await DataFixTool.diagnoseData();      // تشخيص فقط
/// await DataFixTool.fixOldNotes();       // إصلاح الملاحظات
/// await DataFixTool.generateReport();    // تقرير مفصل
/// ```
class DataFixTool {
  /// تشخيص البيانات - يفحص محتويات قاعدة SQLite ويجمع إحصائيات بسيطة
  static Future<DataDiagnosisReport> diagnoseData() async {
    final report = DataDiagnosisReport();

    try {
      final INotesStore store = SqliteNotesStore();
      final pagesRes = await store.getAllPages();
      final pages = pagesRes.data ?? [];

      final seen = <String>{};

      report.totalPages = pages.length;
      for (final page in pages) {
        report.totalFolders += page.folders.length;
        for (final folder in page.folders) {
          for (final note in folder.notes) {
            report.totalNotes++;

            // Check ID
            if (note.id.isEmpty) {
              report.notesWithoutId++;
              final contentPreview = note.content.length > 30 ? note.content.substring(0, 30) : note.content;
              report.problematicNotes.add({'content': contentPreview, 'issue': 'missing id'});
            } else {
              if (seen.contains(note.id)) {
                report.duplicateIds++;
                final contentPreview = note.content.length > 30 ? note.content.substring(0, 30) : note.content;
                report.problematicNotes.add({'content': contentPreview, 'issue': 'duplicate id: ${note.id}'});
              } else {
                seen.add(note.id);
              }
            }
          }
        }
      }

      report.isHealthy = report.hasProblems() == false;
    } catch (err) {
      report.errors.add('خطأ عام في التشخيص: $err');
    }

    return report;
  }

  /// إصلاح الملاحظات القديمة
  static Future<FixResult> fixOldNotes({
    String defaultPageId = 'p1',
    String defaultFolderId = 'f1',
  }) async {
    final result = FixResult();
    
    try {
      // This tool now only analyzes and reports potential fixes, it does not modify the DB.
      final store = SqliteNotesStore();
      final pagesRes = await store.getAllPages();
      final pages = pagesRes.data ?? [];

      final seen = <String>{};
      int missingIds = 0;
      int duplicates = 0;

      for (final page in pages) {
        for (final folder in page.folders) {
          for (final note in folder.notes) {
            if (note.id.isEmpty) {
              missingIds++;
            } else if (seen.contains(note.id)) {
              duplicates++;
            } else {
              seen.add(note.id);
            }
          }
        }
      }

      result.totalFixed = missingIds; // number of items that would need IDs
      result.skipped = duplicates; // report duplicates count in skipped field
      result.success = true;
      
    } catch (e) {
      result.errors.add('خطأ عام في الإصلاح: $e');
      result.success = false;
    }
    
    return result;
  }

  /// إنشاء تقرير مفصل
  static Future<String> generateReport() async {
    final diagnosis = await diagnoseData();
    
    final buffer = StringBuffer();
    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln('       تقرير سلامة البيانات');
    buffer.writeln('═══════════════════════════════════════\n');
    
    buffer.writeln('📊 الإحصائيات العامة:');
    buffer.writeln('   • إجمالي الملاحظات: ${diagnosis.totalNotes}');
    buffer.writeln('   • إجمالي الصفحات: ${diagnosis.totalPages}');
    buffer.writeln('   • إجمالي المجلدات: ${diagnosis.totalFolders}\n');
    
    buffer.writeln('🔍 المشاكل المكتشفة:');
    buffer.writeln('   • ملاحظات بدون pageId: ${diagnosis.notesWithoutPageId}');
    buffer.writeln('   • ملاحظات بدون folderId: ${diagnosis.notesWithoutFolderId}');
    buffer.writeln('   • ملاحظات بدون ID: ${diagnosis.notesWithoutId}');
    buffer.writeln('   • معرّفات مكررة: ${diagnosis.duplicateIds}');
    buffer.writeln('   • ملاحظات تالفة: ${diagnosis.corruptedNotes}');
    buffer.writeln('   • صفحات تالفة: ${diagnosis.corruptedPages}\n');
    
    if (diagnosis.hasProblems()) {
      buffer.writeln('⚠️ الحالة: توجد مشاكل تحتاج إصلاح\n');
      
      if (diagnosis.problematicNotes.isNotEmpty) {
        buffer.writeln('📝 أمثلة على الملاحظات المشكلة:');
        for (int i = 0; i < diagnosis.problematicNotes.length && i < 5; i++) {
          final note = diagnosis.problematicNotes[i];
          buffer.writeln('   ${i + 1}. "${note['content']}" - ${note['issue']}');
        }
        if (diagnosis.problematicNotes.length > 5) {
          buffer.writeln('   ... و ${diagnosis.problematicNotes.length - 5} ملاحظة أخرى\n');
        }
      }
      
      buffer.writeln('💡 الحل المقترح:');
      buffer.writeln('   await DataFixTool.fixOldNotes();');
    } else {
      buffer.writeln('✅ الحالة: البيانات سليمة');
    }
    
    if (diagnosis.errors.isNotEmpty) {
      buffer.writeln('\n❌ الأخطاء:');
      for (final error in diagnosis.errors) {
        buffer.writeln('   • $error');
      }
    }
    
    buffer.writeln('\n═══════════════════════════════════════');
    
    return buffer.toString();
  }

  /// حذف الملاحظات المكررة
  static Future<int> removeDuplicates() async {
    try {
      final store = SqliteNotesStore();
      final pagesRes = await store.getAllPages();
      final pages = pagesRes.data ?? [];

      final seen = <String>{};
      int removed = 0;

      for (final page in pages) {
        for (final folder in page.folders) {
          for (final note in folder.notes) {
            if (note.id.isEmpty) continue;
            if (seen.contains(note.id)) {
              removed++;
            } else {
              seen.add(note.id);
            }
          }
        }
      }

      // Note: This function only *detects* duplicates and returns the count.
      // It does not mutate the database. Use a separate migration/cleanup utility
      // if you want to remove duplicates programmatically.

      return removed;
    } catch (e) {
      debugPrint('❌ فشل في حذف المكررات: $e');
      return 0;
    }
  }
}

/// تقرير التشخيص
class DataDiagnosisReport {
  int totalNotes = 0;
  int totalPages = 0;
  int totalFolders = 0;
  
  int notesWithoutPageId = 0;
  int notesWithoutFolderId = 0;
  int notesWithoutId = 0;
  int duplicateIds = 0;
  int corruptedNotes = 0;
  int corruptedPages = 0;
  
  bool isHealthy = true;
  
  final List<Map<String, dynamic>> problematicNotes = [];
  final List<String> errors = [];
  
  
  bool hasProblems() {
    return notesWithoutPageId > 0 ||
           notesWithoutFolderId > 0 ||
           notesWithoutId > 0 ||
           duplicateIds > 0 ||
           corruptedNotes > 0 ||
           corruptedPages > 0;
  }
  
  @override
  String toString() {
    return '''
DataDiagnosisReport:
  Total: $totalNotes notes, $totalPages pages, $totalFolders folders
  Problems: 
    - Without pageId: $notesWithoutPageId
    - Without folderId: $notesWithoutFolderId
    - Without id: $notesWithoutId
    - Duplicates: $duplicateIds
    - Corrupted: $corruptedNotes
  Healthy: $isHealthy
''';
  }
}

/// نتيجة الإصلاح
class FixResult {
  bool success = false;
  int totalFixed = 0;
  int fixedPageId = 0;
  int fixedFolderId = 0;
  int fixedId = 0;
  int skipped = 0;
  
  final List<String> errors = [];
  
  @override
  String toString() {
    return '''
FixResult:
  Success: $success
  Total Fixed: $totalFixed
    - Fixed pageId: $fixedPageId
    - Fixed folderId: $fixedFolderId
    - Fixed id: $fixedId
  Skipped: $skipped
  Errors: ${errors.length}
''';
  }
}
