import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';

class MemberLoginScreen extends ConsumerStatefulWidget {
  const MemberLoginScreen({super.key});

  @override
  ConsumerState<MemberLoginScreen> createState() => _MemberLoginScreenState();
}

class _MemberLoginScreenState extends ConsumerState<MemberLoginScreen> {
  final _idController = TextEditingController();
  final _pinController = TextEditingController();
  bool _isLoading = false;
  bool _hasError = false;

  void _login() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    final success = await ref.read(authProvider.notifier).loginMember(
      _idController.text.trim(),
      _pinController.text.trim(),
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (!success) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'Vedic Oasis',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const SizedBox(height: 48),
              Text(
                'Member Login',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.onSurface,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your assigned Member ID and PIN',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _idController,
                decoration: InputDecoration(
                  labelText: 'Member ID (e.g. VO-001)',
                  filled: true,
                  fillColor: AppTheme.surfaceContainerLowest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: InputDecoration(
                  labelText: '4-Digit PIN',
                  errorText: _hasError ? 'Invalid Member ID or PIN' : null,
                  filled: true,
                  fillColor: AppTheme.surfaceContainerLowest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.dialpad),
                ),
                onSubmitted: (_) => _login(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Login',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
