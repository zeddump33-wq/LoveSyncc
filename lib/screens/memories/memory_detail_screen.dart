import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/utils/platform_image_loader.dart';
import '../../models/memory_model.dart';

class MemoryDetailScreen extends StatelessWidget {
  final MemoryModel memory;

  const MemoryDetailScreen({super.key, required this.memory});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                : [const Color(0xFFFDF2F8), const Color(0xFFFFF5F9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (memory.imagePath != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: kIsWeb
                        ? Image.network(
                            memory.imagePath!,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Container(
                              height: 300,
                              color: Colors.grey[300],
                              child: const Center(child: Icon(Icons.broken_image, size: 64)),
                            ),
                          )
                        : platformImageWidget(
                            memory.imagePath!,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Container(
                              height: 300,
                              color: Colors.grey[300],
                              child: const Center(child: Icon(Icons.broken_image, size: 64)),
                            ),
                          ),
                  ),
                const SizedBox(height: 20),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (memory.caption != null) ...[
                        Text(memory.caption!, style: Theme.of(context).textTheme.bodyLarge),
                        const SizedBox(height: 12),
                      ],
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            memory.date,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const Spacer(),
                          Icon(
                            memory.isFavorite == 1 ? Icons.favorite : Icons.favorite_border,
                            color: memory.isFavorite == 1 ? Colors.red : Colors.grey,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
