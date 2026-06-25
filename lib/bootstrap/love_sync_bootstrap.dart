import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../firebase_options.dart';
import '../providers/auth_provider.dart';
import '../providers/calendar_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/checkin_provider.dart';
import '../providers/couple_provider.dart';
import '../providers/games_provider.dart';
import '../providers/goals_provider.dart';
import '../providers/love_notes_provider.dart';
import '../providers/memories_provider.dart';
import '../providers/statistics_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/wishlist_provider.dart';
import '../core/services/database_service.dart';
import '../core/services/hive_service.dart';
import '../core/services/notification_service.dart';
import '../core/services/storage_service.dart';

class LoveSyncBootstrap {
  static Future<void> run() async {
    WidgetsFlutterBinding.ensureInitialized();

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (_) {
      // Firebase stays optional so the app can still boot offline.
    }

    await StorageService.init();

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => CoupleProvider()),
          ChangeNotifierProvider(create: (_) => ChatProvider()),
          ChangeNotifierProvider(create: (_) => CalendarProvider()),
          ChangeNotifierProvider(create: (_) => MemoriesProvider()),
          ChangeNotifierProvider(create: (_) => GoalsProvider()),
          ChangeNotifierProvider(create: (_) => GamesProvider()),
          ChangeNotifierProvider(create: (_) => WishlistProvider()),
          ChangeNotifierProvider(create: (_) => LoveNotesProvider()),
          ChangeNotifierProvider(create: (_) => CheckInProvider()),
          ChangeNotifierProvider(create: (_) => StatisticsProvider()),
        ],
        child: const LoveSyncApp(),
      ),
    );

    await Future.wait<dynamic>([
      DatabaseService.ensureInitialized().timeout(const Duration(seconds: 10)),
      HiveService.init().timeout(const Duration(seconds: 5)),
      NotificationService.initialize().timeout(const Duration(seconds: 5)),
    ]).catchError((_) {});
  }
}
