import 'package:flutter/material.dart';
import 'providers/app_state.dart';
import 'providers/app_state_provider.dart';
import 'services/auth_service.dart';
import 'services/item_service.dart';
import 'services/qr_service.dart';
import 'screens/main_layout.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Instantiate services
  final authService = MockAuthService();
  final itemService = MockItemService();
  final qrService = MockQrService();

  // Instantiate application state controller
  final appState = AppState(
    authService: authService,
    itemService: itemService,
    qrService: qrService,
  );

  runApp(
    AppStateProvider(
      notifier: appState,
      child: const KampusEmanetApp(),
    ),
  );
}

class KampusEmanetApp extends StatelessWidget {
  const KampusEmanetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KampüsEmanet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        
        // Define a beautiful campus-friendly color palette
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A8A), // Indigo
          secondary: const Color(0xFF0D9488), // Teal
          brightness: Brightness.light,
        ),

        // Customize card and button default styles
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 2),
          ),
        ),
      ),
      home: const MainLayout(),
    );
  }
}
