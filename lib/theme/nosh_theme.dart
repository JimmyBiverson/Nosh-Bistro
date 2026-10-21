import 'package:flutter/material.dart';

abstract final class NoshTheme {
  static const background = Color(0xFF1C110A);
  static const surface = Color(0xFF291D15);
  static const surfaceLow = Color(0xFF251911);
  static const surfaceHigh = Color(0xFF35271F);
  static const primary = Color(0xFFFF6D00);
  static const primarySoft = Color(0xFFFFB692);
  static const amber = Color(0xFFEBC23E);
  static const text = Color(0xFFF6DED1);
  static const muted = Color(0xFFB9A49A);
  static const outline = Color(0xFF594136);
  static const error = Color(0xFFFFB4AB);

  static ThemeData get theme {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: primary,
      onPrimary: Color(0xFF341100),
      secondary: Color(0xFFFFB59A),
      onSecondary: Color(0xFF5B1B00),
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      surface: surface,
      onSurface: text,
      surfaceContainerLowest: Color(0xFF160C06),
      surfaceContainerLow: surfaceLow,
      surfaceContainer: surface,
      surfaceContainerHigh: surfaceHigh,
      surfaceContainerHighest: Color(0xFF403229),
      outline: outline,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      fontFamily: 'Plus Jakarta Sans',
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: text,
        elevation: 0,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceHigh,
        hintStyle: const TextStyle(color: muted),
        labelStyle: const TextStyle(color: muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceHigh,
        contentTextStyle: const TextStyle(color: text),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
