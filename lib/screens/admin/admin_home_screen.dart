import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../models/app_user.dart';
import '../../models/provider_verification.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/common/app_bottom_nav.dart';
import '../../widgets/common/app_widgets.dart';
import '../auth/logout_button.dart';
import 'admin_verification_screen.dart';

/// Admin dashboard: pending provider verifications and the admin's profile.
class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({
    super.key,
    required this.user,
    required this.authService,
    this.service,
  });

  final AppUser user;
  final AuthService authService;
  final AdminService? service;

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  late final AdminService _service = widget.service ?? AdminService();
  late final Stream<int> _pending = _service.watchPendingCount();
  int _tab = 0;

  @override
  Widget build(BuildContext context) => StreamBuilder<int>(
    stream: _pending,
    builder: (context, snapshot) {
      final pending = snapshot.data ?? 0;
      return Scaffold(
        appBar: AppBar(title: Text(_tab == 0 ? 'Providers' : 'Profile')),
        body: SafeArea(
          child: _tab == 0
              ? AdminProvidersScreen(service: _service)
              : AdminProfileScreen(
                  user: widget.user,
                  authService: widget.authService,
                  service: _service,
                ),
        ),
        bottomNavigationBar: AppBottomNav(
          items: [
            AppNavItem(
              icon: LucideIcons.shieldCheck,
              label: 'Providers',
              badge: pending,
            ),
            const AppNavItem(icon: LucideIcons.user, label: 'Profile'),
          ],
          selectedIndex: _tab,
          onSelected: (index) => setState(() => _tab = index),
        ),
      );
    },
  );
}

/// Pending / verified / rejected provider submissions.
class AdminProvidersScreen extends StatefulWidget {
  const AdminProvidersScreen({super.key, required this.service});
  final AdminService service;

  @override
  State<AdminProvidersScreen> createState() => _AdminProvidersScreenState();
}

class _AdminProvidersScreenState extends State<AdminProvidersScreen> {
  VerificationStatus _filter = VerificationStatus.pending;
  late Stream<List<ProviderVerification>> _items = widget.service
      .watchByStatus(_filter);

  void _select(VerificationStatus status) => setState(() {
    _filter = status;
    _items = widget.service.watchByStatus(status);
  });

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.xs,
          AppSpacing.screen,
          AppSpacing.sm,
        ),
        child: SizedBox(
          width: double.infinity,
          child: SegmentedButton<VerificationStatus>(
            segments: const [
              ButtonSegment(
                value: VerificationStatus.pending,
                label: Text('Pending'),
              ),
              ButtonSegment(
                value: VerificationStatus.verified,
                label: Text('Verified'),
              ),
              ButtonSegment(
                value: VerificationStatus.rejected,
                label: Text('Rejected'),
              ),
            ],
            selected: {_filter},
            showSelectedIcon: false,
            onSelectionChanged: (s) => _select(s.first),
          ),
        ),
      ),
      Expanded(
        child: StreamBuilder<List<ProviderVerification>>(
          stream: _items,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return ErrorState(
                error: snapshot.error!,
                onRetry: () => _select(_filter),
              );
            }
            if (!snapshot.hasData) return const LoadingState();
            final items = snapshot.data!;
            if (items.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Text(
                    switch (_filter) {
                      VerificationStatus.pending =>
                        'No providers are waiting for verification.',
                      VerificationStatus.verified =>
                        'No verified providers yet.',
                      _ => 'No rejected submissions.',
                    },
                    key: const ValueKey('admin-empty'),
                    textAlign: TextAlign.center,
                    style: AppTypography.body,
                  ),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                0,
                AppSpacing.screen,
                AppSpacing.xl,
              ),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, i) => _ProviderTile(
                submission: items[i],
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AdminVerificationScreen(
                      service: widget.service,
                      submission: items[i],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ],
  );
}

class _ProviderTile extends StatelessWidget {
  const _ProviderTile({required this.submission, required this.onTap});
  final ProviderVerification submission;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = submission;
    return AppCard(
      key: ValueKey('provider-tile-${s.uid}'),
      onTap: onTap,
      child: Row(
        children: [
          PersonAvatar(name: s.fullName, size: 48),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.title,
                ),
                Text(
                  '${s.profession.isEmpty ? 'Provider' : s.profession} · '
                  '${s.experienceYears} yr${s.experienceYears == 1 ? '' : 's'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body,
                ),
                Text(
                  s.submittedAt == null
                      ? 'Submitted'
                      : 'Submitted ${Formatters.shortDate(s.submittedAt!)}',
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          switch (s.status) {
            VerificationStatus.verified => StatusPill(
              label: s.providerCode ?? 'Verified',
              background: AppColors.successSoft,
              color: AppColors.success,
            ),
            VerificationStatus.rejected => const StatusPill(
              label: 'Rejected',
              background: AppColors.dangerSoft,
              color: AppColors.danger,
            ),
            _ => const StatusPill(
              label: 'Review',
              background: AppColors.warningSoft,
              color: AppColors.warning,
            ),
          },
          const Icon(LucideIcons.chevronRight, size: 18, color: AppColors.muted),
        ],
      ),
    );
  }
}

/// The admin's own profile and a summary of the review queue.
class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({
    super.key,
    required this.user,
    required this.authService,
    required this.service,
  });

  final AppUser user;
  final AuthService authService;
  final AdminService service;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(AppSpacing.screen),
    children: [
      AppCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            PersonAvatar(name: user.name, size: 72),
            const SizedBox(height: AppSpacing.sm),
            Text(user.name, style: AppTypography.headline),
            const SizedBox(height: 4),
            Text(user.email, style: AppTypography.caption),
            const SizedBox(height: AppSpacing.sm),
            const StatusPill(
              label: 'Administrator',
              icon: LucideIcons.shieldCheck,
              background: AppColors.primaryTint,
              color: AppColors.primaryDark,
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      Row(
        children: [
          for (final status in [
            VerificationStatus.pending,
            VerificationStatus.verified,
            VerificationStatus.rejected,
          ])
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _CountCard(service: service, status: status),
              ),
            ),
        ],
      ),
      const SizedBox(height: AppSpacing.lg),
      LogoutButton(authService: authService),
    ],
  );
}

class _CountCard extends StatelessWidget {
  const _CountCard({required this.service, required this.status});
  final AdminService service;
  final VerificationStatus status;

  @override
  Widget build(BuildContext context) => AppCard(
    child: StreamBuilder<List<ProviderVerification>>(
      stream: service.watchByStatus(status),
      builder: (context, snapshot) => Column(
        children: [
          Text(
            '${snapshot.data?.length ?? 0}',
            key: ValueKey('count-${status.name}'),
            style: AppTypography.headline,
          ),
          const SizedBox(height: 2),
          Text(
            '${status.name[0].toUpperCase()}${status.name.substring(1)}',
            style: AppTypography.caption,
          ),
        ],
      ),
    ),
  );
}
