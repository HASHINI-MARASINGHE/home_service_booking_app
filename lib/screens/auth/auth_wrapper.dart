import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'login_screen.dart';
import 'provider_registration_screen.dart';
import 'register_screen.dart';
import 'role_selection_screen.dart';
import 'logout_button.dart';

import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../customer/customer_home_screen.dart';
import '../admin/admin_home_screen.dart';
import '../provider/provider_gate.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key, this.authService});

  final AuthService? authService;

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  late final AuthService _service = widget.authService ?? AuthService();
  late final Stream<User?> _authChanges = _service.authStateChanges();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authChanges,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(
              child: Text(
                'Unable to check your session. Please restart the app.',
              ),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snapshot.data;
        if (user == null) return _SignedOut(authService: _service);
        return _ProfileGate(
          key: ValueKey(user.uid),
          uid: user.uid,
          authService: _service,
        );
      },
    );
  }
}

class _SignedOut extends StatefulWidget {
  const _SignedOut({required this.authService});
  final AuthService authService;

  @override
  State<_SignedOut> createState() => _SignedOutState();
}

enum _SignedOutStep { login, role, register }

class _SignedOutState extends State<_SignedOut> {
  var _step = _SignedOutStep.login;
  String _role = AppUser.customerRole;

  void _go(_SignedOutStep step) => setState(() => _step = step);

  void _continue(String role) {
    _role = role;
    if (role == AppUser.providerRole) {
      // The provider sign-up is its own pushed flow and closes itself.
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              ProviderRegistrationScreen(authService: widget.authService),
        ),
      );
    } else {
      _go(_SignedOutStep.register);
    }
  }

  // Sign-up steps replace each other in place, so system back walks them
  // back one step instead of leaving the app.
  Widget _backTo(_SignedOutStep step, Widget child) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _go(step);
    },
    child: child,
  );

  @override
  Widget build(BuildContext context) => switch (_step) {
    _SignedOutStep.login => LoginScreen(
      authService: widget.authService,
      onRegister: () => _go(_SignedOutStep.role),
    ),
    _SignedOutStep.role => _backTo(
      _SignedOutStep.login,
      RoleSelectionScreen(
        initialRole: _role,
        onContinue: _continue,
        onLogin: () => _go(_SignedOutStep.login),
      ),
    ),
    _SignedOutStep.register => _backTo(
      _SignedOutStep.role,
      RegisterScreen(
        authService: widget.authService,
        role: _role,
        onLogin: () => _go(_SignedOutStep.login),
        onChangeRole: () => _go(_SignedOutStep.role),
      ),
    ),
  };
}

class _ProfileGate extends StatefulWidget {
  const _ProfileGate({super.key, required this.uid, required this.authService});
  final String uid;
  final AuthService authService;

  @override
  State<_ProfileGate> createState() => _ProfileGateState();
}

class _ProfileGateState extends State<_ProfileGate> {
  late Future<AppUser?> _profile = widget.authService.getUserProfile(
    widget.uid,
  );

  @override
  Widget build(BuildContext context) => FutureBuilder<AppUser?>(
    future: _profile,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      final profile = snapshot.data;
      if (snapshot.hasError || profile == null) {
        return Scaffold(
          appBar: AppBar(title: const Text('Profile unavailable')),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    snapshot.hasError
                        ? 'Your profile could not be loaded. Please retry or contact support.'
                        : 'No profile was found for your account. Please contact support.',
                  ),
                  FilledButton(
                    onPressed: () => setState(() {
                      _profile = widget.authService.getUserProfile(widget.uid);
                    }),
                    child: const Text('Retry'),
                  ),
                  LogoutButton(authService: widget.authService),
                ],
              ),
            ),
          ),
        );
      }
      return switch (profile.role) {
        AppUser.customerRole => CustomerHomeScreen(
          user: profile,
          authService: widget.authService,
        ),
        AppUser.providerRole => ProviderGate(
          user: profile,
          authService: widget.authService,
        ),
        AppUser.adminRole => AdminHomeScreen(
          user: profile,
          authService: widget.authService,
        ),
        _ => const Scaffold(
          body: Center(child: Text('Unsupported account role.')),
        ),
      };
    },
  );
}
