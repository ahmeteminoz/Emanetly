import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'navigation_service.dart';

/// Bildirime tıklanınca yayınlanan event
class NotificationClickEvent {
  final String route;
  final String requestId;
  const NotificationClickEvent({required this.route, required this.requestId});
}

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  factory NotificationService() => instance;
  NotificationService._internal();

  FirebaseMessaging? _fcm;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Reactive click stream — MainLayout veya herhangi bir widget dinleyebilir
  final _clickController =
      StreamController<NotificationClickEvent>.broadcast();
  Stream<NotificationClickEvent> get onNotificationClick =>
      _clickController.stream;

  /// Kullanıcı hangi chat ekranındaysa push sessize alınır
  String? activeChatRequestId;

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
        if (payloadRequestId != null &&
            payloadRequestId == activeChatRequestId) {
          return; // Zaten o chat ekranındayız
        }
        _showLocalNotification(message);
      });

      // 7. BACKGROUND: Bildirime tıklanınca (uygulama arka planda)
      _onMessageOpenedAppSubscription =
          FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('Emanetly NS: onMessageOpenedApp → ${message.data}');
        _emitClickEvent(message.data);
      });

      // 8. TERMINATED: main.dart'ta getInitialMessage ile alındı,
      //    pendingClick set edildi, checkPendingClick() ile işlenecek.

    } catch (e) {
      debugPrint('Emanetly NS: initialize error: $e');
    }
  }

  // Terminated state'ten gelen click — main.dart bunu set eder
  Map<String, dynamic>? _pendingClickData;

  void setPendingClick(Map<String, dynamic> data) {
    _pendingClickData = data;
  }

  /// MainLayout.initState'den çağrılır — navigator hazırsa bekleyen click'i işle
  void checkPendingClick() {
    if (_pendingClickData != null) {
      final data = _pendingClickData!;
      _pendingClickData = null;
      debugPrint('Emanetly NS: processing pendingClick → $data');
      _emitClickEvent(data);
    }
  }

  void _emitClickEvent(Map<String, dynamic> data) {
    debugPrint('Emanetly NS: _emitClickEvent data=$data');
    final route = data['route'] as String?;
    final requestId = data['requestId'] as String?;
    if (route == 'request_chat' && requestId != null && requestId.isNotEmpty) {
      _clickController.add(
        NotificationClickEvent(route: route!, requestId: requestId),
      );
    } else {
      debugPrint(
          'Emanetly NS: unhandled payload — route=$route, requestId=$requestId');
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
            'Emanetly NS: local notification tapped payload=${response.payload}');
        if (response.payload != null) {
          try {
            final Map<String, dynamic> data = jsonDecode(response.payload!);
            _emitClickEvent(data);
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

  void dispose() {
    _tokenRefreshSubscription?.cancel();
    _onMessageSubscription?.cancel();
    _onMessageOpenedAppSubscription?.cancel();
    _initialized = false;
  }
}
