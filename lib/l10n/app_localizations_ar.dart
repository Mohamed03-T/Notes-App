// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'تطبيق الملاحظات';

  @override
  String get settings => 'الإعدادات';

  @override
  String get appearanceAndDisplay => 'المظهر والعرض';

  @override
  String get darkMode => 'المظهر الداكن';

  @override
  String get darkModeSubtitle => 'تفعيل المظهر الداكن للتطبيق';

  @override
  String get fontSize => 'حجم الخط';

  @override
  String get fontSizeSubtitle => 'متوسط';

  @override
  String get languageAndRegion => 'اللغة والمنطقة';

  @override
  String get language => 'اللغة';

  @override
  String get timezone => 'المنطقة الزمنية';

  @override
  String get timezoneSubtitle => 'GMT+3 (الرياض)';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get enableNotifications => 'تفعيل الإشعارات';

  @override
  String get enableNotificationsSubtitle => 'استقبال إشعارات التذكير';

  @override
  String get backupAndSync => 'النسخ الاحتياطي والمزامنة';

  @override
  String get autoBackup => 'النسخ الاحتياطي التلقائي';

  @override
  String get autoBackupSubtitle => 'حفظ تلقائي للملاحظات';

  @override
  String get exportData => 'تصدير البيانات';

  @override
  String get exportDataSubtitle => 'JSON, PDF, TXT';

  @override
  String get importData => 'استيراد البيانات';

  @override
  String get importDataSubtitle => 'من ملفات خارجية';

  @override
  String get support => 'الدعم والمساعدة';

  @override
  String get helpCenter => 'مركز المساعدة';

  @override
  String get helpCenterSubtitle => 'الأسئلة الشائعة والدروس';

  @override
  String get contactUs => 'تواصل معنا';

  @override
  String get contactUsSubtitle => 'support@noteapp.com';

  @override
  String get aboutApp => 'حول التطبيق';

  @override
  String get selectLanguage => 'اختر اللغة';

  @override
  String get arabic => 'العربية';

  @override
  String get english => 'English';

  @override
  String get french => 'Français';

  @override
  String get cancel => 'إلغاء';

  @override
  String get close => 'إغلاق';

  @override
  String get version => 'الإصدار: 1.0.0';

  @override
  String get developer => 'تطوير: Mohamed03-T';

  @override
  String get darkModeEnabled => 'تم تفعيل المظهر الداكن';

  @override
  String get lightModeEnabled => 'تم تفعيل المظهر الفاتح';

  @override
  String get fontSizeComingSoon => 'سيتم إضافة خيارات حجم الخط قريباً';

  @override
  String get timezoneComingSoon => 'سيتم إضافة خيارات المنطقة الزمنية قريباً';

  @override
  String get exportComingSoon => 'سيتم إضافة خيارات التصدير قريباً';

  @override
  String get importComingSoon => 'سيتم إضافة خيارات الاستيراد قريباً';

  @override
  String get helpComingSoon => 'سيتم إضافة مركز المساعدة قريباً';

  @override
  String get contactComingSoon => 'سيتم إضافة خيارات التواصل قريباً';

  @override
  String get welcome => 'مرحباً بك في تطبيق الملاحظات';

  @override
  String get noPagesYet => 'لا توجد صفحات بعد';

  @override
  String get createFirstPage => 'ابدأ بإنشاء صفحتك الأولى';

  @override
  String get createNewPage => 'إنشاء صفحة جديدة';

  @override
  String get addNewPage => 'إضافة صفحة جديدة';

  @override
  String get addNewFolder => 'إضافة مجلد جديد';

  @override
  String get loadingData => 'جاري تحميل البيانات...';

  @override
  String get manageFolder => 'إدارة المجلد:';

  @override
  String get unpinFolder => 'إلغاء تثبيت';

  @override
  String get pinFolder => 'تثبيت المجلد';

  @override
  String get renameFolder => 'تغيير اسم المجلد';

  @override
  String get changeBackgroundColor => 'تغيير لون الخلفية';

  @override
  String get deleteFolder => 'حذف المجلد';

  @override
  String get folderName => 'اسم المجلد';

  @override
  String get confirm => 'تأكيد';

  @override
  String get selectBackgroundColor => 'اختر لون الخلفية';

  @override
  String get confirmDelete => 'تأكيد الحذف';

  @override
  String deleteConfirmMessage(String folderName) {
    return 'هل أنت متأكد من حذف المجلد "${folderName}"؟\nسيتم حذف جميع الملاحظات الموجودة فيه.';
  }

  @override
  String get delete => 'حذف';

  @override
  String get noFolders => 'لا توجد مجلدات';

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'أيام',
      one: 'يوم',
    );
    return 'منذ $count $_temp0';
  }

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ساعات',
      one: 'ساعة',
    );
    return 'منذ $count $_temp0';
  }

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'دقائق',
      one: 'دقيقة',
    );
    return 'منذ $count $_temp0';
  }

  @override
  String get now => 'الآن';

  @override
  String get splashWelcomeTitle => 'مرحباً بك في تطبيق الملاحظات';

  @override
  String get splashTagline => 'نظّم أفكارك وملاحظاتك بسهولة';

  @override
  String get splashLoading => 'جاري التحميل...';
}

