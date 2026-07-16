import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/app_state.dart';
import 'providers/app_state_provider.dart';
import 'services/auth_service.dart';
import 'services/item_service.dart';
import 'services/qr_service.dart';
import 'services/borrow_request_service.dart';
import 'screens/auth/auth_gate.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AuthService authService;
  ItemService itemService;
  BorrowRequestService borrowRequestService;

  try {
    // Attempt to initialize Firebase using platform options (overwritten by flutterfire configure)
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    authService = FirebaseAuthService();
    itemService = FirestoreItemService();
    borrowRequestService = FirestoreBorrowRequestService();
    debugPrint('Emanetly: Firebase initialized successfully with Firestore support.');
  } catch (e) {
    // Fallback if firebase options are not configured yet or throws UnimplementedError
    authService = MockAuthService();
    itemService = MockItemService();
    borrowRequestService = MockBorrowRequestService();
    debugPrint('Emanetly: Firebase config fallback to Mock. Notice: $e');
  }

  // Instantiate services
  final qrService = MockQrService();

  // Instantiate application state controller
  final appState = AppState(
    authService: authService,
    itemService: itemService,
    qrService: qrService,
    borrowRequestService: borrowRequestService,
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
