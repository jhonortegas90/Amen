import 'package:flutter/material.dart';

import 'amen_colors.dart';

class AmenTheme {
  const AmenTheme._();

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: AmenColors.amenGold,
      brightness: Brightness.dark,
      surface: AmenColors.deepSpace,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme.copyWith(
        primary: AmenColors.amenGold,
        secondary: AmenColors.blueMist,
        surface: AmenColors.deepSpace,
        onSurface: AmenColors.text,
        error: AmenColors.danger,
      ),
      scaffoldBackgroundColor: AmenColors.deepSpace,
      fontFamily: 'SF Pro Display',
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: AmenColors.text,
          fontSize: 34,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
          height: 1.12,
        ),
        headlineMedium: TextStyle(
          color: AmenColors.text,
          fontSize: 26,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
          height: 1.18,
        ),
        titleLarge: TextStyle(
          color: AmenColors.text,
          fontSize: 20,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
        ),
        bodyLarge: TextStyle(
          color: AmenColors.text,
          fontSize: 17,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
          height: 1.35,
        ),
        bodyMedium: TextStyle(
          color: AmenColors.mutedText,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
          height: 1.35,
        ),
        labelLarge: TextStyle(
          color: AmenColors.amenGold,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        modalBackgroundColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AmenColors.night.withValues(alpha: 0.72),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: AmenColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: AmenColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: AmenColors.amenGold, width: 1.4),
        ),
      ),
    );
  }
}
