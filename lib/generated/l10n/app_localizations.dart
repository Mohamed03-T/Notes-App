import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationsDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/l10n.dart';
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
/// To configure the locales supported by your app, you'll need to edit this
/// file.
///
/// First, open your project's ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project's Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the supportedLocales parameter
/// of your application's MaterialApp.
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

  /// A list of all valid language codes
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fr')
  ];

  /// عنوان التطبيق
  String get appTitle;

  /// عنوان شاشة الإعدادات
  String get settings;

  /// قسم المظهر والعرض في الإعدادات
  String get appearanceAndDisplay;

  /// خيار المظهر الداكن
  String get darkMode;

  /// وصف خيار المظهر الداكن
  String get darkModeSubtitle;

  /// خيار حجم الخط
  String get fontSize;

  /// قيمة حجم الخط الحالية
  String get fontSizeSubtitle;

  /// قسم اللغة والمنطقة في الإعدادات
  String get languageAndRegion;

  /// خيار اللغة
  String get language;

  /// خيار المنطقة الزمنية
  String get timezone;

  /// قيمة المنطقة الزمنية الحالية
  String get timezoneSubtitle;

  /// قسم الإشعارات في الإعدادات
  String get notifications;

  /// خيار تفعيل الإشعارات
  String get enableNotifications;

  /// وصف خيار تفعيل الإشعارات
  String get enableNotificationsSubtitle;

  /// قسم النسخ الاحتياطي والمزامنة
  String get backupAndSync;

  /// خيار النسخ الاحتياطي التلقائي
  String get autoBackup;

  /// وصف خيار النسخ الاحتياطي التلقائي
  String get autoBackupSubtitle;

  /// خيار تصدير البيانات
  String get exportData;

  /// تنسيقات تصدير البيانات
  String get exportDataSubtitle;

  /// خيار استيراد البيانات
  String get importData;

  /// وصف خيار استيراد البيانات
  String get importDataSubtitle;

  /// قسم الدعم والمساعدة
  String get support;

  /// خيار مركز المساعدة
  String get helpCenter;

  /// وصف مركز المساعدة
  String get helpCenterSubtitle;

  /// خيار التواصل
  String get contactUs;

  /// معلومات التواصل
  String get contactUsSubtitle;

  /// خيار حول التطبيق
  String get aboutApp;

  /// عنوان مربع حوار اللغة
  String get selectLanguage;

  /// اللغة العربية
  String get arabic;

  /// اللغة الإنجليزية
  String get english;

  /// اللغة الفرنسية
  String get french;

  /// زر الإلغاء
  String get cancel;

  /// زر الإغلاق
  String get close;

  /// رقم إصدار التطبيق
  String get version;

  /// مطور التطبيق
  String get developer;

  /// رسالة تفعيل المظهر الداكن
  String get darkModeEnabled;

  /// رسالة تفعيل المظهر الفاتح
  String get lightModeEnabled;

  /// رسالة قريباً لحجم الخط
  String get fontSizeComingSoon;

  /// رسالة قريباً للمنطقة الزمنية
  String get timezoneComingSoon;

  /// رسالة قريباً للتصدير
  String get exportComingSoon;

  /// رسالة قريباً للاستيراد
  String get importComingSoon;

  /// رسالة قريباً لمركز المساعدة
  String get helpComingSoon;

  /// رسالة قريباً للتواصل
  String get contactComingSoon;

  /// رسالة الترحيب
  String get welcome;

  /// رسالة عدم وجود صفحات
  String get noPagesYet;

  /// رسالة إنشاء أول صفحة
  String get createFirstPage;

  /// زر إنشاء صفحة جديدة
  String get createNewPage;

  /// تلميح إضافة صفحة جديدة
  String get addNewPage;

  /// تلميح إضافة مجلد جديد
  String get addNewFolder;

  /// رسالة تحميل البيانات
  String get loadingData;

  /// عنوان إدارة المجلد
  String get manageFolder;

  /// خيار إلغاء التثبيت
  String get unpinFolder;

  /// خيار تثبيت المجلد
  String get pinFolder;

  /// خيار تغيير اسم المجلد
  String get renameFolder;

  /// خيار تغيير لون الخلفية
  String get changeBackgroundColor;

  /// خيار حذف المجلد
  String get deleteFolder;

  /// تسمية اسم المجلد
  String get folderName;

  /// زر التأكيد
  String get confirm;

  /// عنوان اختيار لون الخلفية
  String get selectBackgroundColor;

  /// عنوان تأكيد الحذف
  String get confirmDelete;

  /// رسالة تأكيد حذف المجلد
  String deleteConfirmMessage(String folderName);

  /// زر الحذف
  String get delete;

  /// رسالة عدم وجود مجلدات
  String get noFolders;

  /// منذ أيام
  String daysAgo(int count);

  /// منذ ساعات
  String hoursAgo(int count);

  /// منذ دقائق
  String minutesAgo(int count);

  /// الآن
  String get now;
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
      'an issue with the localizations generation tool. Please file an issue on GitHub with a '
      'reproducible sample app and the gen-l10n configuration that was used.');
}
