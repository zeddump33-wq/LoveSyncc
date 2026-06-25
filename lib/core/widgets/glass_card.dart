import 'package:flutter/material.dart';
import '../constants/theme_constants.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final double blur;
  final List<Color>? gradient;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = ThemeConstants.borderRadius,
    this.blur = 20,
    this.gradient,
    this.margin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(ThemeConstants.cardPadding),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: isDark
            ? Colors.white.withOpacity(0.08)
            : Colors.white.withOpacity(0.7),
        gradient: gradient != null
            ? LinearGradient(
                colors: gradient!.map((c) => c.withOpacity(0.2)).toList(),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
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
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: card);
    }
    return card;
  }
}
