import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pyq/features/auth/register_screen.dart';
import 'package:pyq/features/auth/widgets/auth_shell.dart';

import 'package:pyq/features/auth/auth_controller.dart';
import 'package:pyq/features/home/home_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController emailController;
  late TextEditingController passwordController;
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();
    passwordController = TextEditingController();
    ref.read(authControllerProvider.notifier).restoreSession().then((_) {
      final ok = ref.read(authControllerProvider).valueOrNull ?? false;
      if (ok && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return AuthShell(
      icon: Icons.school_rounded,
      title: 'Welcome Back',
      subtitle:
          'Practice previous year questions for UPSC, JEE, NEET and more with timed flows.',
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
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _showPassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () =>
                      setState(() => _showPassword = !_showPassword),
                ),
              ),
              validator: (value) =>
                  (value?.trim().length ?? 0) < 6 ? 'Min 6 characters' : null,
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
                          .login(
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
                            content: Text(err?.toString() ?? 'Login failed'),
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
                  : const Text('Sign In'),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: Divider(color: Theme.of(context).dividerColor)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('NEW HERE?'),
                ),
                Expanded(child: Divider(color: Theme.of(context).dividerColor)),
              ],
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const RegisterScreen())),
              child: const Text('Create your account and start practicing'),
            ),
          ],
        ),
      ),
    );
  }
}
