import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voice_app/presentation/screens/kitchen/meal_planning_screen.dart';
import 'package:voice_app/core/providers/auth_provider.dart';
import 'package:voice_app/core/providers/app_providers.dart';
import 'package:voice_app/data/local/database.dart';
import 'package:intl/intl.dart';

class MockAuthNotifier extends AuthNotifier {
  final AuthState mockState;
  MockAuthNotifier(this.mockState);

  @override
  AuthState build() => mockState;
}

void main() {
  testWidgets('MealPlanningScreen shows KitchenView with correct breakdown for PM', (WidgetTester tester) async {
    final pmRole = Role(
      id: 'r1',
      name: 'Project Manager',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final pmMember = Member(
      id: 'm1',
      memberId: 'VO-001',
      name: 'Test PM',
      currentStatus: 'Present',
      memberType: 'working',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final otherMember = Member(
      id: 'm2',
      memberId: 'VO-002',
      name: 'Test Member',
      currentStatus: 'Present',
      memberType: 'student',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final awayMember = Member(
      id: 'm3',
      memberId: 'VO-003',
      name: 'Away Member',
      currentStatus: 'Away',
      memberType: 'student',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // m2 is not eating lunch
    final m2Plan = MealPlan(
      id: 'p1',
      memberId: 'm2',
      date: todayStr,
      breakfast: true,
      lunch: false,
      dinner: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final mockAuthState = AuthState(
      currentMember: pmMember, 
      currentRole: pmRole,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(() => MockAuthNotifier(mockAuthState)),
          membersStreamProvider.overrideWith((ref) => Stream.value([pmMember, otherMember, awayMember])),
          mealPlansStreamProvider.overrideWith((ref) => Stream.value([m2Plan])),
          leavesStreamProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: const MaterialApp(
          home: MealPlanningScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify it's the Kitchen View
    expect(find.text('Kitchen Analytics'), findsOneWidget);

    // Total members: 3
    // On Leave: 1
    // Not eating: 1 (lunch)
    // Required Lunch = 2 (Present) - 1 (Not Eating) = 1
    
    // We should see "Total Members" -> 3
    expect(find.text('3'), findsWidgets);
    
    // We should see "On Leave" -> 1
    expect(find.text('1'), findsWidgets);

    // We should see "Required: 1" for lunch
    expect(find.text('Required: 1'), findsWidgets); // For lunch
    // For breakfast and dinner, it should be 2
    expect(find.text('Required: 2'), findsWidgets); 
  });

  testWidgets('MealPlanningScreen MemberView locks editing if on leave', (WidgetTester tester) async {
    final member = Member(
      id: 'm1',
      memberId: 'VO-001',
      name: 'Test Member',
      currentStatus: 'Away',
      memberType: 'student',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final activeLeave = LeaveRequest(
      id: 'L1',
      memberId: 'm1',
      startDate: DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      endDate: DateTime.now().add(const Duration(days: 1)).toIso8601String(),
      status: 'active',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final mockAuthState = AuthState(
      currentMember: member, 
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(() => MockAuthNotifier(mockAuthState)),
          membersStreamProvider.overrideWith((ref) => Stream.value([member])),
          mealPlansStreamProvider.overrideWith((ref) => Stream.value([])),
          leavesStreamProvider.overrideWith((ref) => Stream.value([activeLeave])),
        ],
        child: const MaterialApp(
          home: MealPlanningScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify it's Member View
    expect(find.text('My Meals'), findsOneWidget);

    // Verify Warning Banner
    expect(find.text('You are on leave for this date. Meals are automatically marked as Not Eating.'), findsOneWidget);
  });
}
