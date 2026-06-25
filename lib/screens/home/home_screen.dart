import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/theme_constants.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/animated_heart.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/utils/date_utils.dart';
import '../../providers/auth_provider.dart';
import '../../providers/couple_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/memories_provider.dart';
import '../../providers/goals_provider.dart';
import '../../providers/love_notes_provider.dart';
import '../../providers/calendar_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../providers/checkin_provider.dart';
import '../../providers/games_provider.dart';
import '../../providers/statistics_provider.dart';
import '../memories/memories_screen.dart';
import '../profile/profile_screen.dart';
import '../chat/chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final auth = context.read<AuthProvider>();
    final couple = context.read<CoupleProvider>();

    // Clear all provider state to prevent stale data from previous session
    context.read<ChatProvider>().clear();
    context.read<MemoriesProvider>().clear();
    context.read<GoalsProvider>().clear();
    context.read<LoveNotesProvider>().clear();
    context.read<CalendarProvider>().clear();
    context.read<WishlistProvider>().clear();
    context.read<CheckInProvider>().clear();
    context.read<GamesProvider>().clear();
    context.read<StatisticsProvider>().clear();

    if (auth.user?.coupleId != null) {
      await couple.loadCouple(auth.user!.coupleId!);
      await context.read<CheckInProvider>().loadData(auth.user!.coupleId!, auth.user!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CoupleProvider>(
      builder: (_, couple, __) {
        final showChat = couple.isLinked;
        final screens = [
          if (showChat) const ChatRoomScreen(),
          const _DashboardScreen(),
          const MemoriesScreen(),
          const ProfileScreen(),
        ];
        final navItems = [
          if (showChat)
            BottomNavigationBarItem(
              icon: Consumer<ChatProvider>(
                builder: (_, chat, __) {
                  final unread = chat.unreadCount;
                  return unread > 0
                      ? Badge(
                          label: Text(unread.toString()),
                          child: const Icon(Icons.chat_outlined),
                        )
                      : const Icon(Icons.chat_outlined);
                },
              ),
              label: 'Chat',
            ),
          const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          const BottomNavigationBarItem(icon: Icon(Icons.favorite_outline), label: 'Memories'),
          const BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ];

        if (_currentIndex >= screens.length) {
          _currentIndex = showChat ? 0 : 1;
        }

        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: screens,
          ),
          bottomNavigationBar: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF16213E)
                  : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Theme(
                data: Theme.of(context).copyWith(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                ),
                child: BottomNavigationBar(
                  currentIndex: _currentIndex,
                  onTap: (i) => setState(() => _currentIndex = i),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  selectedItemColor: ThemeConstants.primaryColor,
                  unselectedItemColor: Colors.grey,
                  type: BottomNavigationBarType.fixed,
                  items: navItems,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DashboardScreen extends StatelessWidget {
  const _DashboardScreen();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
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
          padding: const EdgeInsets.all(ThemeConstants.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Consumer<AuthProvider>(
                builder: (_, auth, __) => Row(
                  children: [
                    AvatarWidget(
                      name: auth.user?.name ?? 'Me',
                      photoPath: auth.user?.photoPath,
                      size: 48,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, ${auth.user?.name ?? 'Love'}!',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          Text(
                            'Beautiful day to be in love',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    Consumer<CoupleProvider>(
                      builder: (_, couple, __) => Text(
                        '${couple.daysTogether} days 💕',
                        style: const TextStyle(
                          color: ThemeConstants.primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildLoveCounter(context),
              const SizedBox(height: 20),
              _buildQuickActions(context),
              const SizedBox(height: 20),
              _buildTodayMood(context),
              const SizedBox(height: 20),
              _buildUpcomingSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoveCounter(BuildContext context) {
    return Consumer<CoupleProvider>(
      builder: (_, couple, __) {
        final days = couple.daysTogether;
        return GlassCard(
          gradient: ThemeConstants.loveGradient,
          child: Column(
            children: [
              const AnimatedHeart(size: 40),
              const SizedBox(height: 12),
              Text(
                '$days',
                style: const TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                days == 1 ? 'Day Together' : 'Days Together',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.9),
                  letterSpacing: 1,
                ),
              ),
              if (couple.couple?.anniversaryDate != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Since ${DateFormatUtils.formatDisplay(DateTime.parse(couple.couple!.anniversaryDate!))}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _ActionData(Icons.emoji_events_outlined, 'Milestones', '/milestones'),
      _ActionData(Icons.photo_album_outlined, 'Memories', '/memories'),
      _ActionData(Icons.calendar_month_outlined, 'Calendar', '/calendar'),
      _ActionData(Icons.emoji_events_outlined, 'Goals', '/goals'),
      _ActionData(Icons.games_outlined, 'Games', '/games'),
      _ActionData(Icons.card_giftcard_outlined, 'Wishlist', '/wishlist'),
      _ActionData(Icons.notes_outlined, 'Love Notes', '/love-notes'),
      _ActionData(Icons.check_circle_outline, 'Check-In', '/checkin'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Quick Actions'),
        const SizedBox(height: 8),
        // Partner's Feeling card (always visible)
        Consumer<CheckInProvider>(
          builder: (_, checkin, __) {
            final partnerMood = checkin.partnerTodayMood;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassCard(
                onTap: () => Navigator.pushNamed(context, '/checkin'),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: partnerMood != null
                            ? const Color(0xFFE91E63).withOpacity(0.15)
                            : Colors.grey.withOpacity(0.1),
                      ),
                      child: Icon(
                        partnerMood != null ? Icons.favorite : Icons.favorite_border,
                        color: partnerMood != null ? const Color(0xFFE91E63) : Colors.grey,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            partnerMood != null
                                ? 'Partner feels: $partnerMood'
                                : 'Partner feeling',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          Text(
                            partnerMood != null
                                ? 'Tap to see details'
                                : 'No mood shared yet',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    if (partnerMood != null)
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 0.85,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: actions.length,
          itemBuilder: (_, i) => GestureDetector(
            onTap: () => Navigator.pushNamed(context, actions[i].route),
            child: GlassCard(
              padding: const EdgeInsets.all(8),
              borderRadius: 16,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(actions[i].icon, color: ThemeConstants.primaryColor, size: 26),
                  const SizedBox(height: 4),
                  Text(
                    actions[i].label,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTodayMood(BuildContext context) {
    return Consumer<CheckInProvider>(
      builder: (_, checkin, __) {
        final mood = checkin.todayMood;
        return GlassCard(
          onTap: () => Navigator.pushNamed(context, '/checkin'),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ThemeConstants.primaryColor.withOpacity(0.1),
                ),
                child: Icon(
                  mood != null ? Icons.favorite : Icons.favorite_border,
                  color: ThemeConstants.primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mood != null ? "Today's Mood: $mood" : 'How are you feeling?',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (checkin.partnerTodayMood != null && mood != null)
                      Text(
                        'Partner: ${checkin.partnerTodayMood}',
                        style: TextStyle(fontSize: 12, color: ThemeConstants.primaryColor),
                      ),
                    Text(
                      mood != null
                          ? 'Tap to update'
                          : 'Daily check-in with your partner',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Theme.of(context).brightness == Brightness.dark ? Colors.white38 : Colors.black38),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUpcomingSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Relationship Goals'),
        Consumer<CoupleProvider>(
          builder: (_, couple, __) {
            if (couple.milestones.isEmpty) {
              return GlassCard(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Add your first milestone!',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
              );
            }
            return Column(
              children: couple.milestones.take(3).map((m) => ListTile(
                    leading: Icon(Icons.emoji_events, color: ThemeConstants.primaryColor),
                    title: Text(m.title),
                    subtitle: Text(DateFormatUtils.formatDisplay(DateTime.parse(m.date))),
                  )).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _ActionData {
  final IconData icon;
  final String label;
  final String route;
  _ActionData(this.icon, this.label, this.route);
}
