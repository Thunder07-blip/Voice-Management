import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import 'package:drift/drift.dart' as drift;
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/local/database.dart';
import 'app_providers.dart';

class AuthState {
  final Member? currentMember;
  final Role? currentRole;
  final List<String> permissions; // Pre-loaded list of permission keys

  final bool isAdminMode;
  final Role? adminRole; // The role they used to authenticate admin mode

  const AuthState({
    this.currentMember,
    this.currentRole,
    this.permissions = const [],
    this.isAdminMode = false,
    this.adminRole,
  });

  AuthState copyWith({
    Member? currentMember,
    Role? currentRole,
    List<String>? permissions,
    bool? isAdminMode,
    Role? adminRole,
  }) {
    return AuthState(
      currentMember: currentMember ?? this.currentMember,
      currentRole: currentRole ?? this.currentRole,
      permissions: permissions ?? this.permissions,
      isAdminMode: isAdminMode ?? this.isAdminMode,
      adminRole: adminRole ?? this.adminRole,
    );
  }

  /// Global helper to check permissions.
  /// If the current member has the 'Project Manager' role, they have full system access.
  /// Otherwise, they must have the specific permission key.
  bool hasPermission(String key) {
    if (currentRole?.name == 'Project Manager') return true;
    return permissions.contains(key);
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    ref.listen(membersStreamProvider, (_, __) => unawaited(refreshCurrentSession()));
    ref.listen(rolesStreamProvider, (_, __) => unawaited(refreshCurrentSession()));
    return const AuthState();
  }

  // Predefined Administrator PINs
  static const String _pmCode = 'PM_CODE';
  static const String _ocCode = 'OC_CODE';
  static const String _aocCode = 'AOC_CODE';

  /// Authenticate a daily member session
  Future<bool> loginMember(String memberId, String pin) async {
    final db = ref.read(databaseProvider);
    
    // Find member by ID
    final normalizedMemberId = memberId.trim().toUpperCase();
    final members = await db.select(db.membersTable).get();
    final member = members.firstWhereOrNull((m) => m.memberId == normalizedMemberId);

    if (member == null) return false;
    
    // In a real app, hash the PIN and compare. For MVP, direct comparison.
    if (member.pinHash != pin) return false;

    // Load Role
    Role? role;
    if (member.roleId != null) {
      final roles = await db.select(db.rolesTable).get();
      role = roles.firstWhereOrNull((r) => r.id == member.roleId);
    }

    // Load Permissions
    List<String> perms = [];
    if (role != null) {
      final rolePerms = await (db.select(db.rolePermissionsTable)..where((t) => t.roleId.equals(role!.id))).get();
      final allPerms = await db.select(db.permissionsTable).get();
      
      for (final rp in rolePerms) {
        final p = allPerms.firstWhereOrNull((p) => p.id == rp.permissionId);
        if (p != null) {
          perms.add(p.permissionKey);
        }
      }
    }

    state = AuthState(
      currentMember: member,
      currentRole: role,
      permissions: perms,
      isAdminMode: false,
    );

    // Save to persistent storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('memberId', normalizedMemberId);
    await prefs.setString('memberPin', pin);

    return true;
  }

  /// Try to auto-login from stored credentials
  Future<bool> tryAutoLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final memberId = prefs.getString('memberId');
      final memberPin = prefs.getString('memberPin');

      if (memberId != null && memberPin != null) {
        return await loginMember(memberId, memberPin);
      }
    } catch (e) {
      // Ignore storage errors on init
    }
    return false;
  }

  /// Re-evaluate the current session after Realtime updates the local role,
  /// permission, member, or PIN data. This makes permission changes from one
  /// coordinator take effect on every open phone without requiring logout.
  Future<void> refreshCurrentSession() async {
    final current = state.currentMember;
    if (current == null || current.memberId == null || current.pinHash == null) return;
    await loginMember(current.memberId!, current.pinHash!);
  }

  /// Enable Administrator Mode
  /// Requires checking BOTH the logged-in member's assigned role AND the provided PIN
  bool enableAdminMode(String pin) {
    final roleName = state.currentRole?.name;
    
    if (roleName == null) return false;

    bool isAuthorized = false;

    if (roleName == 'Project Manager' && pin == _pmCode) {
      isAuthorized = true;
    } else if (roleName == 'Overall Coordinator' && pin == _ocCode) {
      isAuthorized = true;
    } else if (roleName == 'Assistant Overall Coordinator' && pin == _aocCode) {
      isAuthorized = true;
    }

    if (isAuthorized) {
      state = state.copyWith(
        isAdminMode: true,
        adminRole: state.currentRole,
      );
      return true;
    }

    return false;
  }

  void exitAdminMode() {
    state = state.copyWith(isAdminMode: false, adminRole: null);
  }

  void logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('memberId');
    await prefs.remove('memberPin');
    state = const AuthState();
  }

  /// Change the PIN of the currently logged-in member
  Future<bool> changePin(String currentPin, String newPin) async {
    final member = state.currentMember;
    if (member == null) return false;
    
    if (member.pinHash != currentPin || !RegExp(r'^\d{4}$').hasMatch(newPin)) return false;

    final db = ref.read(databaseProvider);
    
    // Create updated member object
    final updatedMember = member.copyWith(
      pinHash: drift.Value(newPin),
      updatedAt: DateTime.now(),
    );

    // Update PIN in DB
    await db.update(db.membersTable).replace(updatedMember);

    await ref.read(syncEngineProvider).queueOperation(
      table: 'members',
      operation: 'update',
      data: {
        'id': updatedMember.id,
        'memberId': updatedMember.memberId,
        'pinHash': updatedMember.pinHash,
        'name': updatedMember.name,
        'profilePhoto': updatedMember.profilePhoto,
        'college': updatedMember.college,
        'year': updatedMember.year,
        'memberType': updatedMember.memberType,
        'currentStatus': updatedMember.currentStatus,
        'groupId': updatedMember.groupId,
        'roleId': updatedMember.roleId,
        'createdAt': updatedMember.createdAt.toIso8601String(),
        'updatedAt': updatedMember.updatedAt.toIso8601String(),
        'deletedAt': updatedMember.deletedAt?.toIso8601String(),
      },
    );

    // Update in-memory state
    state = state.copyWith(currentMember: updatedMember);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('memberPin', newPin);

    return true;
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
