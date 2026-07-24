import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:voice_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('End-to-End Login and Dashboard Load Flow', (WidgetTester tester) async {
    app.main();
    // Wait for the app to initialize (Supabase, Riverpod, Drift)
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Verify we are on the login screen
    expect(find.text('Enter PIN'), findsOneWidget);

    // Enter VO-001 (Admin)
    await tester.enterText(find.byType(TextField).first, 'VO-001');
    await tester.enterText(find.byType(TextField).last, '1234');

    // Tap Login
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Wait for dashboard to load
    await tester.pumpAndSettle();

    // Verify Dashboard features
    expect(find.text('Dashboard'), findsWidgets);
    
    // We should see KPI cards like 'Members', 'Tasks'
    expect(find.text('Members'), findsWidgets);
    expect(find.text('Tasks'), findsWidgets);
  });
}
