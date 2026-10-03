import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../../theme/customer_home_theme.dart';
import '../auth/logout_button.dart';
import 'edit_profile_screen.dart';
import 'widgets/customer_home_widgets.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({
    super.key,
    required this.uid,
    required this.authService,
    this.onUserUpdated,
  });

  final String uid;
  final AuthService authService;
  final ValueChanged<AppUser>? onUserUpdated;

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  late Future<AppUser?> _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    _profile = widget.authService.getUserProfile(widget.uid);
  }

  void _retry() {
    setState(_loadProfile);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<AppUser?>(
    future: _profile,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError || snapshot.data == null) {
        return _ProfileError(onRetry: _retry, hasError: snapshot.hasError);
      }
      return _ProfileContent(
        user: snapshot.data!,
        authService: widget.authService,
        onEdit: () => _openEditProfile(snapshot.data!),
      );
    },
  );

  Future<void> _openEditProfile(AppUser user) async {
    final updated = await Navigator.of(context).push<AppUser>(
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          user: user,
          authService: widget.authService,
          onUserUpdated: widget.onUserUpdated,
        ),
      ),
    );
    if (!mounted || updated == null) return;
    setState(_loadProfile);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile updated.')));
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({
    required this.user,
    required this.authService,
    required this.onEdit,
  });

  final AppUser user;
  final AuthService authService;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) => CustomScrollView(
    slivers: [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        sliver: SliverList(
          delegate: SliverChildListDelegate([
            const Text(
              'Profile',
              style: TextStyle(
                color: CustomerHomeTheme.primaryDark,
                fontSize: 32,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your account details',
              style: TextStyle(
                color: CustomerHomeTheme.mutedText,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: CustomerHomeTheme.border),
                boxShadow: const [
                  BoxShadow(
                    color: CustomerHomeTheme.shadow,
                    blurRadius: 22,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CustomerAvatar(photoUrl: user.photoUrl, radius: 34),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _valueOrFallback(user.name),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: CustomerHomeTheme.text,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _valueOrFallback(user.email),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: CustomerHomeTheme.mutedText,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit Profile'),
              style: OutlinedButton.styleFrom(
                foregroundColor: CustomerHomeTheme.primary,
                side: const BorderSide(color: CustomerHomeTheme.primary),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: CustomerHomeTheme.border),
              ),
              child: Column(
                children: [
                  _ProfileDetail(
                    icon: Icons.badge_outlined,
                    label: 'Full name',
                    value: _valueOrFallback(user.name),
                  ),
                  const Divider(height: 1, color: CustomerHomeTheme.border),
                  _ProfileDetail(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: _valueOrFallback(user.email),
                  ),
                  const Divider(height: 1, color: CustomerHomeTheme.border),
                  _ProfileDetail(
                    icon: Icons.account_circle_outlined,
                    label: 'Account type',
                    value: _valueOrFallback(user.role),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: LogoutButton(authService: authService),
            ),
          ]),
        ),
      ),
    ],
  );
}

class _ProfileDetail extends StatelessWidget {
  const _ProfileDetail({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Row(
      children: [
        Icon(icon, color: CustomerHomeTheme.primary, size: 21),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: CustomerHomeTheme.mutedText,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: CustomerHomeTheme.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ProfileError extends StatelessWidget {
  const _ProfileError({required this.onRetry, required this.hasError});

  final VoidCallback onRetry;
  final bool hasError;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            hasError
                ? 'Your profile could not be loaded.'
                : 'No profile was found for this account.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: CustomerHomeTheme.text,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    ),
  );
}

String _valueOrFallback(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? 'Not provided' : trimmed;
}
