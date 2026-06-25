import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/theme_constants.dart';
import '../../core/widgets/glass_card.dart';
import '../../providers/auth_provider.dart';
import '../../providers/statistics_provider.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final auth = context.read<AuthProvider>();
    if (auth.user != null) {
      await context.read<StatisticsProvider>().loadStatistics(
            auth.user!.coupleId ?? '',
            auth.user!.id,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
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
        child: Consumer<StatisticsProvider>(
          builder: (_, stats, __) {
            if (stats.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Your Love Story at a Glance',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),

                  // Stats grid
                  Row(
                    children: [
                      Expanded(child: _buildStatCard(context, 'Days', stats.daysTogether.toString(), Icons.favorite, Colors.red)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatCard(context, 'Goals Done', stats.goalsCompleted.toString(), Icons.emoji_events, Colors.amber)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildStatCard(context, 'Memories', stats.memoriesSaved.toString(), Icons.photo_album, Colors.blue)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatCard(context, 'Streak', '${stats.currentStreak}', Icons.local_fire_department, Colors.orange)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildStatCard(context, 'Messages', stats.totalMessages.toString(), Icons.chat, Colors.purple)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatCard(context, 'Moods', stats.moodEntries.toString(), Icons.mood, Colors.green)),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color) {
    return GlassCard(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.1),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: ThemeConstants.primaryColor,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13),
          ),
        ],
      ),
    );
  }
}
