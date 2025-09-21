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
  String get allPagesTitle => 'جميع الصفحات';

  @override
  String get latest => 'الأحدث';

  @override
  String foldersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مجلدات',
      one: 'مجلد واحد',
      zero: 'لا توجد مجلدات',
    );
    return '$_temp0';
  }

  @override
  String lastUpdated(String when) {
    return 'آخر تحديث: $when';
  }

  @override
  String get addPageDescription => 'أضف صفحة جديدة لتنظيم ملاحظاتك بشكل أفضل';

  @override
  String get pageName => 'اسم الصفحة';

  @override
  String get pageNameHint => 'مثال: مشاريع، أفكار، مهام...';

  @override
  String get creating => 'جاري الإنشاء...';

  @override
  String get createPage => 'إنشاء الصفحة';

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
    return 'هل أنت متأكد من حذف المجلد \"$folderName\"؟\nسيتم حذف جميع الملاحظات الموجودة فيه.';
  }

  @override
  String get delete => 'حذف';

  @override
  String get noFolders => 'لا توجد مجلدات';

  @override
  String get noNotes => 'لا توجد ملاحظات';

  @override
  String get noFoldersYet => 'لا توجد مجلدات بعد';

  @override
  String get tapPlusToAddFolder => 'انقر على + لإضافة مجلد جديد';

  @override
  String get error => 'خطأ';

  @override
  String get folderNotFound => 'المجلد غير موجود';

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

  @override
  String get onboardingPage1Title => 'تحكم كامل';

  @override
  String get onboardingPage1Description => 'قم بإنشاء وتنظيم ملاحظاتك بكل سهولة داخل صفحات ومجلدات.';

  @override
  String get onboardingPage2Title => 'واجهة بسيطة';

  @override
  String get onboardingPage2Description => 'استمتع بواجهة مستخدم نظيفة وسهلة الاستخدام.';

  @override
  String get onboardingPage3Title => 'تخصيص المظهر';

  @override
  String get onboardingPage3Description => 'اختر بين الوضع الفاتح والداكن حسب رغبتك.';

  @override
  String get onboardingPage4Title => 'عمل دون إنترنت';

  @override
  String get onboardingPage4Description => 'التطبيق يعمل دون اتصال بالإنترنت ويخزن ملاحظاتك محلياً لضمان خصوصية عالية.';

  @override
  String get onboardingPage5Title => 'اللغات المتوفرة';

  @override
  String get onboardingPage5Description => 'العربية، الفرنسية، والإنجليزية لتجربة أكثر سهولة ومرونة.';

  @override
  String get onboardingPage6Title => 'النسخ والاستعادة';

  @override
  String get onboardingPage6Description => 'تتوفر تحديثات مستقبلية لنسخ البيانات واستعادتها، وإذا حُذف التطبيق دون نسخ احتياطي ستُفقد الملاحظات.';

  @override
  String get onboardingPage7Title => 'حماية المجلدات';

  @override
  String get onboardingPage7Description => 'يمكنك تعيين رمز للمجلدات لحفظ أسرارك وحمايتها.';

  @override
  String get onboardingSkip => 'تخطي';

  @override
  String get onboardingBack => 'عودة';

  @override
  String get onboardingNext => 'التالي';

  @override
  String get onboardingFinish => 'إنهاء';

  @override
  String foldersInPage(Object page) {
    return 'المجلدات في $page';
  }

  @override
  String get noFoldersHere => 'لا توجد مجلدات في هذه الصفحة';

  @override
  String get addNoteTitleSimple => 'إضافة ملاحظة';

  @override
  String get addNoteTitleArticle => 'مقال جديد';

  @override
  String get addNoteTitleEmail => 'بريد إلكتروني جديد';

  @override
  String get addNoteTitleChecklist => 'قائمة تحقق جديدة';

  @override
  String get save => 'حفظ';

  @override
  String get addFolderTitle => 'إضافة مجلد جديد';

  @override
  String get createFolder => 'إنشاء المجلد';

  @override
  String get addFolderDescription => 'أضف مجلدًا جديدًا لتنظيم الملاحظات داخل هذه الصفحة';

  @override
  String inPage(Object page) {
    return 'في الصفحة: $page';
  }

  @override
  String get folderNameHint => 'مثال: مهام يومية، أفكار، اجتماعات...';

  @override
  String get creatingFolder => 'جاري الإنشاء...';

  @override
  String get notificationsEnabledOn => 'تم تفعيل الإشعارات';

  @override
  String get notificationsEnabledOff => 'تم إيقاف الإشعارات';

  @override
  String get notificationSounds => 'أصوات الإشعارات';

  @override
  String get notificationSoundsSubtitle => 'الصوت الافتراضي';

  @override
  String get notificationSoundsComingSoon => 'سيتم إضافة خيارات الأصوات قريباً';

  @override
  String get autoBackupPeriodicEnabled => 'تم تفعيل النسخ الدوري';

  @override
  String autoBackupLast(String date) {
    return 'آخر نسخة: $date';
  }

  @override
  String get autoBackupPeriodicEnabledSnackOn => 'تم تفعيل النسخ الدوري (يعمل أثناء تشغيل التطبيق)';

  @override
  String get autoBackupPeriodicEnabledSnackOff => 'تم إيقاف النسخ الدوري';

  @override
  String get exportBackupTitle => 'تصدير النسخة الاحتياطية';

  @override
  String get exportBackupSubtitle => 'حفظ ملف JSON للنسخة الاحتياطية';

  @override
  String get exportBackupSaved => 'تم حفظ النسخة الاحتياطية';

  @override
  String get exportBackupFailed => 'فشل في حفظ النسخة الاحتياطية';

  @override
  String get importBackupTitle => 'استيراد النسخة الاحتياطية';

  @override
  String get importBackupSubtitle => 'اختر ملف JSON لاستيراده';

  @override
  String get importBackupSuccess => 'تم استيراد النسخة الاحتياطية';

  @override
  String get importBackupFailed => 'فشل في استيراد الملف';

  @override
  String get restoreFromKeyTitle => 'استعادة من المفتاح الداخلي';

  @override
  String get restoreFromKeySubtitle => 'استعادة من backup_notes_v2';

  @override
  String get restoreFromKeySuccess => 'تمت الاستعادة من المفتاح الداخلي';

  @override
  String get restoreFromKeyNotFound => 'لا توجد نسخة احتياطية داخلية';

  @override
  String get appInfoTitle => 'معلومات التطبيق';

  @override
  String get appDescription => 'تطبيق ملاحظات حديث وأنيق مع دعم المظهر الداكن والفاتح';

  @override
  String get thankYouMessage => 'شكراً لاستخدام التطبيق! 💙';

  @override
  String get composerHint => 'اكتب ملاحظة سريعة... (أو اضغط أيقونة الكتابة للخيارات المتقدمة)';

  @override
  String get composerSend => 'إرسال';

  @override
  String get composerCreate => 'إنشاء ملاحظة';

  @override
  String get composerSavedSuccess => 'تم حفظ الملاحظة بنجاح ✅';

  @override
  String get composerSavedFailure => 'فشل في حفظ الملاحظة ❌';

  @override
  String composerError(Object error) {
    return 'خطأ: $error';
  }

  @override
  String get composerOptionSimple => 'ملاحظة بسيطة';

  @override
  String get composerOptionArticle => 'مقال / ملاحظة طويلة';

  @override
  String get composerOptionEmail => 'بريد إلكتروني / رسالة منسقة';

  @override
  String get composerOptionChecklist => 'قائمة تحقق / مهام';

  @override
  String get composerOptionCancel => 'إلغاء';

  @override
  String get noteTypeSimple => 'بسيطة';

  @override
  String get noteTypeArticle => 'مقال';

  @override
  String get noteTypeEmail => 'بريد إلكتروني';

  @override
  String get noteTypeChecklist => 'قائمة تحقق';

  @override
  String get noteTypeText => 'نص';

  @override
  String get noteTypeImage => 'صورة';

  @override
  String get noteTypeAudio => 'صوت';
}
