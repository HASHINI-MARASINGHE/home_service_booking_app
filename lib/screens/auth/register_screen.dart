import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import 'auth_form.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({
    super.key,
    required this.authService,
    required this.onLogin,
  });

  final AuthService authService;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) =>
      AuthForm(authService: authService, register: true, onSwitch: onLogin);
}
