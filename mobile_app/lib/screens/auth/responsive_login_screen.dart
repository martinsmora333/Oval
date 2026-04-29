import 'package:flutter/material.dart';

import 'login_screen.dart' as base;

/// Backwards-compatible wrapper around the canonical login implementation.
class ResponsiveLoginScreen extends StatelessWidget {
  const ResponsiveLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const base.LoginScreen();
  }
}

/// Legacy alias for imports that still target this file.
class LoginScreen extends ResponsiveLoginScreen {
  const LoginScreen({super.key});
}
