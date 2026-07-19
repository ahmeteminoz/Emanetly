import 'package:flutter_test/flutter_test.dart';
import 'package:emanetly/main.dart';
import 'package:emanetly/providers/app_state.dart';
import 'package:emanetly/providers/app_state_provider.dart';
import 'package:emanetly/services/auth_service.dart';
import 'package:emanetly/services/item_service.dart';
import 'package:emanetly/services/qr_service.dart';
import 'package:emanetly/services/borrow_request_service.dart';
import 'package:emanetly/services/chat_message_service.dart';
import 'package:emanetly/services/storage_service.dart';

void main() {
  testWidgets('Emanetly smoke test - App renders listings correctly', (WidgetTester tester) async {
    // Setup mock services and application state
    final authService = MockAuthService();
    final itemService = MockItemService();
    final qrService = MockQrService();
    final borrowRequestService = MockBorrowRequestService();
    final chatMessageService = MockChatMessageService();
    final storageService = MockStorageService();
    final appState = AppState(
      authService: authService,
      itemService: itemService,
      qrService: qrService,
      borrowRequestService: borrowRequestService,
      chatMessageService: chatMessageService,
      storageService: storageService,
    );

    // Build the app widget tree
    await tester.pumpWidget(
      AppStateProvider(
        notifier: appState,
        child: const EmanetlyApp(),
      ),
    );

    // Verify main app title is visible
    expect(find.text('Emanetly'), findsOneWidget);

    // Verify some mock items from MockItemService are loaded and visible
    await tester.pumpAndSettle(); // let futures settle
    expect(find.text('USB-C Hızlı Şarj Cihazı (65W)'), findsOneWidget);
    expect(find.text('Büyük Boy Siyah Şemsiye'), findsOneWidget);
  });
}
