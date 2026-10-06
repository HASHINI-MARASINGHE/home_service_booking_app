import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../models/provider_verification.dart';
import '../../services/auth_service.dart';
import '../../services/provider_verification_service.dart';
import '../../widgets/common/app_widgets.dart';
import '../auth/logout_button.dart';
import 'provider_home_screen.dart';
import 'unverified_provider_shell.dart';

/// Decides what a signed-in provider gets: the full app once an admin has
/// verified them, otherwise only the profile and notifications. It follows the
/// verification live, so the moment an admin approves, the jobs unlock.
class ProviderGate extends StatefulWidget {
  const ProviderGate({
    super.key,
    required this.user,
    required this.authService,
    this.verificationService,
  });

  final AppUser user;
  final AuthService authService;
  final ProviderVerificationService? verificationService;

  @override
  State<ProviderGate> createState() => _ProviderGateState();
}

class _ProviderGateState extends State<ProviderGate> {
  late final ProviderVerificationService _service =
      widget.verificationService ?? ProviderVerificationService();
  late Stream<ProviderVerification?> _verification = _service.watch();

  @override
  Widget build(BuildContext context) => StreamBuilder<ProviderVerification?>(
    stream: _verification,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        final error = snapshot.error!;
        final denied =
            error is FirebaseException && error.code == 'permission-denied';
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ErrorState(
                    error: error,
                    onRetry: () =>
                        setState(() => _verification = _service.watch()),
                  ),
                ),
                if (denied)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Technical detail: the Firestore security rules in '
                      'this Firebase project do not allow reading '
                      'providerVerifications yet. Publish the latest '
                      'firestore.rules (Firebase console > Firestore > Rules '
                      '> Publish), then tap Try again.',
                      key: const ValueKey('rules-hint'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                // Never leave a provider stuck on an error screen.
                LogoutButton(authService: widget.authService),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      }
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      final verification = snapshot.data;
      if (verification?.isVerified == true) {
        return ProviderHomeScreen(
          user: widget.user,
          authService: widget.authService,
          verification: verification,
        );
      }
      return UnverifiedProviderShell(
        user: widget.user,
        authService: widget.authService,
        verificationService: _service,
        verification: verification,
      );
    },
  );
}
