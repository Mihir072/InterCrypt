// Flutter widget tests for IntelCrypt
//
// These tests verify basic app functionality and UI rendering.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/main.dart';

void main() {
  testWidgets('IntelCryptApp renders without errors', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    // The app requires ProviderScope for Riverpod to work
    await tester.pumpWidget(const ProviderScope(child: IntelCryptApp()));

    // Allow time for initial navigation and routing
    await tester.pumpAndSettle();

    // Verify that the app loads without crashing
    expect(find.byType(IntelCryptApp), findsOneWidget);
  });
}
