import 'package:flutter/material.dart';
import 'tokens.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppTokens.bg,
    primaryColor: AppTokens.gold,
    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: AppTokens.white,
      foregroundColor: AppTokens.black,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppTokens.black),
      bodyMedium: TextStyle(color: AppTokens.black),
    ),
  );
}
