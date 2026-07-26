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
          'id': 'VV001',
          'member_id': 'VV001',
          'pin_hash': '1234',
          'name': 'HG Radhapad pankaj pr',
          'member_type': 'working',
          'role_id': 'role-pm-001',
          'current_status': 'Present'
        },
        {
          'id': 'VV002',
          'member_id': 'VV002',
          'pin_hash': '1234',
          'name': 'Piyush Jagzap',
          'member_type': 'working',
          'role_id': 'role-oc-001',
          'current_status': 'Present'
        },
        {
          'id': 'VV003',
          'member_id': 'VV003',
          'pin_hash': '1234',
          'name': 'Sajal Patil',
          'member_type': 'working',
          'role_id': 'role-aoc-001',
          'current_status': 'Present'
        },
        {
          'id': 'VV004',
          'member_id': 'VV004',
          'pin_hash': '1234',
          'name': 'Soham Dode',
          'member_type': 'working',
          'role_id': null,
          'current_status': 'Present'
        },
        {
          'id': 'VV005',
          'member_id': 'VV005',
          'pin_hash': '1234',
          'name': 'Sushant Nikaju',
          'member_type': 'working',
          'role_id': null,
          'current_status': 'Present'
        },
        {
          'id': 'VV006',
          'member_id': 'VV006',
          'pin_hash': '1234',
          'name': 'Pratik Gadade',
          'member_type': 'working',
          'role_id': null,
          'current_status': 'Present'
        },
        {
          'id': 'VV007',
          'member_id': 'VV007',
          'pin_hash': '1234',
          'name': 'Mayur Patil',
          'member_type': 'working',
          'role_id': null,
          'current_status': 'Present'
        },
        {
          'id': 'VV008',
          'member_id': 'VV008',
          'pin_hash': '1234',
          'name': 'Aditya Deshmukh',
          'member_type': 'working',
          'role_id': null,
          'current_status': 'Present'
        },
        {
          'id': 'VV009',
          'member_id': 'VV009',
          'pin_hash': '1234',
          'name': 'Dinesh Dhanuka',
          'member_type': 'working',
          'role_id': null,
          'current_status': 'Present'
        },
        {
          'id': 'VV010',
          'member_id': 'VV010',
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
        'VV001',
        'VV002',
        'VV003',
        'VV004',
        'VV005',
        'VV006',
        'VV007',
        'VV008',
        'VV009',
        'VV010'
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
