import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/language_manager.dart';
import 'screens/notes/notes_home.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LanguageManager.instance.initializeLanguage();
  runApp(const NotesApp());
}

class NotesApp extends StatelessWidget {
  const NotesApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([ThemeManager.instance, LanguageManager.instance]),
      builder: (context, child) {
        return FutureBuilder<bool>(
          future: SharedPreferences.getInstance()
              .then((prefs) => prefs.getBool('seenOnboarding') ?? false),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const MaterialApp(
                home: Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                ),
              );
            }
            final seen = snapshot.data!;
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
              home: seen ? const NotesHome() : const OnboardingScreen(),
              debugShowCheckedModeBanner: false,
            );
          },
        );
      },
    );
  }
}
