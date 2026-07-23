import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/auth_provider.dart';
import 'presentation/screens/app_shell.dart';
import 'presentation/screens/auth/member_login_screen.dart';

import 'core/providers/app_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final container = ProviderContainer();
  final db = container.read(databaseProvider);
  
  // Ensure the database has the initial Project Manager if it's empty
  try {
    await db.seedInitialAdmin();
  } catch (e) {
    debugPrint('Failed to seed initial admin: $e');
  }

  final authNotifier = container.read(authProvider.notifier);
  await authNotifier.tryAutoLogin();

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
