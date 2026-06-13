import 'package:flutter/material.dart';

extension AppColorSchemeX on ColorScheme {
  Color get backgroundPrimary => surface;

  Color get backgroundSecondary =>
      brightness == Brightness.dark ? surfaceContainerLow : surfaceContainer;

  Color get cardBackground => surfaceContainerHighest;

  Gradient get pageGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: brightness == Brightness.dark
            ? const [Color(0xFF1A1A2E), Color(0xFF16213E)]
            : [surface, surfaceContainerLow],
      );

  Color overlayOnSurface(double darkAlpha, {double? lightAlpha}) =>
      brightness == Brightness.dark
          ? Colors.white.withValues(alpha: darkAlpha)
          : Colors.black.withValues(alpha: lightAlpha ?? darkAlpha);

  Color get textPrimary =>
      brightness == Brightness.dark ? Colors.white : Colors.black87;

  Color get textSecondary => brightness == Brightness.dark
      ? Colors.white.withValues(alpha: 0.7)
      : Colors.black54;

  Color borderWithOverlay(double darkAlpha, {double? lightAlpha}) =>
      brightness == Brightness.dark
          ? Colors.white.withValues(alpha: darkAlpha)
          : Colors.black.withValues(alpha: lightAlpha ?? darkAlpha);

  Color shadowWithOverlay(double darkAlpha, {double? lightAlpha}) =>
      Colors.black.withValues(
        alpha: brightness == Brightness.dark
            ? darkAlpha
            : (lightAlpha ?? darkAlpha),
      );
}
