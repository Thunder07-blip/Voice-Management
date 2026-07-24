import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Helper utility for programmatically seeding and wiping Member data in Supabase.
class SupabaseSeedManager {
  static final SupabaseClient _client = Supabase.instance.client;

  /// 1. POST / SEED DATA TO SUPABASE
  static Future<void> postSeedData() async {
    try {
      debugPrint('🌱 Starting Supabase Seeding...');

      // Step A: Insert Roles
      await _client.from('roles').upsert([
        {
          'id': 'role-pm-001',
          'name': 'Project Manager',
          'description': 'Full system access.'
        },
        {
          'id': 'role-oc-001',
          'name': 'Overall Coordinator',
          'description': 'System access.'
        },
        {
          'id': 'role-aoc-001',
          'name': 'Assistant Overall Coordinator',
          'description': 'System access.'
        },
      ]);

      // Step B: Insert Permissions & Role Permissions
      await _client.from('permissions').upsert([
        {
          'id': 'perm-ack-001',
          'permission_key': 'manage_acknowledgements',
          'description': 'Can post new acknowledgements on the board'
        }
      ]);

      await _client.from('role_permissions').upsert([
        {'role_id': 'role-pm-001', 'permission_id': 'perm-ack-001'},
        {'role_id': 'role-oc-001', 'permission_id': 'perm-ack-001'},
        {'role_id': 'role-aoc-001', 'permission_id': 'perm-ack-001'},
      ]);

      // Step C: Insert 10 Members
      final members = [
        {
          'id': 'member-001',
          'member_id': 'VO-001',
          'pin_hash': '1234',
          'name': 'HG Radhapad pankaj pr',
          'member_type': 'working',
          'role_id': 'role-pm-001',
          'current_status': 'Present'
        },
        {
          'id': 'member-002',
          'member_id': 'VO-002',
          'pin_hash': '1234',
          'name': 'Piyush Jagzap',
          'member_type': 'working',
          'role_id': 'role-oc-001',
          'current_status': 'Present'
        },
        {
          'id': 'member-003',
          'member_id': 'VO-003',
          'pin_hash': '1234',
          'name': 'Sajal Patil',
          'member_type': 'working',
          'role_id': 'role-aoc-001',
          'current_status': 'Present'
        },
        {
          'id': 'member-004',
          'member_id': 'VO-004',
          'pin_hash': '1234',
          'name': 'Soham Dode',
          'member_type': 'working',
          'role_id': null,
          'current_status': 'Present'
        },
        {
          'id': 'member-005',
          'member_id': 'VO-005',
          'pin_hash': '1234',
          'name': 'Sushant Nikaju',
          'member_type': 'working',
          'role_id': null,
          'current_status': 'Present'
        },
        {
          'id': 'member-006',
          'member_id': 'VO-006',
          'pin_hash': '1234',
          'name': 'Pratik Gadade',
          'member_type': 'working',
          'role_id': null,
          'current_status': 'Present'
        },
        {
          'id': 'member-007',
          'member_id': 'VO-007',
          'pin_hash': '1234',
          'name': 'Mayur Patil',
          'member_type': 'working',
          'role_id': null,
          'current_status': 'Present'
        },
        {
          'id': 'member-008',
          'member_id': 'VO-008',
          'pin_hash': '1234',
          'name': 'Aditya Deshmukh',
          'member_type': 'working',
          'role_id': null,
          'current_status': 'Present'
        },
        {
          'id': 'member-009',
          'member_id': 'VO-009',
          'pin_hash': '1234',
          'name': 'Dinesh Dhanuka',
          'member_type': 'working',
          'role_id': null,
          'current_status': 'Present'
        },
        {
          'id': 'member-010',
          'member_id': 'VO-010',
          'pin_hash': '1234',
          'name': 'Preet',
          'member_type': 'working',
          'role_id': null,
          'current_status': 'Present'
        },
      ];

      await _client.from('members').upsert(members);

      debugPrint('✅ Supabase Seeding Completed Successfully!');
    } catch (e) {
      debugPrint('❌ Error seeding Supabase data: $e');
    }
  }

  /// 2. DELETE SEED DATA FROM SUPABASE
  static Future<void> deleteSeedData() async {
    try {
      debugPrint('🧹 Cleaning Seed Data from Supabase...');

      final memberIds = [
        'member-001',
        'member-002',
        'member-003',
        'member-004',
        'member-005',
        'member-006',
        'member-007',
        'member-008',
        'member-009',
        'member-010'
      ];

      // Delete Members
      await _client.from('members').delete().filter('id', 'in', memberIds);

      // Delete Role Permissions & Roles
      final roleIds = ['role-pm-001', 'role-oc-001', 'role-aoc-001'];
      await _client.from('role_permissions').delete().filter('role_id', 'in', roleIds);
      await _client.from('roles').delete().filter('id', 'in', roleIds);
      await _client.from('permissions').delete().eq('id', 'perm-ack-001');

      debugPrint('✅ Supabase Seed Data Deleted Successfully!');
    } catch (e) {
      debugPrint('❌ Error deleting Supabase seed data: $e');
    }
  }
}
