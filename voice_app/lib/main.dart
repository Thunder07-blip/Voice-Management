import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/auth_provider.dart';
import 'presentation/screens/app_shell.dart';
import 'presentation/screens/auth/member_login_screen.dart';
import 'data/remote/supabase_config.dart';
import 'core/services/device_notification_service.dart';

import 'core/providers/app_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );
  
  final container = ProviderContainer();
  // Pull the shared catalog and records before trying auto-login. The app no
  // longer manufactures device-only demo accounts, which keeps every phone on
  // the same Supabase source of truth.
  final syncEngine = container.read(syncEngineProvider);
  await syncEngine.startRealtimeSync();
  await syncEngine.syncNow();

  final authNotifier = container.read(authProvider.notifier);
  await authNotifier.tryAutoLogin();

  await DeviceNotificationService.requestPermission();

  runApp(UncontrolledProviderScope(
    container: container,
    child: const VoiceApp(),
  ));
}

class VoiceApp extends ConsumerWidget {
  const VoiceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'Voice — Vedic Oasis',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: authState.currentMember == null 
          ? const MemberLoginScreen() 
          : const AppShell(),
    );
  }
}
