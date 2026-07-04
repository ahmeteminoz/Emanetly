import 'package:flutter_test/flutter_test.dart';
import 'package:kampus_emanet/main.dart';
import 'package:kampus_emanet/providers/app_state.dart';
import 'package:kampus_emanet/providers/app_state_provider.dart';
import 'package:kampus_emanet/services/auth_service.dart';
import 'package:kampus_emanet/services/item_service.dart';
import 'package:kampus_emanet/services/qr_service.dart';

void main() {
  testWidgets('KampusEmanet smoke test - App renders listings correctly', (WidgetTester tester) async {
    // Setup mock services and application state
    final authService = MockAuthService();
    final itemService = MockItemService();
    final qrService = MockQrService();
    final appState = AppState(
      authService: authService,
      itemService: itemService,
      qrService: qrService,
    );

    // Build the app widget tree
    await tester.pumpWidget(
      AppStateProvider(
        notifier: appState,
        child: const KampusEmanetApp(),
      ),
    );

    // Verify main app title is visible
    expect(find.text('Kampüs Emanet'), findsOneWidget);

    // Verify some mock items from MockItemService are loaded and visible
    await tester.pumpAndSettle(); // let futures settle
    expect(find.text('USB-C Hızlı Şarj Cihazı (65W)'), findsOneWidget);
    expect(find.text('Büyük Boy Siyah Şemsiye'), findsOneWidget);
  });
}
