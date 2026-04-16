import 'package:flutter/material.dart';
import 'package:pyq/features/auth/login_screen.dart';

class AppRoutes {
  const AppRoutes._();

  static const login = '/login';
}

class AppRouter {
  const AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.login:
      case '/':
        return MaterialPageRoute<void>(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );
    }

    return MaterialPageRoute<void>(
      builder: (_) =>
          const Scaffold(body: Center(child: Text('Route not found'))),
      settings: settings,
    );
  }
}
