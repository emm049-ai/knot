import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Firebase temporarily disabled for web compatibility
// import '../firebase_mobile.dart' if (dart.library.html) '../firebase_web.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // Initialize local notifications (works on all platforms)
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Firebase messaging temporarily disabled for web compatibility
    // Will be re-enabled for mobile builds
    // if (!kIsWeb) {
    //   try {
    //     final messaging = FirebaseMessaging.instance;
    //     await messaging.requestPermission(
    //       alert: true,
    //       badge: true,
    //       sound: true,
    //     );
    //     messaging.onMessage.listen((message) {
    //       _handleForegroundMessage(message);
    //     });
    //   } catch (e) {
    //     print('Firebase messaging initialization skipped: $e');
    //   }
    // }
  }

  static void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap
  }

  // Firebase message handling temporarily disabled
  // static Future<void> _handleForegroundMessage(RemoteMessage message) async {
  //   ...
  // }

  static Future<void> showLocalNotification(
    String title,
    String body, {
    Map<String, dynamic>? data,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'knot_channel',
      'Knot Notifications',
      channelDescription: 'Notifications for Knot app',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      title,
      body,
      details,
    );
  }
}
