import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../providers/couple_provider.dart';
import '../../providers/games_provider.dart';

class GamesScreen extends StatelessWidget {
  const GamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Couple Games')),
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
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildGameCard(
              context,
              icon: Icons.help_outline,
              title: 'Truth or Dare',
              subtitle: 'Get to know each other better',
              color: const Color(0xFFE91E63),
              onTap: () => Navigator.pushNamed(context, '/truth-or-dare'),
            ),
            const SizedBox(height: 12),
            _buildGameCard(
              context,
              icon: Icons.quiz_outlined,
              title: 'Love Quiz',
              subtitle: 'Test your knowledge about each other',
              color: const Color(0xFF9C27B0),
              onTap: () => Navigator.pushNamed(context, '/love-quiz'),
            ),
            const SizedBox(height: 12),
            _buildGameCard(
              context,
              icon: Icons.auto_awesome,
              title: 'Daily Challenge',
              subtitle: 'Complete today\'s love challenge',
              color: const Color(0xFF3F51B5),
              onTap: () => Navigator.pushNamed(context, '/daily-challenge'),
            ),
            const SizedBox(height: 12),
            _buildGameCard(
              context,
              icon: Icons.compare_arrows,
              title: 'Would You Rather',
              subtitle: 'Fun couple dilemmas',
              color: const Color(0xFFFF4081),
              onTap: () => Navigator.pushNamed(context, '/would-you-rather'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GlassCard(
      onTap: onTap,
      gradient: [color, color.withOpacity(0.5)],
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.8)),
        ],
      ),
    );
  }
}

class TruthOrDareScreen extends StatelessWidget {
  const TruthOrDareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _GamePlayScreen(
      appBarTitle: 'Truth or Dare',
      startGame: () => context.read<GamesProvider>().startTruthOrDare(),
    );
  }
}

class LoveQuizScreen extends StatelessWidget {
  const LoveQuizScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _GamePlayScreen(
      appBarTitle: 'Love Quiz',
      startGame: () => context.read<GamesProvider>().startLoveQuiz(),
    );
  }
}

class WouldYouRatherScreen extends StatelessWidget {
  const WouldYouRatherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _GamePlayScreen(
      appBarTitle: 'Would You Rather',
      startGame: () => context.read<GamesProvider>().startWouldYouRather(),
    );
  }
}

class DailyChallengeScreen extends StatelessWidget {
  const DailyChallengeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _GamePlayScreen(
      appBarTitle: 'Daily Challenge',
      startGame: () => context.read<GamesProvider>().startDailyChallenge(context.read<CoupleProvider>().couple?.id ?? ''),
    );
  }
}

class _GamePlayScreen extends StatefulWidget {
  final String appBarTitle;
  final VoidCallback startGame;

  const _GamePlayScreen({
    required this.appBarTitle,
    required this.startGame,
  });

  @override
  State<_GamePlayScreen> createState() => _GamePlayScreenState();
}

class _GamePlayScreenState extends State<_GamePlayScreen> {
  @override
  void initState() {
    super.initState();
    widget.startGame();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(widget.appBarTitle)),
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
        child: Consumer<GamesProvider>(
          builder: (_, games, __) {
            if (games.currentQuestion.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('All done!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    GradientButton(
                      text: 'Play Again',
                      onPressed: widget.startGame,
                    ),
                  ],
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        games.currentQuestion,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, height: 1.4),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (games.hasMoreQuestions)
                    GradientButton(
                      text: 'Next Question',
                      onPressed: () => games.nextQuestion(),
                    )
                  else
                    GradientButton(
                      text: 'Finish',
                      onPressed: () => Navigator.pop(context),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
