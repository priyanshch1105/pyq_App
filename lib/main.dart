import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/router/app_router.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: PyqApp()));
}

class PyqApp extends StatelessWidget {
  const PyqApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      onGenerateRoute: AppRouter.onGenerateRoute,
      initialRoute: AppRoutes.login,
    );
  }
}
