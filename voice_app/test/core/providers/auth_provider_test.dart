import 'package:flutter_test/flutter_test.dart';
import 'package:voice_app/core/providers/auth_provider.dart';
import 'package:voice_app/data/local/database.dart';

void main() {
  group('RBAC Tests - AuthState.hasPermission()', () {
    test('Project Manager has universal access', () {
      final pmRole = Role(
        id: 'r1',
        name: 'Project Manager',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final state = AuthState(currentRole: pmRole, permissions: []);
      
      // Project manager automatically bypasses permission checks
      expect(state.hasPermission('delete_member'), isTrue);
      expect(state.hasPermission('approve_leave'), isTrue);
      expect(state.hasPermission('random_nonexistent_permission'), isTrue);
    });

    test('Normal Member checks explicit permissions', () {
      final memberRole = Role(
        id: 'r2',
        name: 'Member',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Give them just one permission explicitly
      final state = AuthState(
        currentRole: memberRole,
        permissions: ['view_profile', 'update_meals'],
      );

      expect(state.hasPermission('view_profile'), isTrue);
      expect(state.hasPermission('update_meals'), isTrue);
      
      // Should NOT have access to these
      expect(state.hasPermission('delete_member'), isFalse);
      expect(state.hasPermission('approve_leave'), isFalse);
    });

    test('Coordinator checks explicit permissions', () {
      final ocRole = Role(
        id: 'r3',
        name: 'Overall Coordinator',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final state = AuthState(
        currentRole: ocRole,
        permissions: ['approve_leave', 'assign_tasks'],
      );

      expect(state.hasPermission('approve_leave'), isTrue);
      expect(state.hasPermission('assign_tasks'), isTrue);
      expect(state.hasPermission('change_system_permissions'), isFalse);
    });

    test('Kitchen Incharge checks explicit permissions', () {
      final kitchenRole = Role(
        id: 'r4',
        name: 'Kitchen Incharge',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final state = AuthState(
        currentRole: kitchenRole,
        permissions: ['view_meal_planning'],
      );

      expect(state.hasPermission('view_meal_planning'), isTrue);
      expect(state.hasPermission('edit_members'), isFalse);
      expect(state.hasPermission('change_roles'), isFalse);
    });
  });
}
