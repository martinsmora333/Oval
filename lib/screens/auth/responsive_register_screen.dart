import 'package:flutter/material.dart';

import 'register_screen.dart' as base;

/// Compile-safe wrapper that reuses the current registration implementation.
class ResponsiveRegisterScreen extends StatelessWidget {
  const ResponsiveRegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const base.RegisterScreen();
  }
}

/// Backwards-compatible alias for call sites that still import this file.
class RegisterScreen extends ResponsiveRegisterScreen {
  const RegisterScreen({super.key});
}
