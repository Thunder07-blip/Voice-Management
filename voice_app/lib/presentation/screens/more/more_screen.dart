import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../auth/admin_login_screen.dart';
import '../auth/administration_screen.dart';
import '../app_drawer.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    
    return Scaffold(
      backgroundColor: AppTheme.surface,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(
          'More',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: AppTheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (['Project Manager', 'Overall Coordinator', 'Assistant Overall Coordinator'].contains(authState.currentRole?.name))
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppTheme.outlineVariant),
              ),
              tileColor: AppTheme.surfaceContainerLowest,
              leading: Icon(
                Icons.admin_panel_settings,
                color: authState.isAdminMode ? AppTheme.primary : AppTheme.onSurfaceVariant,
              ),
              title: const Text('Administration'),
              subtitle: Text(
                authState.isAdminMode ? 'Manage Members & Roles' : 'Admin Login',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                if (authState.isAdminMode) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AdministrationScreen()),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
                  );
                }
              },
            ),
          const SizedBox(height: 12),
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppTheme.outlineVariant),
            ),
            tileColor: AppTheme.surfaceContainerLowest,
            leading: const Icon(Icons.password, color: AppTheme.onSurfaceVariant),
            title: const Text('Change PIN'),
            subtitle: const Text('Update your 4-digit daily login PIN'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                backgroundColor: AppTheme.surfaceContainerLowest,
                builder: (context) => const _ChangePinDialog(),
              );
            },
          ),
          // ... more settings can go here
        ],
      ),
    );
  }
}

class _ChangePinDialog extends ConsumerStatefulWidget {
  const _ChangePinDialog();

  @override
  ConsumerState<_ChangePinDialog> createState() => _ChangePinDialogState();
}

class _ChangePinDialogState extends ConsumerState<_ChangePinDialog> {
  final _currentPinController = TextEditingController();
  final _newPinController = TextEditingController();
  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _currentPinController.dispose();
    _newPinController.dispose();
    super.dispose();
  }

  void _submit() async {
    final currentPin = _currentPinController.text.trim();
    final newPin = _newPinController.text.trim();

    if (currentPin.length != 4 || newPin.length != 4) {
      setState(() => _errorText = 'PINs must be exactly 4 digits');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    final success = await ref.read(authProvider.notifier).changePin(currentPin, newPin);

    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN successfully changed!')),
      );
    } else {
      setState(() {
        _isLoading = false;
        _errorText = 'Incorrect current PIN. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Change PIN',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_errorText != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _errorText!,
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
          TextField(
            controller: _currentPinController,
            keyboardType: TextInputType.number,
            maxLength: 4,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Current PIN',
              filled: true,
              counterText: '',
              fillColor: AppTheme.surfaceContainerLowest,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _newPinController,
            keyboardType: TextInputType.number,
            maxLength: 4,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'New 4-Digit PIN',
              filled: true,
              counterText: '',
              fillColor: AppTheme.surfaceContainerLowest,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Update PIN',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
