import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/app_state.dart';
import 'providers/app_state_provider.dart';
import 'services/auth_service.dart';
import 'services/item_service.dart';
import 'services/borrow_request_service.dart';
import 'services/chat_message_service.dart';
import 'services/storage_service.dart';
import 'services/navigation_service.dart';
import 'screens/auth/auth_gate.dart';
import 'theme/app_theme.dart';
import 'services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'services/analytics_service.dart';
import 'services/crashlytics_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AuthService authService;
  ItemService itemService;
  BorrowRequestService borrowRequestService;
  ChatMessageService chatMessageService;
  StorageService storageService;
  final crashlyticsService = CrashlyticsService();
  final analyticsService = AnalyticsService();

  try {
    // Attempt to initialize Firebase using platform options
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    try {
      final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('Emanetly: Found initial message in main(): ${initialMessage.data}');
        NotificationService.instance.pendingDeepLink = initialMessage.data;
      }
    } catch (e) {
      debugPrint('Emanetly: Error checking initial message in main(): $e');
    }
    authService = FirebaseAuthService();
    itemService = FirestoreItemService();
    borrowRequestService = FirestoreBorrowRequestService();
    chatMessageService = FirestoreChatMessageService();
    storageService = FirebaseStorageService();
    
    // Initialize global Crashlytics error handlers
    await crashlyticsService.initialize();
    
    debugPrint('Emanetly: Firebase initialized successfully with Firestore, Analytics, and Crashlytics support.');
  } catch (e) {
    // Fallback if firebase options are not configured yet or throws UnimplementedError
    authService = MockAuthService();
    itemService = MockItemService();
    borrowRequestService = MockBorrowRequestService();
    chatMessageService = MockChatMessageService();
    storageService = MockStorageService();
    debugPrint('Emanetly: Firebase config fallback to Mock. Notice: $e');
  }

  // Instantiate application state controller
  final appState = AppState(
    authService: authService,
    itemService: itemService,
    borrowRequestService: borrowRequestService,
    chatMessageService: chatMessageService,
    storageService: storageService,
    analyticsService: analyticsService,
    crashlyticsService: crashlyticsService,
  );

  runApp(
    AppStateProvider(
      notifier: appState,
      child: const EmanetlyApp(),
    ),
  );
}

class EmanetlyApp extends StatelessWidget {
  const EmanetlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateProvider.of(context);

    return MaterialApp(
      title: 'Emanetly',
      navigatorKey: NavigationService.navigatorKey,
      debugShowCheckedModeBanner: false,
      themeMode: appState.themeMode,
      theme: AppTheme.buildTheme(
        isDark: false,
        paletteIndex: appState.selectedPaletteIndex,
      ),
      darkTheme: AppTheme.buildTheme(
        isDark: true,
        paletteIndex: appState.selectedPaletteIndex,
      ),
      home: const AuthGate(),
    );
  }
}
