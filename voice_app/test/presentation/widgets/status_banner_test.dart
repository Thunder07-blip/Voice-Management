import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voice_app/presentation/screens/dashboard/widgets/status_banner.dart';
import 'package:voice_app/core/providers/auth_provider.dart';
import 'package:voice_app/core/providers/app_providers.dart';
import 'package:voice_app/data/local/database.dart';

class MockAuthNotifier extends AuthNotifier {
  final AuthState mockState;
  MockAuthNotifier(this.mockState);

  @override
  AuthState build() => mockState;
}

void main() {
  testWidgets('StatusBanner shows Present when member is present', (WidgetTester tester) async {
    final member = Member(
      id: 'm1',
      memberId: 'VO-001',
      name: 'Test Member',
      currentStatus: 'Present',
      memberType: 'working',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final mockAuthState = AuthState(currentMember: member);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(() => MockAuthNotifier(mockAuthState)),
          membersStreamProvider.overrideWith((ref) => Stream.value([member])),
          leavesStreamProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: StatusBanner(),
          ),
        ),
      ),
    );

    // Wait for stream to emit
    await tester.pumpAndSettle();

    expect(find.text('Status: Present'), findsOneWidget);
    expect(find.text('Status: Away on Leave'), findsNothing);
  });

  testWidgets('StatusBanner shows Away with buttons when member is on leave', (WidgetTester tester) async {
    final member = Member(
      id: 'm1',
      memberId: 'VO-001',
      name: 'Test Member',
      currentStatus: 'Away',
      memberType: 'working',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final activeLeave = LeaveRequest(
      id: 'L1',
      memberId: 'm1',
      startDate: DateTime.now().toIso8601String(),
      endDate: DateTime.now().add(const Duration(days: 3)).toIso8601String(),
      status: 'active',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final mockAuthState = AuthState(currentMember: member);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(() => MockAuthNotifier(mockAuthState)),
          membersStreamProvider.overrideWith((ref) => Stream.value([member])),
          leavesStreamProvider.overrideWith((ref) => Stream.value([activeLeave])),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: StatusBanner(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Status: Present'), findsNothing);
    expect(find.text('Status: Away on Leave'), findsOneWidget);
    
    // Check buttons
    expect(find.text('Update Return'), findsOneWidget);
    expect(find.text('I Have Returned'), findsOneWidget);
  });
}
