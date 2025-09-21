import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen_l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fr')
  ];

  /// عنوان التطبيق
  ///
  /// In ar, this message translates to:
  /// **'تطبيق الملاحظات'**
  String get appTitle;

  /// عنوان شاشة الإعدادات
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get settings;

  /// قسم المظهر والعرض في الإعدادات
  ///
  /// In ar, this message translates to:
  /// **'المظهر والعرض'**
  String get appearanceAndDisplay;

  /// خيار المظهر الداكن
  ///
  /// In ar, this message translates to:
  /// **'المظهر الداكن'**
  String get darkMode;

  /// وصف خيار المظهر الداكن
  ///
  /// In ar, this message translates to:
  /// **'تفعيل المظهر الداكن للتطبيق'**
  String get darkModeSubtitle;

  /// خيار حجم الخط
  ///
  /// In ar, this message translates to:
  /// **'حجم الخط'**
  String get fontSize;

  /// قيمة حجم الخط الحالية
  ///
  /// In ar, this message translates to:
  /// **'متوسط'**
  String get fontSizeSubtitle;

  /// قسم اللغة والمنطقة في الإعدادات
  ///
  /// In ar, this message translates to:
  /// **'اللغة والمنطقة'**
  String get languageAndRegion;

  /// خيار اللغة
  ///
  /// In ar, this message translates to:
  /// **'اللغة'**
  String get language;

  /// خيار المنطقة الزمنية
  ///
  /// In ar, this message translates to:
  /// **'المنطقة الزمنية'**
  String get timezone;

  /// قيمة المنطقة الزمنية الحالية
  ///
  /// In ar, this message translates to:
  /// **'GMT+3 (الرياض)'**
  String get timezoneSubtitle;

  /// قسم الإشعارات في الإعدادات
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات'**
  String get notifications;

  /// خيار تفعيل الإشعارات
  ///
  /// In ar, this message translates to:
  /// **'تفعيل الإشعارات'**
  String get enableNotifications;

  /// وصف خيار تفعيل الإشعارات
  ///
  /// In ar, this message translates to:
  /// **'استقبال إشعارات التذكير'**
  String get enableNotificationsSubtitle;

  /// قسم النسخ الاحتياطي والمزامنة
  ///
  /// In ar, this message translates to:
  /// **'النسخ الاحتياطي والمزامنة'**
  String get backupAndSync;

  /// خيار النسخ الاحتياطي التلقائي
  ///
  /// In ar, this message translates to:
  /// **'النسخ الاحتياطي التلقائي'**
  String get autoBackup;

  /// وصف خيار النسخ الاحتياطي التلقائي
  ///
  /// In ar, this message translates to:
  /// **'حفظ تلقائي للملاحظات'**
  String get autoBackupSubtitle;

  /// خيار تصدير البيانات
  ///
  /// In ar, this message translates to:
  /// **'تصدير البيانات'**
  String get exportData;

  /// تنسيقات تصدير البيانات
  ///
  /// In ar, this message translates to:
  /// **'JSON, PDF, TXT'**
  String get exportDataSubtitle;

  /// خيار استيراد البيانات
  ///
  /// In ar, this message translates to:
  /// **'استيراد البيانات'**
  String get importData;

  /// وصف خيار استيراد البيانات
  ///
  /// In ar, this message translates to:
  /// **'من ملفات خارجية'**
  String get importDataSubtitle;

  /// قسم الدعم والمساعدة
  ///
  /// In ar, this message translates to:
  /// **'الدعم والمساعدة'**
  String get support;

  /// خيار مركز المساعدة
  ///
  /// In ar, this message translates to:
  /// **'مركز المساعدة'**
  String get helpCenter;

  /// وصف مركز المساعدة
  ///
  /// In ar, this message translates to:
  /// **'الأسئلة الشائعة والدروس'**
  String get helpCenterSubtitle;

  /// خيار التواصل
  ///
  /// In ar, this message translates to:
  /// **'تواصل معنا'**
  String get contactUs;

  /// معلومات التواصل
  ///
  /// In ar, this message translates to:
  /// **'support@noteapp.com'**
  String get contactUsSubtitle;

  /// خيار حول التطبيق
  ///
  /// In ar, this message translates to:
  /// **'حول التطبيق'**
  String get aboutApp;

  /// عنوان مربع حوار اللغة
  ///
  /// In ar, this message translates to:
  /// **'اختر اللغة'**
  String get selectLanguage;

  /// اللغة العربية
  ///
  /// In ar, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// اللغة الإنجليزية
  ///
  /// In ar, this message translates to:
  /// **'English'**
  String get english;

  /// اللغة الفرنسية
  ///
  /// In ar, this message translates to:
  /// **'Français'**
  String get french;

  /// زر الإلغاء
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get cancel;

  /// زر الإغلاق
  ///
  /// In ar, this message translates to:
  /// **'إغلاق'**
  String get close;

  /// رقم إصدار التطبيق
  ///
  /// In ar, this message translates to:
  /// **'الإصدار: 1.0.0'**
  String get version;

  /// مطور التطبيق
  ///
  /// In ar, this message translates to:
  /// **'تطوير: Mohamed03-T'**
  String get developer;

  /// رسالة تفعيل المظهر الداكن
  ///
  /// In ar, this message translates to:
  /// **'تم تفعيل المظهر الداكن'**
  String get darkModeEnabled;

  /// رسالة تفعيل المظهر الفاتح
  ///
  /// In ar, this message translates to:
  /// **'تم تفعيل المظهر الفاتح'**
  String get lightModeEnabled;

  /// رسالة قريباً لحجم الخط
  ///
  /// In ar, this message translates to:
  /// **'سيتم إضافة خيارات حجم الخط قريباً'**
  String get fontSizeComingSoon;

  /// رسالة قريباً للمنطقة الزمنية
  ///
  /// In ar, this message translates to:
  /// **'سيتم إضافة خيارات المنطقة الزمنية قريباً'**
  String get timezoneComingSoon;

  /// رسالة قريباً للتصدير
  ///
  /// In ar, this message translates to:
  /// **'سيتم إضافة خيارات التصدير قريباً'**
  String get exportComingSoon;

  /// رسالة قريباً للاستيراد
  ///
  /// In ar, this message translates to:
  /// **'سيتم إضافة خيارات الاستيراد قريباً'**
  String get importComingSoon;

  /// رسالة قريباً لمركز المساعدة
  ///
  /// In ar, this message translates to:
  /// **'سيتم إضافة مركز المساعدة قريباً'**
  String get helpComingSoon;

  /// رسالة قريباً للتواصل
  ///
  /// In ar, this message translates to:
  /// **'سيتم إضافة خيارات التواصل قريباً'**
  String get contactComingSoon;

  /// رسالة الترحيب
  ///
  /// In ar, this message translates to:
  /// **'مرحباً بك في تطبيق الملاحظات'**
  String get welcome;

  /// رسالة عدم وجود صفحات
  ///
  /// In ar, this message translates to:
  /// **'لا توجد صفحات بعد'**
  String get noPagesYet;

  /// رسالة إنشاء أول صفحة
  ///
  /// In ar, this message translates to:
  /// **'ابدأ بإنشاء صفحتك الأولى'**
  String get createFirstPage;

  /// زر إنشاء صفحة جديدة
  ///
  /// In ar, this message translates to:
  /// **'إنشاء صفحة جديدة'**
  String get createNewPage;

  /// تلميح إضافة صفحة جديدة
  ///
  /// In ar, this message translates to:
  /// **'إضافة صفحة جديدة'**
  String get addNewPage;

  /// تلميح إضافة مجلد جديد
  ///
  /// In ar, this message translates to:
  /// **'إضافة مجلد جديد'**
  String get addNewFolder;

  /// رسالة تحميل البيانات
  ///
  /// In ar, this message translates to:
  /// **'جاري تحميل البيانات...'**
  String get loadingData;

  /// عنوان إدارة المجلد
  ///
  /// In ar, this message translates to:
  /// **'إدارة المجلد:'**
  String get manageFolder;

  /// خيار إلغاء التثبيت
  ///
  /// In ar, this message translates to:
  /// **'إلغاء تثبيت'**
  String get unpinFolder;

  /// خيار تثبيت المجلد
  ///
  /// In ar, this message translates to:
  /// **'تثبيت المجلد'**
  String get pinFolder;

  /// خيار تغيير اسم المجلد
  ///
  /// In ar, this message translates to:
  /// **'تغيير اسم المجلد'**
  String get renameFolder;

  /// خيار تغيير لون الخلفية
  ///
  /// In ar, this message translates to:
  /// **'تغيير لون الخلفية'**
  String get changeBackgroundColor;

  /// خيار حذف المجلد
  ///
  /// In ar, this message translates to:
  /// **'حذف المجلد'**
  String get deleteFolder;

  /// تسمية اسم المجلد
  ///
  /// In ar, this message translates to:
  /// **'اسم المجلد'**
  String get folderName;

  /// زر التأكيد
  ///
  /// In ar, this message translates to:
  /// **'تأكيد'**
  String get confirm;

  /// عنوان اختيار لون الخلفية
  ///
  /// In ar, this message translates to:
  /// **'اختر لون الخلفية'**
  String get selectBackgroundColor;

  /// عنوان تأكيد الحذف
  ///
  /// In ar, this message translates to:
  /// **'تأكيد الحذف'**
  String get confirmDelete;

  /// رسالة تأكيد حذف المجلد
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد من حذف المجلد "{folderName}"؟\nسيتم حذف جميع الملاحظات الموجودة فيه.'**
  String deleteConfirmMessage(String folderName);

  /// زر الحذف
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get delete;

  /// رسالة عدم وجود مجلدات
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مجلدات'**
  String get noFolders;

  /// منذ أيام
  ///
  /// In ar, this message translates to:
  /// **'منذ {count} {count, plural, =1{يوم} other{أيام}}'**
  String daysAgo(int count);

  /// منذ ساعات
  ///
  /// In ar, this message translates to:
  /// **'منذ {count} {count, plural, =1{ساعة} other{ساعات}}'**
  String hoursAgo(int count);

  /// منذ دقائق
  ///
  /// In ar, this message translates to:
  /// **'منذ {count} {count, plural, =1{دقيقة} other{دقائق}}'**
  String minutesAgo(int count);

  /// الآن
  ///
  /// In ar, this message translates to:
  /// **'الآن'**
  String get now;

  /// العنوان الترحيبي في شاشة البداية
  ///
  /// In ar, this message translates to:
  /// **'مرحباً بك في تطبيق الملاحظات'**
  String get splashWelcomeTitle;

  /// الشرح القصير في شاشة البداية
  ///
  /// In ar, this message translates to:
  /// **'نظّم أفكارك وملاحظاتك بسهولة'**
  String get splashTagline;

  /// نص التحميل في شاشة البداية
  ///
  /// In ar, this message translates to:
  /// **'جاري التحميل...'**
  String get splashLoading;

  // Onboarding strings
  String get onboardingPage1Title;
  String get onboardingPage1Description;
  String get onboardingPage2Title;
  String get onboardingPage2Description;
  String get onboardingPage3Title;
  String get onboardingPage3Description;
  String get onboardingPage4Title;
  String get onboardingPage4Description;
  String get onboardingPage5Title;
  String get onboardingPage5Description;
  String get onboardingPage6Title;
  String get onboardingPage6Description;
  String get onboardingPage7Title;
  String get onboardingPage7Description;
  String get onboardingSkip;
  String get onboardingBack;
  String get onboardingNext;
  String get onboardingFinish;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar': return AppLocalizationsAr();
    case 'en': return AppLocalizationsEn();
    case 'fr': return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}

