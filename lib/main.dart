import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'services/backup/backup_service.dart';
import 'core/utils/language_manager.dart';
import 'screens/splash_screen.dart';
import 'generated/l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LanguageManager.instance.initializeLanguage();
  // Initialize automatic backup scheduler (workmanager + prefs)
  try {
    await BackupService.instance.initBackupScheduler();
  } catch (e) {
    debugPrint('Failed to init BackupService: $e');
  }
  runApp(const NotesApp());
}

class NotesApp extends StatelessWidget {
  const NotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([ThemeManager.instance, LanguageManager.instance]),
      builder: (context, child) {
        return MaterialApp(
          title: 'Notes',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeManager.instance.isDarkMode 
              ? ThemeMode.dark 
              : ThemeMode.light,
          locale: LanguageManager.instance.currentLocale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: LanguageManager.instance.supportedLocales,
          home: const SplashScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
