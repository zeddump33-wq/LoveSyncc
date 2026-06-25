import 'package:flutter/material.dart';

class ResponsiveShell extends StatelessWidget {
  final Widget child;
  final double maxContentWidth;
  final EdgeInsetsGeometry padding;

  const ResponsiveShell({
    super.key,
    required this.child,
    this.maxContentWidth = 1200,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final isWide = constraints.maxWidth >= 900;
        final paddedChild = Padding(
          padding: padding,
          child: child,
        );

        if (!isWide) return paddedChild;

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: paddedChild,
          ),
        );
      },
    );
  }
}
