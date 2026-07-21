import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  factory NotificationService() => instance;
  NotificationService._internal();

  FirebaseMessaging? _fcm;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _onMessageSubscription;
  StreamSubscription<RemoteMessage>? _onMessageOpenedAppSubscription;

  Future<void> initialize({
    required Function(String token) onTokenReceived,
  }) async {
    if (Firebase.apps.isEmpty) {
      return;
    }

    try {
      _fcm ??= FirebaseMessaging.instance;
      final fcm = _fcm!;

      // 1. Request Permission
      final settings = await fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // 2. Initialize Local Notifications for Foreground
        await _initLocalNotifications();

        // 3. Get FCM Token
        try {
          final token = await fcm.getToken();
          if (token != null) {
            onTokenReceived(token);
          }
        } catch (_) {}

        // 4. Token Refresh Listener
        _tokenRefreshSubscription = fcm.onTokenRefresh.listen((newToken) {
          onTokenReceived(newToken);
        });

        // 5. Foreground Message Listener
        _onMessageSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          _showLocalNotification(message);
        });

        // 6. Background Message Clicked Listener
        _onMessageOpenedAppSubscription = FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          _handleNotificationClick(message.data);
        });

        // 7. Initial Message Check (App opened from terminated state)
        final initialMessage = await fcm.getInitialMessage();
        if (initialMessage != null) {
          _handleNotificationClick(initialMessage.data);
        }
      }
    } catch (_) {}
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle local notification tap
      },
    );
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'emanetly_channel',
      'Emanetly Bildirimleri',
      channelDescription: 'Emanetly kampüs bildirimleri',
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
      payload: message.data['type'],
    );
  }

  void _handleNotificationClick(Map<String, dynamic> data) {
    // NavigationService routing can be triggered based on payload
  }

  void dispose() {
    _tokenRefreshSubscription?.cancel();
    _onMessageSubscription?.cancel();
    _onMessageOpenedAppSubscription?.cancel();
  }
}
