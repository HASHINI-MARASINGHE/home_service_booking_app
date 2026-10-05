import 'package:flutter/material.dart';

import '../../services/auth_service.dart';

class LogoutButton extends StatefulWidget {
  const LogoutButton({super.key, required this.authService});
  final AuthService authService;

  @override
  State<LogoutButton> createState() => _LogoutButtonState();
}

class _LogoutButtonState extends State<LogoutButton> {
  bool _busy = false;

  Future<void> _logout() async {
    setState(() => _busy = true);
    try {
      await widget.authService.logout();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AuthService.errorMessage(error))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: _busy ? null : _logout,
    child: Text(_busy ? 'Logging out…' : 'Log out'),
  );
}
