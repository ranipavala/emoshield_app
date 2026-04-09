import 'package:flutter/material.dart';

class AppTheme {
  // Approximated from your Figma screens
  static const bgSky = Color(0xFFD7ECFF);
  static const panelBlue = Color(0xFF7FB8F0);
  static const deepBlue = Color(0xFF2F86D6);

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: bgSky,
      colorScheme: ColorScheme.fromSeed(seedColor: deepBlue),
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        bodyMedium: TextStyle(fontSize: 14),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}