import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../../theme/customer_home_theme.dart';
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
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Profile updated.')));
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
  Widget build(BuildContext context) => SafeArea(
    child: CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const Text(
                'Profile',
                style: TextStyle(
                  color: CustomerHomeTheme.primaryDark,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
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
              _ProfileHeader(user: user, onEdit: onEdit),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit Profile'),
                  style: FilledButton.styleFrom(
                    backgroundColor: CustomerHomeTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _ProfileDetailsCard(user: user),
              const SizedBox(height: 32),
              _ProfileLogoutButton(authService: authService),
            ]),
          ),
        ),
      ],
    ),
  );
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user, required this.onEdit});

  final AppUser user;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [CustomerHomeTheme.mint, CustomerHomeTheme.background],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: CustomerHomeTheme.border),
    ),
    child: Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                    color: CustomerHomeTheme.shadow,
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: CustomerAvatar(photoUrl: user.photoUrl, radius: 48),
            ),
            Positioned(
              right: -2,
              bottom: 0,
              child: Material(
                color: CustomerHomeTheme.primary,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: onEdit,
                  customBorder: const CircleBorder(),
                  child: const Padding(
                    padding: EdgeInsets.all(9),
                    child: Icon(
                      Icons.camera_alt_outlined,
                      color: Colors.white,
                      size: 17,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          _valueOrFallback(user.name),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: CustomerHomeTheme.text,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _valueOrFallback(user.email),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: CustomerHomeTheme.mutedText,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 14),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.verified_user_outlined,
                  color: CustomerHomeTheme.primary,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  _accountLabel(user.role),
                  style: const TextStyle(
                    color: CustomerHomeTheme.primaryDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _ProfileDetailsCard extends StatelessWidget {
  const _ProfileDetailsCard({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [
        BoxShadow(
          color: CustomerHomeTheme.shadow,
          blurRadius: 18,
          offset: Offset(0, 8),
        ),
      ],
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
          value: _accountLabel(user.role),
        ),
      ],
    ),
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
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: CustomerHomeTheme.mint,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: CustomerHomeTheme.primary, size: 19),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: CustomerHomeTheme.mutedText,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: CustomerHomeTheme.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ProfileLogoutButton extends StatefulWidget {
  const _ProfileLogoutButton({required this.authService});

  final AuthService authService;

  @override
  State<_ProfileLogoutButton> createState() => _ProfileLogoutButtonState();
}

class _ProfileLogoutButtonState extends State<_ProfileLogoutButton> {
  bool _busy = false;

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
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
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: OutlinedButton.icon(
      onPressed: _busy ? null : _confirmLogout,
      icon: const Icon(Icons.logout_outlined),
      label: Text(_busy ? 'Logging out...' : 'Log out'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.error,
        side: BorderSide(color: Theme.of(context).colorScheme.error),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
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

String _accountLabel(String role) => switch (role) {
  AppUser.customerRole => 'Customer',
  AppUser.providerRole => 'Provider',
  _ => _valueOrFallback(role),
};
