import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // Request permission for iOS/Web
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Initialize local notifications for foreground display
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);
    await _localNotificationsPlugin.initialize(initSettings);

    // Foreground message handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        _showLocalNotification(message.notification!);
      }
    });
  }

  static Future<void> _showLocalNotification(RemoteNotification notification) async {
    const androidDetails = AndroidNotificationDetails(
      'lovesync_channel_id',
      'LoveSync Notifications',
      channelDescription: 'Notifications for LoveSync messages and updates',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const platformDetails = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _localNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      platformDetails,
    );
  }

  static Future<String?> getToken() async {
    return await _messaging.getToken();
  }
}
