import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../constants/theme_constants.dart';
import '../utils/platform_image_loader.dart';

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black26,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ThemeConstants.screenPadding,
        vertical: 12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              child: Text(
                actionLabel!,
                style: const TextStyle(
                  color: ThemeConstants.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class AvatarWidget extends StatelessWidget {
  final String? photoPath;
  final String name;
  final double size;

  const AvatarWidget({
    super.key,
    this.photoPath,
    required this.name,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    if (photoPath != null && photoPath!.isNotEmpty) {
      if (photoPath!.startsWith('http')) {
        return ClipOval(
          child: Image.network(
            photoPath!,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildInitials(),
          ),
        );
      } else if (!kIsWeb) {
        return ClipOval(
          child: platformImageWidget(
            photoPath!,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildInitials(),
          ),
        );
      }
    }
    return _buildInitials();
  }

  Widget _buildInitials() {
    final initials = name.isNotEmpty
        ? name.split(' ').map((n) => n[0]).take(2).join().toUpperCase()
        : '?';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [ThemeConstants.primaryColor, ThemeConstants.secondaryColor],
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
