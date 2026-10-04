import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../auth/logout_button.dart';

class CustomerHomeScreen extends StatelessWidget {
  const CustomerHomeScreen({
    super.key,
    required this.user,
    required this.authService,
  });

  final AppUser user;
  final AuthService authService;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Customer home'),
      actions: [LogoutButton(authService: authService)],
    ),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Welcome, ${user.name}!\nYour customer dashboard is coming soon.',
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );
}
