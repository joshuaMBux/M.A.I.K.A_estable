import 'package:flutter/material.dart';

extension AppColorSchemeX on ColorScheme {
  Color get backgroundPrimary => surface;

  Color get cardBackground => surfaceContainerHighest;

  Color overlayOnSurface(double alpha) => brightness == Brightness.dark
      ? Colors.white.withValues(alpha: alpha)
      : Colors.black.withValues(alpha: alpha);

  Color get textPrimary =>
      brightness == Brightness.dark ? Colors.white : Colors.black87;

  Color get textSecondary => brightness == Brightness.dark
      ? Colors.white.withValues(alpha: 0.7)
      : Colors.black54;

  Color borderWithOverlay(double alpha) => brightness == Brightness.dark
      ? Colors.white.withValues(alpha: alpha)
      : Colors.black.withValues(alpha: alpha);
}
