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

  /// No description provided for @allPagesTitle.
  ///
  /// In ar, this message translates to:
  /// **'جميع الصفحات'**
  String get allPagesTitle;

  /// No description provided for @latest.
  ///
  /// In ar, this message translates to:
  /// **'الأحدث'**
  String get latest;

  /// عدد المجلدات
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =0{لا توجد مجلدات} =1{مجلد واحد} other{{count} مجلدات}}'**
  String foldersCount(int count);

  /// نص آخر تحديث
  ///
  /// In ar, this message translates to:
  /// **'آخر تحديث: {when}'**
  String lastUpdated(String when);

  /// No description provided for @addPageDescription.
  ///
  /// In ar, this message translates to:
  /// **'أضف صفحة جديدة لتنظيم ملاحظاتك بشكل أفضل'**
  String get addPageDescription;

  /// No description provided for @pageName.
  ///
  /// In ar, this message translates to:
  /// **'اسم الصفحة'**
  String get pageName;

  /// No description provided for @pageNameHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: مشاريع، أفكار، مهام...'**
  String get pageNameHint;

  /// No description provided for @creating.
  ///
  /// In ar, this message translates to:
  /// **'جاري الإنشاء...'**
  String get creating;

  /// No description provided for @createPage.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء الصفحة'**
  String get createPage;

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
  /// **'هل أنت متأكد من حذف المجلد \"{folderName}\"؟\nسيتم حذف جميع الملاحظات الموجودة فيه.'**
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

  /// No description provided for @noNotes.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد ملاحظات'**
  String get noNotes;

  /// No description provided for @noFoldersYet.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مجلدات بعد'**
  String get noFoldersYet;

  /// No description provided for @tapPlusToAddFolder.
  ///
  /// In ar, this message translates to:
  /// **'انقر على + لإضافة مجلد جديد'**
  String get tapPlusToAddFolder;

  /// No description provided for @error.
  ///
  /// In ar, this message translates to:
  /// **'خطأ'**
  String get error;

  /// No description provided for @folderNotFound.
  ///
  /// In ar, this message translates to:
  /// **'المجلد غير موجود'**
  String get folderNotFound;

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

  /// No description provided for @onboardingPage1Title.
  ///
  /// In ar, this message translates to:
  /// **'تحكم كامل'**
  String get onboardingPage1Title;

  /// No description provided for @onboardingPage1Description.
  ///
  /// In ar, this message translates to:
  /// **'قم بإنشاء وتنظيم ملاحظاتك بكل سهولة داخل صفحات ومجلدات.'**
  String get onboardingPage1Description;

  /// No description provided for @onboardingPage2Title.
  ///
  /// In ar, this message translates to:
  /// **'واجهة بسيطة'**
  String get onboardingPage2Title;

  /// No description provided for @onboardingPage2Description.
  ///
  /// In ar, this message translates to:
  /// **'استمتع بواجهة مستخدم نظيفة وسهلة الاستخدام.'**
  String get onboardingPage2Description;

  /// No description provided for @onboardingPage3Title.
  ///
  /// In ar, this message translates to:
  /// **'تخصيص المظهر'**
  String get onboardingPage3Title;

  /// No description provided for @onboardingPage3Description.
  ///
  /// In ar, this message translates to:
  /// **'اختر بين الوضع الفاتح والداكن حسب رغبتك.'**
  String get onboardingPage3Description;

  /// No description provided for @onboardingPage4Title.
  ///
  /// In ar, this message translates to:
  /// **'عمل دون إنترنت'**
  String get onboardingPage4Title;

  /// No description provided for @onboardingPage4Description.
  ///
  /// In ar, this message translates to:
  /// **'التطبيق يعمل دون اتصال بالإنترنت ويخزن ملاحظاتك محلياً لضمان خصوصية عالية.'**
  String get onboardingPage4Description;

  /// No description provided for @onboardingPage5Title.
  ///
  /// In ar, this message translates to:
  /// **'اللغات المتوفرة'**
  String get onboardingPage5Title;

  /// No description provided for @onboardingPage5Description.
  ///
  /// In ar, this message translates to:
  /// **'العربية، الفرنسية، والإنجليزية لتجربة أكثر سهولة ومرونة.'**
  String get onboardingPage5Description;

  /// No description provided for @onboardingPage6Title.
  ///
  /// In ar, this message translates to:
  /// **'النسخ والاستعادة'**
  String get onboardingPage6Title;

  /// No description provided for @onboardingPage6Description.
  ///
  /// In ar, this message translates to:
  /// **'تتوفر تحديثات مستقبلية لنسخ البيانات واستعادتها، وإذا حُذف التطبيق دون نسخ احتياطي ستُفقد الملاحظات.'**
  String get onboardingPage6Description;

  /// No description provided for @onboardingPage7Title.
  ///
  /// In ar, this message translates to:
  /// **'حماية المجلدات'**
  String get onboardingPage7Title;

  /// No description provided for @onboardingPage7Description.
  ///
  /// In ar, this message translates to:
  /// **'يمكنك تعيين رمز للمجلدات لحفظ أسرارك وحمايتها.'**
  String get onboardingPage7Description;

  /// No description provided for @onboardingSkip.
  ///
  /// In ar, this message translates to:
  /// **'تخطي'**
  String get onboardingSkip;

  /// No description provided for @onboardingBack.
  ///
  /// In ar, this message translates to:
  /// **'عودة'**
  String get onboardingBack;

  /// No description provided for @onboardingNext.
  ///
  /// In ar, this message translates to:
  /// **'التالي'**
  String get onboardingNext;

  /// No description provided for @onboardingFinish.
  ///
  /// In ar, this message translates to:
  /// **'إنهاء'**
  String get onboardingFinish;

  /// No description provided for @foldersInPage.
  ///
  /// In ar, this message translates to:
  /// **'المجلدات في {page}'**
  String foldersInPage(Object page);

  /// No description provided for @noFoldersHere.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مجلدات في هذه الصفحة'**
  String get noFoldersHere;

  /// No description provided for @addNoteTitleSimple.
  ///
  /// In ar, this message translates to:
  /// **'إضافة ملاحظة'**
  String get addNoteTitleSimple;

  /// No description provided for @addNoteTitleArticle.
  ///
  /// In ar, this message translates to:
  /// **'مقال جديد'**
  String get addNoteTitleArticle;

  /// No description provided for @addNoteTitleEmail.
  ///
  /// In ar, this message translates to:
  /// **'بريد إلكتروني جديد'**
  String get addNoteTitleEmail;

  /// No description provided for @addNoteTitleChecklist.
  ///
  /// In ar, this message translates to:
  /// **'قائمة تحقق جديدة'**
  String get addNoteTitleChecklist;

  /// No description provided for @save.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get save;

  /// No description provided for @addFolderTitle.
  ///
  /// In ar, this message translates to:
  /// **'إضافة مجلد جديد'**
  String get addFolderTitle;

  /// No description provided for @createFolder.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء المجلد'**
  String get createFolder;

  /// No description provided for @addFolderDescription.
  ///
  /// In ar, this message translates to:
  /// **'أضف مجلدًا جديدًا لتنظيم الملاحظات داخل هذه الصفحة'**
  String get addFolderDescription;

  /// No description provided for @inPage.
  ///
  /// In ar, this message translates to:
  /// **'في الصفحة: {page}'**
  String inPage(Object page);

  /// No description provided for @folderNameHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: مهام يومية، أفكار، اجتماعات...'**
  String get folderNameHint;

  /// No description provided for @creatingFolder.
  ///
  /// In ar, this message translates to:
  /// **'جاري الإنشاء...'**
  String get creatingFolder;

  /// No description provided for @notificationsEnabledOn.
  ///
  /// In ar, this message translates to:
  /// **'تم تفعيل الإشعارات'**
  String get notificationsEnabledOn;

  /// No description provided for @notificationsEnabledOff.
  ///
  /// In ar, this message translates to:
  /// **'تم إيقاف الإشعارات'**
  String get notificationsEnabledOff;

  /// No description provided for @notificationSounds.
  ///
  /// In ar, this message translates to:
  /// **'أصوات الإشعارات'**
  String get notificationSounds;

  /// No description provided for @notificationSoundsSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'الصوت الافتراضي'**
  String get notificationSoundsSubtitle;

  /// No description provided for @notificationSoundsComingSoon.
  ///
  /// In ar, this message translates to:
  /// **'سيتم إضافة خيارات الأصوات قريباً'**
  String get notificationSoundsComingSoon;

  /// No description provided for @autoBackupPeriodicEnabled.
  ///
  /// In ar, this message translates to:
  /// **'تم تفعيل النسخ الدوري'**
  String get autoBackupPeriodicEnabled;

  /// وقت آخر نسخة احتياطية
  ///
  /// In ar, this message translates to:
  /// **'آخر نسخة: {date}'**
  String autoBackupLast(String date);

  /// No description provided for @autoBackupPeriodicEnabledSnackOn.
  ///
  /// In ar, this message translates to:
  /// **'تم تفعيل النسخ الدوري (يعمل أثناء تشغيل التطبيق)'**
  String get autoBackupPeriodicEnabledSnackOn;

  /// No description provided for @autoBackupPeriodicEnabledSnackOff.
  ///
  /// In ar, this message translates to:
  /// **'تم إيقاف النسخ الدوري'**
  String get autoBackupPeriodicEnabledSnackOff;

  /// No description provided for @exportBackupTitle.
  ///
  /// In ar, this message translates to:
  /// **'تصدير النسخة الاحتياطية'**
  String get exportBackupTitle;

  /// No description provided for @exportBackupSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'حفظ ملف JSON للنسخة الاحتياطية'**
  String get exportBackupSubtitle;

  /// No description provided for @exportBackupSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ النسخة الاحتياطية'**
  String get exportBackupSaved;

  /// No description provided for @exportBackupFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشل في حفظ النسخة الاحتياطية'**
  String get exportBackupFailed;

  /// No description provided for @importBackupTitle.
  ///
  /// In ar, this message translates to:
  /// **'استيراد النسخة الاحتياطية'**
  String get importBackupTitle;

  /// No description provided for @importBackupSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'اختر ملف JSON لاستيراده'**
  String get importBackupSubtitle;

  /// No description provided for @importBackupSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم استيراد النسخة الاحتياطية'**
  String get importBackupSuccess;

  /// No description provided for @importBackupFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشل في استيراد الملف'**
  String get importBackupFailed;

  /// No description provided for @restoreFromKeyTitle.
  ///
  /// In ar, this message translates to:
  /// **'استعادة من المفتاح الداخلي'**
  String get restoreFromKeyTitle;

  /// No description provided for @restoreFromKeySubtitle.
  ///
  /// In ar, this message translates to:
  /// **'استعادة من backup_notes_v2'**
  String get restoreFromKeySubtitle;

  /// No description provided for @restoreFromKeySuccess.
  ///
  /// In ar, this message translates to:
  /// **'تمت الاستعادة من المفتاح الداخلي'**
  String get restoreFromKeySuccess;

  /// No description provided for @restoreFromKeyNotFound.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد نسخة احتياطية داخلية'**
  String get restoreFromKeyNotFound;

  /// No description provided for @appInfoTitle.
  ///
  /// In ar, this message translates to:
  /// **'معلومات التطبيق'**
  String get appInfoTitle;

  /// No description provided for @appDescription.
  ///
  /// In ar, this message translates to:
  /// **'تطبيق ملاحظات حديث وأنيق مع دعم المظهر الداكن والفاتح'**
  String get appDescription;

  /// No description provided for @thankYouMessage.
  ///
  /// In ar, this message translates to:
  /// **'شكراً لاستخدام التطبيق! 💙'**
  String get thankYouMessage;

  /// No description provided for @composerHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب ملاحظة سريعة... (أو اضغط أيقونة الكتابة للخيارات المتقدمة)'**
  String get composerHint;

  /// No description provided for @composerSend.
  ///
  /// In ar, this message translates to:
  /// **'إرسال'**
  String get composerSend;

  /// No description provided for @composerCreate.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء ملاحظة'**
  String get composerCreate;

  /// No description provided for @composerSavedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ الملاحظة بنجاح ✅'**
  String get composerSavedSuccess;

  /// No description provided for @composerSavedFailure.
  ///
  /// In ar, this message translates to:
  /// **'فشل في حفظ الملاحظة ❌'**
  String get composerSavedFailure;

  /// No description provided for @composerError.
  ///
  /// In ar, this message translates to:
  /// **'خطأ: {error}'**
  String composerError(Object error);

  /// No description provided for @composerOptionSimple.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة بسيطة'**
  String get composerOptionSimple;

  /// No description provided for @composerOptionArticle.
  ///
  /// In ar, this message translates to:
  /// **'مقال / ملاحظة طويلة'**
  String get composerOptionArticle;

  /// No description provided for @composerOptionEmail.
  ///
  /// In ar, this message translates to:
  /// **'بريد إلكتروني / رسالة منسقة'**
  String get composerOptionEmail;

  /// No description provided for @composerOptionChecklist.
  ///
  /// In ar, this message translates to:
  /// **'قائمة تحقق / مهام'**
  String get composerOptionChecklist;

  /// No description provided for @composerOptionCancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get composerOptionCancel;

  /// No description provided for @noteTypeSimple.
  ///
  /// In ar, this message translates to:
  /// **'بسيطة'**
  String get noteTypeSimple;

  /// No description provided for @noteTypeArticle.
  ///
  /// In ar, this message translates to:
  /// **'مقال'**
  String get noteTypeArticle;

  /// No description provided for @noteTypeEmail.
  ///
  /// In ar, this message translates to:
  /// **'بريد إلكتروني'**
  String get noteTypeEmail;

  /// No description provided for @noteTypeChecklist.
  ///
  /// In ar, this message translates to:
  /// **'قائمة تحقق'**
  String get noteTypeChecklist;

  /// No description provided for @noteTypeText.
  ///
  /// In ar, this message translates to:
  /// **'نص'**
  String get noteTypeText;

  /// No description provided for @noteTypeImage.
  ///
  /// In ar, this message translates to:
  /// **'صورة'**
  String get noteTypeImage;

  /// No description provided for @noteTypeAudio.
  ///
  /// In ar, this message translates to:
  /// **'صوت'**
  String get noteTypeAudio;
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
