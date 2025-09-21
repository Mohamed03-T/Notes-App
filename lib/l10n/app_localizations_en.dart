// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Notes App';

  @override
  String get settings => 'Settings';

  @override
  String get appearanceAndDisplay => 'Appearance & Display';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get darkModeSubtitle => 'Enable dark theme for the app';

  @override
  String get fontSize => 'Font Size';

  @override
  String get fontSizeSubtitle => 'Medium';

  @override
  String get languageAndRegion => 'Language & Region';

  @override
  String get language => 'Language';

  @override
  String get timezone => 'Timezone';

  @override
  String get timezoneSubtitle => 'GMT+3 (Riyadh)';

  @override
  String get notifications => 'Notifications';

  @override
  String get enableNotifications => 'Enable Notifications';

  @override
  String get enableNotificationsSubtitle => 'Receive reminder notifications';

  @override
  String get backupAndSync => 'Backup & Sync';

  @override
  String get autoBackup => 'Auto Backup';

  @override
  String get autoBackupSubtitle => 'Automatic note saving';

  @override
  String get exportData => 'Export Data';

  @override
  String get exportDataSubtitle => 'JSON, PDF, TXT';

  @override
  String get importData => 'Import Data';

  @override
  String get importDataSubtitle => 'From external files';

  @override
  String get support => 'Support & Help';

  @override
  String get helpCenter => 'Help Center';

  @override
  String get helpCenterSubtitle => 'FAQs and tutorials';

  @override
  String get contactUs => 'Contact Us';

  @override
  String get contactUsSubtitle => 'support@noteapp.com';

  @override
  String get aboutApp => 'About App';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get arabic => 'العربية';

  @override
  String get english => 'English';

  @override
  String get french => 'Français';

  @override
  String get cancel => 'Cancel';

  @override
  String get close => 'Close';

  @override
  String get version => 'Version: 1.0.0';

  @override
  String get developer => 'Developer: Mohamed03-T';

  @override
  String get darkModeEnabled => 'Dark mode enabled';

  @override
  String get lightModeEnabled => 'Light mode enabled';

  @override
  String get fontSizeComingSoon => 'Font size options will be added soon';

  @override
  String get timezoneComingSoon => 'Timezone options will be added soon';

  @override
  String get exportComingSoon => 'Export options will be added soon';

  @override
  String get importComingSoon => 'Import options will be added soon';

  @override
  String get helpComingSoon => 'Help center will be added soon';

  @override
  String get contactComingSoon => 'Contact options will be added soon';

  @override
  String get welcome => 'Welcome to Notes App';

  @override
  String get noPagesYet => 'No pages yet';

  @override
  String get createFirstPage => 'Start by creating your first page';

  @override
  String get createNewPage => 'Create New Page';

  @override
  String get addNewPage => 'Add new page';

  @override
  String get addNewFolder => 'Add new folder';

  @override
  String get loadingData => 'Loading data...';

  @override
  String get manageFolder => 'Manage Folder:';

  @override
  String get unpinFolder => 'Unpin';

  @override
  String get pinFolder => 'Pin Folder';

  @override
  String get renameFolder => 'Rename Folder';

  @override
  String get changeBackgroundColor => 'Change Background Color';

  @override
  String get deleteFolder => 'Delete Folder';

  @override
  String get folderName => 'Folder Name';

  @override
  String get confirm => 'Confirm';

  @override
  String get selectBackgroundColor => 'Select Background Color';

  @override
  String get confirmDelete => 'Confirm Delete';

  @override
  String deleteConfirmMessage(String folderName) {
    return 'Are you sure you want to delete the folder "${folderName}"?\nAll notes inside it will be deleted.';
  }

  @override
  String get delete => 'Delete';

  @override
  String get noFolders => 'No folders';

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes ago',
      one: '1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String get now => 'Now';

  @override
  String get splashWelcomeTitle => 'Welcome to Notes App';

  @override
  String get splashTagline => 'Organize your ideas and notes easily';

  @override
  String get splashLoading => 'Loading...';

  @override
  String get onboardingPage1Title => 'Full Control';
  @override
  String get onboardingPage1Description => 'Create and organize your notes easily within pages and folders.';
  @override
  String get onboardingPage2Title => 'Simple Interface';
  @override
  String get onboardingPage2Description => 'Enjoy a clean and easy-to-use user interface.';
  @override
  String get onboardingPage3Title => 'Theme Customization';
  @override
  String get onboardingPage3Description => 'Choose between light and dark modes as you prefer.';
  @override
  String get onboardingPage4Title => 'Offline Ready';
  @override
  String get onboardingPage4Description => 'The app works offline and stores notes locally to ensure privacy.';
  @override
  String get onboardingPage5Title => 'Multiple Languages';
  @override
  String get onboardingPage5Description => 'Arabic, French, and English supported for flexibility.';
  @override
  String get onboardingPage6Title => 'Backup & Restore';
  @override
  String get onboardingPage6Description => 'Future updates will add backup and restore; without backup notes may be lost if app is removed.';
  @override
  String get onboardingPage7Title => 'Folder Protection';
  @override
  String get onboardingPage7Description => 'Set a PIN for folders to keep your private notes safe.';
  @override
  String get onboardingSkip => 'Skip';
  @override
  String get onboardingBack => 'Back';
  @override
  String get onboardingNext => 'Next';
  @override
  String get onboardingFinish => 'Finish';
}
