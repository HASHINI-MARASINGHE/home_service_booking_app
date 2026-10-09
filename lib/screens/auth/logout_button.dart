import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class LogoutButton extends StatefulWidget {
  const LogoutButton({super.key, required this.authService, this.icon});
  final AuthService authService;

  /// When given, the button is red with this icon (the provider's profile).
  final IconData? icon;

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
  Widget build(BuildContext context) {
    final label = Text(_busy ? 'Logging out…' : 'Log out');
    final icon = widget.icon;
    if (icon == null) {
      return TextButton(onPressed: _busy ? null : _logout, child: label);
    }
    return TextButton.icon(
      onPressed: _busy ? null : _logout,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.errorSolid,
        minimumSize: const Size.fromHeight(48),
      ),
      icon: Icon(icon, size: 18),
      label: label,
    );
  }
}
