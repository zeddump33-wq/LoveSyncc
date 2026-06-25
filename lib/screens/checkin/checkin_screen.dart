import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/theme_constants.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../providers/checkin_provider.dart';

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> with TickerProviderStateMixin {
  final _answerController = TextEditingController();
  String? _selectedMood;
  final Map<String, AnimationController> _moodControllers = {};

  final _moods = [
    _MoodData('amazing', Icons.emoji_emotions, const Color(0xFFFFD700)),
    _MoodData('happy', Icons.sentiment_satisfied, const Color(0xFF4CAF50)),
    _MoodData('good', Icons.sentiment_neutral, const Color(0xFF2196F3)),
    _MoodData('neutral', Icons.sentiment_neutral, const Color(0xFF9E9E9E)),
    _MoodData('sad', Icons.sentiment_dissatisfied, const Color(0xFF607D8B)),
    _MoodData('angry', Icons.mood_bad, const Color(0xFFF44336)),
    _MoodData('loved', Icons.favorite, const Color(0xFFE91E63)),
  ];

  @override
  void initState() {
    super.initState();
    for (final m in _moods) {
      _moodControllers[m.label] = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 200),
      );
    }
  }

  @override
  void dispose() {
    for (final c in _moodControllers.values) {
      c.dispose();
    }
    _answerController.dispose();
    super.dispose();
  }

  void _saveMood(String mood) {
    _moodControllers[mood]?.forward().then((_) => _moodControllers[mood]?.reverse());
    setState(() => _selectedMood = mood);
    context.read<CheckInProvider>().saveMood(mood);
  }

  Future<void> _saveCheckIn() async {
    final answer = _answerController.text.trim();
    if (answer.isEmpty) return;

    await context.read<CheckInProvider>().saveCheckIn(answer);
    _answerController.clear();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sent to partner!'), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Check-In')),
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
        child: Consumer<CheckInProvider>(
          builder: (_, checkin, __) => SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mood Section
                GlassCard(
                  child: Column(
                    children: [
                      const Text('How are you feeling today?',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: _moods.map((m) {
                          final ctrl = _moodControllers[m.label]!;
                          return GestureDetector(
                            onTap: () => _saveMood(m.label),
                            child: AnimatedBuilder(
                              animation: ctrl,
                              builder: (_, child) {
                                final scale = 1.0 + (ctrl.value * 0.15);
                                return Transform.scale(
                                  scale: scale,
                                  child: child,
                                );
                              },
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 120),
                                    curve: Curves.easeOut,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _selectedMood == m.label
                                          ? m.color
                                          : m.color.withOpacity(0.1),
                                      border: Border.all(
                                        color: _selectedMood == m.label
                                            ? m.color
                                            : Colors.transparent,
                                        width: 2,
                                      ),
                                      boxShadow: _selectedMood == m.label
                                          ? [BoxShadow(color: m.color.withOpacity(0.4), blurRadius: 12, spreadRadius: 1)]
                                          : null,
                                    ),
                                    child: Icon(
                                      m.icon,
                                      color: _selectedMood == m.label
                                          ? Colors.white
                                          : m.color,
                                      size: 30,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(m.label,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: _selectedMood == m.label
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: _selectedMood == m.label
                                            ? m.color
                                            : null,
                                      )),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      if (checkin.todayMood != null) ...[
                        const SizedBox(height: 12),
                        Text('Today\'s mood: ${checkin.todayMood}',
                            style: const TextStyle(color: ThemeConstants.primaryColor)),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, size: 14, color: Colors.green),
                            const SizedBox(width: 4),
                            Text('Sent to partner!',
                                style: TextStyle(fontSize: 12, color: Colors.green)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Streak
                Row(
                  children: [
                    const Icon(Icons.local_fire_department, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text('${checkin.currentStreak} day streak',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                if (checkin.partnerTodayMood != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: ThemeConstants.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.favorite, color: Color(0xFFE91E63), size: 18),
                        const SizedBox(width: 8),
                        Text('Partner feels: ${checkin.partnerTodayMood}',
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),

                // Daily Question Section
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(checkin.todayQuestion,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.4)),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _answerController,
                        decoration: const InputDecoration(
                          hintText: 'Write your answer...',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      GradientButton(
                        text: checkin.hasCheckedInToday ? 'Send to Partner' : 'Send to Partner',
                        onPressed: _saveCheckIn,
                      ),
                      if (checkin.hasCheckedInToday)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle, size: 14, color: Colors.green),
                              const SizedBox(width: 4),
                              Text('Sent to partner!',
                                  style: TextStyle(fontSize: 12, color: Colors.green)),
                            ],
                          ),
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

class _MoodData {
  final String label;
  final IconData icon;
  final Color color;
  _MoodData(this.label, this.icon, this.color);
}
