import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../screens/request_chat_screen.dart';
import 'navigation_service.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  factory NotificationService() => instance;
  NotificationService._internal();

  FirebaseMessaging? _fcm;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Kullanıcı hangi chat ekranındaysa push sessize alınır
  String? activeChatRequestId;

  /// Navigator henüz hazır değilse deep-link burada bekler
  Map<String, dynamic>? pendingDeepLink;

  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _onMessageSubscription;
  StreamSubscription<RemoteMessage>? _onMessageOpenedAppSubscription;

  bool _initialized = false;

  Future<void> initialize({
    required Function(String token) onTokenReceived,
  }) async {
    if (Firebase.apps.isEmpty || _initialized) return;
    _initialized = true;

    try {
      _fcm ??= FirebaseMessaging.instance;
      final fcm = _fcm!;

      // 1. İzin İste
      try {
        await fcm.requestPermission(alert: true, badge: true, sound: true);
      } catch (_) {}

      // 2. iOS foreground bildirimlerini göster
      await fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 3. Local Notifications başlat (foreground tap için)
      await _initLocalNotifications();

      // 4. FCM Token al
      try {
        final token = await fcm.getToken();
        if (token != null) onTokenReceived(token);
      } catch (_) {}

      // 5. Token yenileme dinleyicisi
      _tokenRefreshSubscription = fcm.onTokenRefresh.listen(onTokenReceived);

      // 6. FOREGROUND: FCM mesajı gelince local notification göster
      _onMessageSubscription =
          FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final payloadRequestId = message.data['requestId'] as String?;
        // Kullanıcı zaten o chat ekranındaysa gösterme
        if (payloadRequestId != null &&
            payloadRequestId == activeChatRequestId) {
          return;
        }
        _showLocalNotification(message);
      });

      // 7. BACKGROUND: Bildirime tıklanınca (uygulama arka planda)
      _onMessageOpenedAppSubscription =
          FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint(
            'Emanetly NS: onMessageOpenedApp → ${message.data}');
        _handleNotificationClick(message.data);
      });

      // NOT: getInitialMessage (TERMINATED) yalnızca main.dart'ta çağrılır.
      // Buradan çağırmıyoruz — çift çağrıda ikincisi null döner.

    } catch (e) {
      debugPrint('Emanetly NS: initialize error: $e');
    }
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint(
            'Emanetly NS: local notification tapped, payload=${response.payload}');
        if (response.payload != null) {
          try {
            final Map<String, dynamic> data = jsonDecode(response.payload!);
            _handleNotificationClick(data);
          } catch (e) {
            debugPrint('Emanetly NS: payload parse error: $e');
          }
        }
      },
    );

    // Android bildirim kanalını oluştur
    const channel = AndroidNotificationChannel(
      'emanetly_channel',
      'Emanetly Bildirimleri',
      description: 'Emanetly kampüs bildirimleri',
      importance: Importance.max,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    // data-only mesajlar için de başlık/gövde çek
    final title = notification?.title ??
        message.data['title'] as String? ??
        'Emanetly';
    final body =
        notification?.body ?? message.data['body'] as String? ?? '';

    const androidDetails = AndroidNotificationDetails(
      'emanetly_channel',
      'Emanetly Bildirimleri',
      channelDescription: 'Emanetly kampüs bildirimleri',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );
    const iosDetails = DarwinNotificationDetails();
    const details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _localNotifications.show(
      message.hashCode,
      title,
      body,
      details,
      payload: jsonEncode(message.data),
    );
  }

  /// HomeScreen veya AuthGate yüklenince çağrılır.
  /// Eğer navigator hazırlanmadan önce gelen bir deep-link varsa işler.
  void checkPendingDeepLink() {
    if (pendingDeepLink != null) {
      final data = pendingDeepLink!;
      pendingDeepLink = null;
      debugPrint('Emanetly NS: processing pendingDeepLink → $data');
      _handleNotificationClick(data);
    }
  }

  void _handleNotificationClick(Map<String, dynamic> data) {
    debugPrint('Emanetly NS: _handleNotificationClick data=$data');

    final route = data['route'] as String?;
    final requestId = data['requestId'] as String?;

    if (route == 'request_chat' && requestId != null && requestId.isNotEmpty) {
      final navState = NavigationService.navigatorKey.currentState;
      if (navState == null) {
        // Navigator henüz yüklenmedi (terminated start) → kaydet
        debugPrint('Emanetly NS: navigator not ready, storing pendingDeepLink');
        pendingDeepLink = data;
      } else {
        debugPrint(
            'Emanetly NS: navigating to RequestChatScreen($requestId)');
        navState.push(
          MaterialPageRoute(
            builder: (_) => RequestChatScreen(requestId: requestId),
          ),
        );
      }
    } else {
      debugPrint(
          'Emanetly NS: unhandled payload — route=$route, requestId=$requestId');
    }
  }

  void dispose() {
    _tokenRefreshSubscription?.cancel();
    _onMessageSubscription?.cancel();
    _onMessageOpenedAppSubscription?.cancel();
    _initialized = false;
  }
}
