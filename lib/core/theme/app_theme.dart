import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData dark() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
        ).copyWith(
          surface: AppColors.darkSurface,
          surfaceContainerHighest: AppColors.darkSurfaceVariant,
          surfaceContainerHigh: AppColors.darkSurfaceVariant,
          surfaceContainer: AppColors.darkSurface,
          surfaceContainerLow: AppColors.darkSurface,
          surfaceContainerLowest: AppColors.darkSurface,
          primary: AppColors.primary,
          secondary: AppColors.primaryVariant,
          tertiary: AppColors.success,
          error: AppColors.error,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onTertiary: Colors.white,
          onError: Colors.white,
          onSurface: Colors.white,
        );
    return _baseTheme(scheme);
  }

  static ThemeData light() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ).copyWith(
          surface: AppColors.lightSurface,
          surfaceContainerHighest: AppColors.lightSurfaceVariant,
          surfaceContainerHigh: AppColors.lightSurfaceVariant,
          surfaceContainer: AppColors.lightSurface,
          surfaceContainerLow: AppColors.lightSurface,
          surfaceContainerLowest: AppColors.lightSurface,
          primary: AppColors.primary,
          secondary: AppColors.primaryVariant,
          tertiary: AppColors.success,
          error: AppColors.error,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onTertiary: Colors.white,
          onError: Colors.white,
          onSurface: Colors.black87,
        );
    return _baseTheme(scheme);
  }

  static ThemeData _baseTheme(ColorScheme scheme) {
    final surfaceContainer = scheme.surfaceContainer;
    final surfaceHighest = scheme.surfaceContainerHighest;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      fontFamily: 'Inter',
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.primary,
        contentTextStyle: TextStyle(
          color: scheme.onPrimary,
          fontWeight: FontWeight.w600,
        ),
        behavior: SnackBarBehavior.floating,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
      ),
      textTheme: _textTheme(scheme),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: scheme.surface.withValues(alpha: 0.85),
        selectedItemColor: scheme.primary,
        unselectedItemColor: scheme.onSurface.withValues(alpha: 0.6),
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary),
        ),
        hintStyle: TextStyle(
          color: scheme.onSurface.withValues(alpha: 0.55),
          fontSize: 13,
        ),
        labelStyle: TextStyle(color: scheme.onSurface.withValues(alpha: 0.8)),
      ),
      cardColor: surfaceContainer,
      canvasColor: scheme.surface,
    );
  }

  static TextTheme _textTheme(ColorScheme scheme) {
    return TextTheme(
      titleLarge: TextStyle(
        color: scheme.onSurface,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: TextStyle(
        color: scheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: TextStyle(
        color: scheme.onSurface.withValues(alpha: 0.9),
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(color: scheme.onSurface, fontSize: 16, height: 1.5),
      bodyMedium: TextStyle(
        color: scheme.onSurface.withValues(alpha: 0.85),
        fontSize: 14,
        height: 1.45,
      ),
      bodySmall: TextStyle(
        color: scheme.onSurface.withValues(alpha: 0.7),
        fontSize: 12,
      ),
      labelLarge: TextStyle(
        color: scheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
