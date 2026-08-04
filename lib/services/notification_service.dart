import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../screens/request_chat_screen.dart';
import 'navigation_service.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  factory NotificationService() => instance;
  NotificationService._internal();

  FirebaseMessaging? _fcm;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // Tracks the ID of the chat room the user is currently viewing to silence in-app pushes
  String? activeChatRequestId;

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

      // 1. Request Permission (Non-blocking)
      try {
        await fcm.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
      } catch (_) {}

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
        // Skip showing local push notification if user is already viewing this chat
        final payloadRequestId = message.data["requestId"];
        if (payloadRequestId != null && payloadRequestId == activeChatRequestId) {
          return;
        }
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
        if (response.payload != null) {
          try {
            final Map<String, dynamic> data = jsonDecode(response.payload!);
            _handleNotificationClick(data);
          } catch (_) {}
        }
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
      payload: jsonEncode(message.data),
    );
  }

  Map<String, dynamic>? pendingDeepLink;

  void checkPendingDeepLink() {
    if (pendingDeepLink != null) {
      final data = pendingDeepLink!;
      pendingDeepLink = null;
      _handleNotificationClick(data);
    }
  }

  void _handleNotificationClick(Map<String, dynamic> data) {
    print('Emanetly: _handleNotificationClick called with data: $data');
    final route = data['route'];
    final requestId = data['requestId'];
    if (route == 'request_chat' && requestId != null && requestId is String) {
      if (NavigationService.navigatorKey.currentState == null) {
        print('Emanetly: navigatorKey.currentState is null. Storing pendingDeepLink.');
        pendingDeepLink = data;
      } else {
        print('Emanetly: navigatorKey.currentState is ready. Navigating to RequestChatScreen.');
        NavigationService.navigateTo(RequestChatScreen(requestId: requestId));
      }
    } else {
      print('Emanetly: Ignored click handler due to missing or mismatched payload: route=$route, requestId=$requestId');
    }
  }

  void dispose() {
    _tokenRefreshSubscription?.cancel();
    _onMessageSubscription?.cancel();
    _onMessageOpenedAppSubscription?.cancel();
  }
}
