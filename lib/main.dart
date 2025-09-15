import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'screens/notes/notes_home.dart';
import 'screens/onboarding/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NotesApp());
}

class NotesApp extends StatelessWidget {
  const NotesApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeManager.instance,
      builder: (context, child) {
        return FutureBuilder<bool>(
          future: SharedPreferences.getInstance()
              .then((prefs) => prefs.getBool('seenOnboarding') ?? false),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const CircularProgressIndicator();
            }
            final seen = snapshot.data!;
            return MaterialApp(
              title: 'Notes',
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: ThemeManager.instance.isDarkMode 
                  ? ThemeMode.dark 
                  : ThemeMode.light,
              home: seen ? const NotesHome() : const OnboardingScreen(),
              debugShowCheckedModeBanner: false,
            );
          },
        );
      },
    );
  }
}
