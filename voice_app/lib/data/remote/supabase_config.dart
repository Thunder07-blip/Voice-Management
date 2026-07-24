import 'package:supabase_flutter/supabase_flutter.dart';

/// Central Supabase client accessor.
/// Initialize once in main.dart, then use SupabaseClient everywhere.
class SupabaseConfig {
  static const String supabaseUrl = 'https://viuqtsrnfssouqzqmhhy.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_Q44dHPKX3LuENs1xV7QKdw_7Ygk56JD';

  static SupabaseClient get client => Supabase.instance.client;
}
