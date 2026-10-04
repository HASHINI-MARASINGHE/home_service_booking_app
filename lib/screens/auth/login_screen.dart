import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import 'auth_form.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({
    super.key,
    required this.authService,
    required this.onRegister,
  });

  final AuthService authService;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) =>
      AuthForm(authService: authService, register: false, onSwitch: onRegister);
}
