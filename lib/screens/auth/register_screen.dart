import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import 'auth_form.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({
    super.key,
    required this.authService,
    required this.onLogin,
    this.role,
    this.onChangeRole,
  });

  final AuthService authService;
  final VoidCallback onLogin;

  /// Role picked on the role selection screen; null shows the role dropdown.
  final String? role;
  final VoidCallback? onChangeRole;

  @override
  Widget build(BuildContext context) => AuthForm(
    authService: authService,
    register: true,
    onSwitch: onLogin,
    initialRole: role,
    onChangeRole: onChangeRole,
  );
}
