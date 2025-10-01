import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// أداة لإصلاح البيانات القديمة وفحص سلامة البيانات
/// 
/// الاستخدام:
/// ```dart
/// await DataFixTool.diagnoseData();      // تشخيص فقط
/// await DataFixTool.fixOldNotes();       // إصلاح الملاحظات
/// await DataFixTool.generateReport();    // تقرير مفصل
/// ```
class DataFixTool {
  static const String _notesKey = 'saved_notes_v2';
  static const String _pagesKey = 'saved_pages_v1';

  /// تشخيص البيانات - فحص بدون تعديل
  static Future<DataDiagnosisReport> diagnoseData() async {
    final report = DataDiagnosisReport();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // فحص الملاحظات
      final notesJson = prefs.getStringList(_notesKey) ?? [];
      report.totalNotes = notesJson.length;
      
      for (final noteStr in notesJson) {
        try {
          final noteData = jsonDecode(noteStr);
          
          if (noteData['pageId'] == null) {
            report.notesWithoutPageId++;
            report.problematicNotes.add({
              'content': noteData['content']?.toString().substring(0, 30) ?? 'unknown',
              'issue': 'missing pageId',
            });
          }
          
          if (noteData['folderId'] == null) {
            report.notesWithoutFolderId++;
            report.problematicNotes.add({
              'content': noteData['content']?.toString().substring(0, 30) ?? 'unknown',
              'issue': 'missing folderId',
            });
          }
          
          if (noteData['id'] == null || noteData['id'].toString().isEmpty) {
            report.notesWithoutId++;
            report.problematicNotes.add({
              'content': noteData['content']?.toString().substring(0, 30) ?? 'unknown',
              'issue': 'missing id',
            });
          }
          
          // فحص التكرار
          final noteId = noteData['id'];
          if (noteId != null) {
            if (report._seenIds.contains(noteId)) {
              report.duplicateIds++;
              report.problematicNotes.add({
                'content': noteData['content']?.toString().substring(0, 30) ?? 'unknown',
                'issue': 'duplicate id: $noteId',
              });
            } else {
              report._seenIds.add(noteId);
            }
          }
          
        } catch (e) {
          report.corruptedNotes++;
          report.errors.add('فشل في قراءة ملاحظة: $e');
        }
      }
      
      // فحص الصفحات والمجلدات
      final pagesJson = prefs.getStringList(_pagesKey) ?? [];
      report.totalPages = pagesJson.length;
      
      for (final pageStr in pagesJson) {
        try {
          final pageData = jsonDecode(pageStr);
          final folders = (pageData['folders'] as List<dynamic>?) ?? [];
          report.totalFolders += folders.length;
        } catch (e) {
          report.corruptedPages++;
          report.errors.add('فشل في قراءة صفحة: $e');
        }
      }
      
      report.isHealthy = report.hasProblems() == false;
      
    } catch (e) {
      report.errors.add('خطأ عام في التشخيص: $e');
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
      final prefs = await SharedPreferences.getInstance();
      final notesJson = prefs.getStringList(_notesKey) ?? [];
      final fixed = <String>[];
      
      for (final noteStr in notesJson) {
        try {
          final noteData = jsonDecode(noteStr);
          bool wasFixed = false;
          
          // إصلاح pageId المفقود
          if (noteData['pageId'] == null) {
            noteData['pageId'] = defaultPageId;
            wasFixed = true;
            result.fixedPageId++;
          }
          
          // إصلاح folderId المفقود
          if (noteData['folderId'] == null) {
            noteData['folderId'] = defaultFolderId;
            wasFixed = true;
            result.fixedFolderId++;
          }
          
          // إصلاح ID المفقود
          if (noteData['id'] == null || noteData['id'].toString().isEmpty) {
            noteData['id'] = DateTime.now().millisecondsSinceEpoch.toString() + 
                             '_' + (result.fixedId++).toString();
            wasFixed = true;
          }
          
          if (wasFixed) result.totalFixed++;
          
          fixed.add(jsonEncode(noteData));
          
        } catch (e) {
          result.errors.add('فشل في إصلاح ملاحظة: $e');
          result.skipped++;
        }
      }
      
      // حفظ البيانات المُصلحة
      await prefs.setStringList(_notesKey, fixed);
      result.success = true;
      
      debugPrint('✅ تم إصلاح ${result.totalFixed} ملاحظة');
      
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
      final prefs = await SharedPreferences.getInstance();
      final notesJson = prefs.getStringList(_notesKey) ?? [];
      
      final seen = <String>{};
      final unique = <String>[];
      int removed = 0;
      
      for (final noteStr in notesJson) {
        try {
          final noteData = jsonDecode(noteStr);
          final id = noteData['id']?.toString();
          
          if (id != null && !seen.contains(id)) {
            seen.add(id);
            unique.add(noteStr);
          } else {
            removed++;
          }
        } catch (e) {
          // احتفظ بالملاحظة حتى لو كانت تالفة
          unique.add(noteStr);
        }
      }
      
      if (removed > 0) {
        await prefs.setStringList(_notesKey, unique);
        debugPrint('✅ تم حذف $removed ملاحظة مكررة');
      }
      
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
  final Set<String> _seenIds = {};
  
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
