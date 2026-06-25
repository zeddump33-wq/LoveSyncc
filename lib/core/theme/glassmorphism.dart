import 'package:flutter/material.dart';
import '../constants/theme_constants.dart';

class Glassmorphism {
  static BoxDecoration glassDecoration({
    required BuildContext context,
    double blur = 20,
    double opacity = 0.15,
    double borderRadius = ThemeConstants.borderRadius,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      color: isDark
          ? Colors.white.withOpacity(opacity * 0.5)
          : Colors.white.withOpacity(opacity * 2),
      border: Border.all(
        color: isDark
            ? Colors.white.withOpacity(0.1)
            : Colors.white.withOpacity(0.5),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: isDark ? Colors.black26 : Colors.black12,
          blurRadius: blur,
          spreadRadius: 1,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  static BoxDecoration gradientGlassDecoration({
    required BuildContext context,
    List<Color>? gradient,
    double blur = 20,
    double borderRadius = ThemeConstants.borderRadius,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = gradient ?? ThemeConstants.loveGradient;
    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      gradient: LinearGradient(
        colors: colors.map((c) => c.withOpacity(0.3)).toList(),
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      border: Border.all(
        color: isDark
            ? Colors.white.withOpacity(0.1)
            : Colors.white.withOpacity(0.5),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: colors.first.withOpacity(0.3),
          blurRadius: blur,
          spreadRadius: 1,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
}
