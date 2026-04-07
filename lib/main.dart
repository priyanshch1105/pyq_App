import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';

void main() {
  runApp(const ProviderScope(child: PyqApp()));
}

class PyqApp extends StatelessWidget {
  const PyqApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PYQ Master',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const LoginScreen(),
    );
  }
}
