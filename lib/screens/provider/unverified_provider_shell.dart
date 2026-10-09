import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../models/app_user.dart';
import '../../models/provider_verification.dart';
import '../../services/auth_service.dart';
import '../../services/provider_notification_service.dart';
import '../../services/provider_profile_service.dart';
import '../../services/provider_verification_service.dart';
import '../../widgets/common/app_bottom_nav.dart';
import '../../widgets/common/app_widgets.dart';
import 'provider_notifications_screen.dart';
import 'provider_profile_screen.dart';
import 'provider_theme.dart';
import 'verification/verification_screen.dart';
import '../../widgets/common/homecare_logo.dart';

/// What a provider sees until an admin verifies them: only their profile
/// (with the verification status and what to do next) and notifications.
/// Jobs, requests and earnings stay locked.
class UnverifiedProviderShell extends StatefulWidget {
  const UnverifiedProviderShell({
    super.key,
    required this.user,
    required this.authService,
    required this.verificationService,
    this.verification,
    this.profileService,
    this.notificationService,
  });

  final AppUser user;
  final AuthService authService;
  final ProviderVerificationService verificationService;

  /// Null when nothing has been submitted yet.
  final ProviderVerification? verification;
  final ProviderProfileService? profileService;
  final ProviderNotificationService? notificationService;

  @override
  State<UnverifiedProviderShell> createState() =>
      _UnverifiedProviderShellState();
}

class _UnverifiedProviderShellState extends State<UnverifiedProviderShell> {
  late final _profileService =
      widget.profileService ?? ProviderProfileService();
  late final _notificationService =
      widget.notificationService ?? ProviderNotificationService();
  late final Stream<int> _unread = _notificationService.watchUnreadCount();
  int _tab = 0;

  VerificationStatus get _status =>
      widget.verification?.status ?? VerificationStatus.none;

  Future<void> _openVerification() async {
    final submitted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => VerificationScreen(
          user: widget.user,
          service: widget.verificationService,
          previous: widget.verification,
        ),
      ),
    );
    if (submitted == true && mounted) {
      showAppSnack(
        context,
        'Submitted! Our team will review your documents and notify you.',
      );
    }
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: ProviderTheme.data,
    child: Builder(
      builder: (context) => StreamBuilder<int>(
        stream: _unread,
        builder: (context, snapshot) => BrandShell(
          child: Scaffold(
            appBar: AppBar(
              title: Text(_tab == 0 ? 'Profile' : 'Notifications'),
            ),
            body: SafeArea(
              child: _tab == 0
                  ? ProviderProfileScreen(
                      user: widget.user,
                      authService: widget.authService,
                      service: _profileService,
                      verificationStatus: _status,
                      verification: widget.verification,
                      onOpenVerification: _openVerification,
                    )
                  : ProviderNotificationsScreen(
                      service: _notificationService,
                      onOpen: (_) => setState(() => _tab = 0),
                    ),
            ),
            bottomNavigationBar: AppBottomNav(
              items: [
                const AppNavItem(icon: LucideIcons.user, label: 'Profile'),
                AppNavItem(
                  icon: LucideIcons.bell,
                  label: 'Notifications',
                  badge: snapshot.data ?? 0,
                ),
              ],
              selectedIndex: _tab,
              onSelected: (index) => setState(() => _tab = index),
            ),
          ),
        ),
      ),
    ),
  );
}
