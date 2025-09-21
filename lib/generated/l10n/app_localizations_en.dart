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
  String get allPagesTitle => 'All Pages';

  @override
  String get latest => 'Latest';

  @override
  String foldersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count folders',
      one: '1 folder',
      zero: 'No folders',
    );
    return '$_temp0';
  }

  @override
  String lastUpdated(String when) {
    return 'Last updated: $when';
  }

  @override
  String get addPageDescription => 'Add a new page to organize your notes better';

  @override
  String get pageName => 'Page Name';

  @override
  String get pageNameHint => 'e.g.: Projects, Ideas, Tasks...';

  @override
  String get creating => 'Creating...';

  @override
  String get createPage => 'Create Page';

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
    return 'Are you sure you want to delete the folder \"$folderName\"?\nAll notes inside it will be deleted.';
  }

  @override
  String get delete => 'Delete';

  @override
  String get noFolders => 'No folders';

  @override
  String get noNotes => 'No notes';

  @override
  String get noFoldersYet => 'No folders yet';

  @override
  String get tapPlusToAddFolder => 'Tap + to add a new folder';

  @override
  String get error => 'Error';

  @override
  String get folderNotFound => 'Folder not found';

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

  @override
  String foldersInPage(Object page) {
    return 'Folders in $page';
  }

  @override
  String get noFoldersHere => 'No folders in this page';

  @override
  String get addNoteTitleSimple => 'Add Note';

  @override
  String get addNoteTitleArticle => 'New Article';

  @override
  String get addNoteTitleEmail => 'New Email';

  @override
  String get addNoteTitleChecklist => 'New Checklist';

  @override
  String get save => 'Save';

  @override
  String get addFolderTitle => 'Add New Folder';

  @override
  String get createFolder => 'Create Folder';

  @override
  String get addFolderDescription => 'Add a new folder to organize notes within this page';

  @override
  String inPage(Object page) {
    return 'In page: $page';
  }

  @override
  String get folderNameHint => 'e.g.: Daily Tasks, Ideas, Meetings...';

  @override
  String get creatingFolder => 'Creating...';

  @override
  String get notificationsEnabledOn => 'Notifications enabled';

  @override
  String get notificationsEnabledOff => 'Notifications disabled';

  @override
  String get notificationSounds => 'Notification Sounds';

  @override
  String get notificationSoundsSubtitle => 'Default sound';

  @override
  String get notificationSoundsComingSoon => 'Notification sound options will be added soon';

  @override
  String get autoBackupPeriodicEnabled => 'Auto backup is enabled';

  @override
  String autoBackupLast(String date) {
    return 'Last backup: $date';
  }

  @override
  String get autoBackupPeriodicEnabledSnackOn => 'Auto backup enabled (runs while app is in memory)';

  @override
  String get autoBackupPeriodicEnabledSnackOff => 'Auto backup disabled';

  @override
  String get exportBackupTitle => 'Export Backup';

  @override
  String get exportBackupSubtitle => 'Save a JSON backup file';

  @override
  String get exportBackupSaved => 'Backup saved';

  @override
  String get exportBackupFailed => 'Failed to save backup';

  @override
  String get importBackupTitle => 'Import Backup';

  @override
  String get importBackupSubtitle => 'Pick a JSON file to import';

  @override
  String get importBackupSuccess => 'Backup imported';

  @override
  String get importBackupFailed => 'Failed to import file';

  @override
  String get restoreFromKeyTitle => 'Restore from internal key';

  @override
  String get restoreFromKeySubtitle => 'Restore from backup_notes_v2';

  @override
  String get restoreFromKeySuccess => 'Restored from internal key';

  @override
  String get restoreFromKeyNotFound => 'No internal backup found';

  @override
  String get appInfoTitle => 'App Information';

  @override
  String get appDescription => 'A modern and elegant notes app with dark and light theme support';

  @override
  String get thankYouMessage => 'Thanks for using the app! 💙';

  @override
  String get composerHint => 'Type a quick note... (or press the write icon for advanced options)';

  @override
  String get composerSend => 'Send';

  @override
  String get composerCreate => 'Create note';

  @override
  String get composerSavedSuccess => 'Note saved successfully ✅';

  @override
  String get composerSavedFailure => 'Failed to save note ❌';

  @override
  String composerError(Object error) {
    return 'Error: $error';
  }

  @override
  String get composerOptionSimple => 'Simple note';

  @override
  String get composerOptionArticle => 'Article / long note';

  @override
  String get composerOptionEmail => 'Email / formatted message';

  @override
  String get composerOptionChecklist => 'Checklist / tasks';

  @override
  String get composerOptionCancel => 'Cancel';

  @override
  String get noteTypeSimple => 'Simple';

  @override
  String get noteTypeArticle => 'Article';

  @override
  String get noteTypeEmail => 'Email';

  @override
  String get noteTypeChecklist => 'Checklist';

  @override
  String get noteTypeText => 'Text';

  @override
  String get noteTypeImage => 'Image';

  @override
  String get noteTypeAudio => 'Audio';
}
