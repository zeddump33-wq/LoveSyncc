import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/theme_constants.dart';
import '../../core/widgets/glass_card.dart';
import '../../providers/couple_provider.dart';

class MilestonesScreen extends StatelessWidget {
  const MilestonesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Our Milestones')),
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
        child: Consumer<CoupleProvider>(
          builder: (_, couple, __) {
            final milestones = couple.milestones;
            if (milestones.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.emoji_events_outlined, size: 64,
                        color: ThemeConstants.primaryColor.withOpacity(0.3)),
                    const SizedBox(height: 16),
                    Text('No milestones yet',
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    Text('Milestones will appear as you celebrate\nyour love journey together',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: milestones.length,
              itemBuilder: (_, i) {
                final m = milestones[i];
                final icon = _iconForMilestone(m.icon);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GlassCard(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: ThemeConstants.primaryColor.withOpacity(0.15),
                        child: Icon(icon, color: ThemeConstants.primaryColor),
                      ),
                      title: Text(m.title,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(m.date),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  IconData _iconForMilestone(String? icon) {
    switch (icon) {
      case 'favorite': return Icons.favorite;
      case 'celebration': return Icons.celebration;
      case 'diamond': return Icons.diamond;
      case 'stars': return Icons.stars;
      case 'cake': return Icons.cake;
      default: return Icons.emoji_events;
    }
  }
}
