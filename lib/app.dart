import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/widgets/responsive_shell.dart';
import 'models/memory_model.dart';
import 'providers/theme_provider.dart';
import 'screens/auth/local_account_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/calendar/calendar_screen.dart';
import 'screens/chat/chat_screen.dart';
import 'screens/checkin/checkin_screen.dart';
import 'screens/games/games_screen.dart';
import 'screens/goals/goals_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/love_notes/love_notes_screen.dart';
import 'screens/love_notes/note_editor_screen.dart';
import 'screens/memories/memories_screen.dart';
import 'screens/memories/memory_detail_screen.dart';
import 'screens/milestones/milestones_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/profile/partner_linking_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/statistics/statistics_screen.dart';
import 'screens/wishlist/wishlist_screen.dart';

class LoveSyncApp extends StatelessWidget {
  const LoveSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (_, themeProvider, __) {
        return MaterialApp(
          title: 'LoveSync',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.theme,
          initialRoute: '/',
          builder: (context, child) {
            final body = child ?? const SizedBox.shrink();
            return ColoredBox(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: SafeArea(
                top: false,
                bottom: false,
                child: ResponsiveShell(
                  maxContentWidth: 1280,
                  padding: EdgeInsets.zero,
                  child: body,
                ),
              ),
            );
          },
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case '/':
                return _buildPageRoute(const SplashScreen());
              case '/onboarding':
                return _buildPageRoute(const OnboardingScreen());
              case '/auth':
                return _buildPageRoute(const LoginScreen());
              case '/register':
                return _buildPageRoute(const RegisterScreen());
              case '/local-account':
                return _buildPageRoute(const LocalAccountScreen());
              case '/home':
                return _buildPageRoute(const HomeScreen());
              case '/chat':
                return _buildPageRoute(const ChatRoomScreen());
              case '/chat-room':
                return _buildPageRoute(const ChatRoomScreen());
              case '/calendar':
                return _buildPageRoute(const CalendarScreen());
              case '/memories':
                return _buildPageRoute(const MemoriesScreen());
              case '/memory-detail':
                return _buildPageRoute(
                  MemoryDetailScreen(memory: settings.arguments as MemoryModel),
                );
              case '/goals':
                return _buildPageRoute(const GoalsScreen());
              case '/games':
                return _buildPageRoute(const GamesScreen());
              case '/truth-or-dare':
                return _buildPageRoute(const TruthOrDareScreen());
              case '/love-quiz':
                return _buildPageRoute(const LoveQuizScreen());
              case '/daily-challenge':
                return _buildPageRoute(const DailyChallengeScreen());
              case '/would-you-rather':
                return _buildPageRoute(const WouldYouRatherScreen());
              case '/wishlist':
                return _buildPageRoute(const WishlistScreen());
              case '/love-notes':
                return _buildPageRoute(const LoveNotesScreen());
              case '/note-editor':
                return _buildPageRoute(const NoteEditorScreen());
              case '/checkin':
                return _buildPageRoute(const CheckInScreen());
              case '/profile':
                return _buildPageRoute(const ProfileScreen());
              case '/partner-linking':
                return _buildPageRoute(const PartnerLinkingScreen());
              case '/statistics':
                return _buildPageRoute(const StatisticsScreen());
              case '/milestones':
                return _buildPageRoute(const MilestonesScreen());
              default:
                return _buildPageRoute(const SplashScreen());
            }
          },
        );
      },
    );
  }

  PageRouteBuilder _buildPageRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) {
        return FadeTransition(opacity: anim, child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}
