import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pyq/features/auth/widgets/auth_shell.dart';

import 'package:pyq/features/auth/auth_controller.dart';
import 'package:pyq/features/home/home_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool _showPassword = false;
  bool _showConfirm = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return AuthShell(
      icon: Icons.person_add_rounded,
      title: 'Create Your Account',
      subtitle:
          'Join structured PYQ practice with analytics, mock tests, and revision plans.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (value) {
                final input = value?.trim() ?? '';
                if (input.isEmpty) return 'Email required';
                if (!input.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: passwordController,
              obscureText: !_showPassword,
              decoration: InputDecoration(
                labelText: 'Create Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  onPressed: () =>
                      setState(() => _showPassword = !_showPassword),
                  icon: Icon(
                    _showPassword ? Icons.visibility_off : Icons.visibility,
                  ),
                ),
              ),
              validator: (value) => (value?.trim().length ?? 0) < 6
                  ? 'At least 6 characters'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: confirmPasswordController,
              obscureText: !_showConfirm,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: const Icon(Icons.security_outlined),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _showConfirm = !_showConfirm),
                  icon: Icon(
                    _showConfirm ? Icons.visibility_off : Icons.visibility,
                  ),
                ),
              ),
              validator: (value) {
                if ((value?.trim().isEmpty ?? true)) {
                  return 'Confirm your password';
                }
                if (value!.trim() != passwordController.text.trim()) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: authState.isLoading
                  ? null
                  : () async {
                      final navigator = Navigator.of(context);
                      final messenger = ScaffoldMessenger.of(context);
                      final valid = _formKey.currentState?.validate() ?? false;
                      if (!valid) return;

                      final ok = await ref
                          .read(authControllerProvider.notifier)
                          .register(
                            emailController.text.trim(),
                            passwordController.text.trim(),
                          );
                      if (!context.mounted) return;
                      if (ok) {
                        navigator.pushReplacement(
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                        );
                      } else {
                        final err = ref.read(authControllerProvider).error;
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              err?.toString() ?? 'Registration failed',
                            ),
                          ),
                        );
                      }
                    },
              child: authState.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create Account'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Already have an account? Sign In'),
            ),
          ],
        ),
      ),
    );
  }
}
