import '../../models/page_model.dart';
import '../../models/folder_model.dart';
import '../../models/note_model.dart';

/// واجهة تخزين البيانات - Data Store Interface
/// تحدد العقد الموحد لجميع طرق التخزين (SQLite-backed stores are expected)
/// 
/// العقد (Contract):
/// - كل دالة تُرجع Future<OperationResult<T>> يحتوي على:
///   * success: bool (نجحت أم فشلت)
///   * data: T? (البيانات المُرجعة)
///   * error: String? (رسالة الخطأ إن وُجد)
/// - جميع العمليات تكون آمنة (Safe) ولا ترمي Exceptions
/// - يجب التحقق من النتيجة قبل استخدام البيانات
abstract class INotesStore {
  
  // ==================== Pages Operations ====================
  
  /// حفظ صفحة جديدة
  /// Input: PageModel
  /// Output: OperationResult<String> (ID الصفحة المحفوظة)
  Future<OperationResult<String>> savePage(PageModel page);
  
  /// الحصول على جميع الصفحات
  /// Output: OperationResult<List<PageModel>>
  Future<OperationResult<List<PageModel>>> getAllPages();
  
  /// الحصول على صفحة بالـ ID
  /// Input: String pageId
  /// Output: OperationResult<PageModel>
  Future<OperationResult<PageModel>> getPageById(String pageId);
  
  /// تحديث صفحة
  /// Input: PageModel
  /// Output: OperationResult<bool>
  Future<OperationResult<bool>> updatePage(PageModel page);
  
  /// حذف صفحة
  /// Input: String pageId
  /// Output: OperationResult<bool>
  Future<OperationResult<bool>> deletePage(String pageId);

  // ==================== Folders Operations ====================
  
  /// حفظ مجلد جديد
  /// Input: FolderModel, String pageId
  /// Output: OperationResult<String> (ID المجلد المحفوظ)
  Future<OperationResult<String>> saveFolder(FolderModel folder, String pageId);
  
  /// الحصول على جميع مجلدات صفحة معينة
  /// Input: String pageId
  /// Output: OperationResult<List<FolderModel>>
  Future<OperationResult<List<FolderModel>>> getFoldersByPageId(String pageId);
  
  /// الحصول على مجلد بالـ ID
  /// Input: String folderId
  /// Output: OperationResult<FolderModel>
  Future<OperationResult<FolderModel>> getFolderById(String folderId);
  
  /// تحديث مجلد
  /// Input: FolderModel
  /// Output: OperationResult<bool>
  Future<OperationResult<bool>> updateFolder(FolderModel folder);
  
  /// حذف مجلد
  /// Input: String folderId
  /// Output: OperationResult<bool>
  Future<OperationResult<bool>> deleteFolder(String folderId);

  // ==================== Notes Operations ====================
  
  /// حفظ ملاحظة جديدة
  /// Input: NoteModel
  /// Output: OperationResult<String> (ID الملاحظة المحفوظة)
  Future<OperationResult<String>> saveNote(NoteModel note, String pageId, String folderId);
  
  /// الحصول على جميع ملاحظات مجلد معين
  /// Input: String folderId
  /// Output: OperationResult<List<NoteModel>>
  Future<OperationResult<List<NoteModel>>> getNotesByFolderId(String folderId);
  
  /// الحصول على ملاحظة بالـ ID
  /// Input: String noteId
  /// Output: OperationResult<NoteModel>
  Future<OperationResult<NoteModel>> getNoteById(String noteId);
  
  /// تحديث ملاحظة
  /// Input: NoteModel
  /// Output: OperationResult<bool>
  Future<OperationResult<bool>> updateNote(NoteModel note);
  
  /// حذف ملاحظة (حذف منطقي)
  /// Input: String noteId
  /// Output: OperationResult<bool>
  Future<OperationResult<bool>> deleteNote(String noteId);
  
  /// حذف ملاحظة نهائياً
  /// Input: String noteId
  /// Output: OperationResult<bool>
  Future<OperationResult<bool>> permanentlyDeleteNote(String noteId);

  // ==================== Attachments Operations ====================
  
  /// حفظ مرفق لملاحظة
  /// Input: String noteId, String filePath
  /// Output: OperationResult<String> (ID المرفق)
  Future<OperationResult<String>> saveAttachment(String noteId, String filePath);
  
  /// الحصول على جميع مرفقات ملاحظة
  /// Input: String noteId
  /// Output: OperationResult<List<String>>
  Future<OperationResult<List<String>>> getAttachmentsByNoteId(String noteId);
  
  /// حذف مرفق
  /// Input: String attachmentId
  /// Output: OperationResult<bool>
  Future<OperationResult<bool>> deleteAttachment(String attachmentId);

  // ==================== Backup & Migration ====================
  
  /// إنشاء نسخة احتياطية كاملة
  /// Output: OperationResult<String> (JSON أو Path)
  Future<OperationResult<String>> createFullBackup();
  
  /// استرداد من نسخة احتياطية
  /// Input: String backupData
  /// Output: OperationResult<bool>
  Future<OperationResult<bool>> restoreFromBackup(String backupData);
  
  /// التحقق من سلامة البيانات
  /// Output: OperationResult<bool>
  Future<OperationResult<bool>> validateIntegrity();

  // ==================== Statistics ====================
  
  /// الحصول على إحصائيات
  /// Output: OperationResult<Map<String, int>>
  Future<OperationResult<Map<String, int>>> getStatistics();
}

/// نتيجة العملية - Operation Result
/// تستخدم لتوحيد نتائج جميع العمليات
class OperationResult<T> {
  final bool success;
  final T? data;
  final String? error;
  final OperationResultCode code;

  const OperationResult({
    required this.success,
    this.data,
    this.error,
    this.code = OperationResultCode.unknown,
  });

  /// نجاح العملية
  factory OperationResult.successWith(T data, {OperationResultCode code = OperationResultCode.success}) {
    return OperationResult(
      success: true,
      data: data,
      code: code,
    );
  }

  /// فشل العملية
  factory OperationResult.failure(String error, {OperationResultCode code = OperationResultCode.error}) {
    return OperationResult(
      success: false,
      error: error,
      code: code,
    );
  }

  /// عنصر غير موجود
  factory OperationResult.notFound(String message) {
    return OperationResult(
      success: false,
      error: message,
      code: OperationResultCode.notFound,
    );
  }

  /// استثناء
  factory OperationResult.exception(Exception e) {
    return OperationResult(
      success: false,
      error: e.toString(),
      code: OperationResultCode.exception,
    );
  }

  @override
  String toString() {
    return 'OperationResult{success: $success, code: $code, error: $error, hasData: ${data != null}}';
  }
}

/// رموز نتائج العمليات
enum OperationResultCode {
  success,              // نجحت العملية
  error,                // خطأ عام
  notFound,            // عنصر غير موجود
  alreadyExists,       // العنصر موجود مسبقاً
  invalidInput,        // مدخلات غير صالحة
  databaseError,       // خطأ في قاعدة البيانات
  networkError,        // خطأ في الشبكة (للمستقبل)
  permissionDenied,    // رفض الإذن
  exception,           // استثناء غير متوقع
  unknown,             // غير معروف
}
