import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../models/app_user.dart';
import '../../models/professional.dart';
import '../../models/provider_verification.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/common/app_bottom_nav.dart';
import '../../widgets/common/app_search_bar.dart';
import '../../widgets/common/app_widgets.dart';
import '../auth/logout_button.dart';
import 'admin_disputes_screen.dart';
import 'admin_ratings_screen.dart';
import 'admin_verification_screen.dart';
import '../../widgets/common/homecare_logo.dart';

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
  // Live streams for unread badge counts on bottom navigation tabs:
  // _pending watches unreviewed provider KYC submissions; _disputes watches pending disputes.
  late final Stream<int> _pending = _service.watchPendingCount();
  late final Stream<int> _disputes = _service.watchPendingDisputeCount();
  int _tab = 0;

  @override
  Widget build(BuildContext context) => StreamBuilder<int>(
    stream: _pending,
    builder: (context, snapshot) => StreamBuilder<int>(
      stream: _disputes,
      builder: (context, disputeSnapshot) {
        final pending = snapshot.data ?? 0;
        final disputes = disputeSnapshot.data ?? 0;
        return BrandShell(
          child: Scaffold(
            backgroundColor: AppColors.bg,
            appBar: AppBar(
              backgroundColor: AppColors.surface,
              elevation: 0,
              scrolledUnderElevation: 0,
              centerTitle: false,
              title: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.brand100,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: const Icon(
                      LucideIcons.shieldCheck,
                      size: 18,
                      color: AppColors.brand700,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    _tab == 0
                        ? 'Providers'
                        : _tab == 1
                        ? 'Ratings'
                        : _tab == 2
                        ? 'Disputes'
                        : 'Profile',
                    style: const TextStyle(
                      color: AppColors.brand900,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(
                  color: AppColors.borderSubtle,
                  height: 1,
                ),
              ),
            ),
            body: SafeArea(
              child: _tab == 0
                  ? AdminProvidersScreen(service: _service)
                  : _tab == 1
                  ? AdminRatingsScreen(service: _service)
                  : _tab == 2
                  ? AdminDisputesScreen(service: _service)
                  : AdminProfileScreen(
                      user: widget.user,
                      authService: widget.authService,
                      service: _service,
                      onNavigateToRatings: () => setState(() => _tab = 1),
                    ),
            ),
            bottomNavigationBar: AppBottomNav(
              items: [
                AppNavItem(
                  icon: LucideIcons.shieldCheck,
                  label: 'Providers',
                  badge: pending,
                ),
                const AppNavItem(icon: LucideIcons.star, label: 'Ratings'),
                AppNavItem(
                  icon: LucideIcons.triangleAlert,
                  label: 'Disputes',
                  badge: disputes,
                ),
                const AppNavItem(icon: LucideIcons.user, label: 'Profile'),
              ],
              selectedIndex: _tab,
              onSelected: (index) => setState(() => _tab = index),
            ),
          ),
        );
      },
    ),
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
  final _search = TextEditingController();
  String _selectedProfession = 'All';

  late Stream<List<ProviderVerification>> _items = widget.service.watchByStatus(
    _filter,
  );

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _select(VerificationStatus status) => setState(() {
    _filter = status;
    _items = widget.service.watchByStatus(status);
  });

  List<ProviderVerification> _filterList(List<ProviderVerification> list) {
    final query = _search.text.trim().toLowerCase();
    return list.where((item) {
      if (_selectedProfession != 'All' &&
          item.profession.toLowerCase() != _selectedProfession.toLowerCase()) {
        return false;
      }
      if (query.isEmpty) return true;
      if (item.fullName.toLowerCase().contains(query)) return true;
      if (item.profession.toLowerCase().contains(query)) return true;
      if (item.phone.toLowerCase().contains(query)) return true;
      if (item.idNumber.toLowerCase().contains(query)) return true;
      if (item.providerCode?.toLowerCase().contains(query) ?? false) return true;
      return false;
    }).toList();
  }

  List<String> _extractProfessions(List<ProviderVerification> list) {
    final set = <String>{'All'};
    for (final item in list) {
      final prof = item.profession.trim();
      if (prof.isNotEmpty) set.add(prof);
    }
    return set.toList();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.xs,
          AppSpacing.screen,
          AppSpacing.xs,
        ),
        child: SizedBox(
          width: double.infinity,
          child: SegmentedButton<VerificationStatus>(
            style: SegmentedButton.styleFrom(
              backgroundColor: AppColors.surfaceAlt,
              selectedBackgroundColor: AppColors.brand900,
              selectedForegroundColor: Colors.white,
              foregroundColor: AppColors.ink2,
              side: const BorderSide(color: AppColors.borderSubtle),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
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
      Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.xs,
          AppSpacing.screen,
          AppSpacing.xs,
        ),
        child: AppSearchBar(
          controller: _search,
          hintText: 'Search provider, NIC, phone, or code…',
          onChanged: (_) => setState(() {}),
          onClear: () => setState(() {}),
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
            final allItems = snapshot.data!;
            final professions = _extractProfessions(allItems);
            final filteredItems = _filterList(allItems);

            if (allItems.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.brand100,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: const Icon(
                          LucideIcons.shieldCheck,
                          size: 28,
                          color: AppColors.brand700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        switch (_filter) {
                          VerificationStatus.pending =>
                            'No providers are waiting for verification.',
                          VerificationStatus.verified =>
                            'No verified providers yet.',
                          _ => 'No rejected submissions.',
                        },
                        key: const ValueKey('admin-empty'),
                        textAlign: TextAlign.center,
                        style: context.textStyles.bodySmall.copyWith(
                          color: AppColors.ink2,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: [
                if (professions.length > 2) ...[
                  const SizedBox(height: AppSpacing.xs),
                  AppFilterChipBar<String>(
                    items: [
                      for (final p in professions)
                        FilterItem(
                          value: p,
                          label: p,
                          count: p == 'All'
                              ? allItems.length
                              : allItems
                                  .where((i) => i.profession.toLowerCase() == p.toLowerCase())
                                  .length,
                        ),
                    ],
                    selected: _selectedProfession,
                    onSelected: (p) => setState(() => _selectedProfession = p),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                ],
                Expanded(
                  child: filteredItems.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  LucideIcons.searchX,
                                  size: 40,
                                  color: AppColors.ink3,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  'No providers match your search or filter.',
                                  style: context.textStyles.bodySmall.copyWith(
                                    color: AppColors.ink2,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.screen,
                            AppSpacing.xs,
                            AppSpacing.screen,
                            AppSpacing.xl,
                          ),
                          itemCount: filteredItems.length,
                          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (context, i) => _ProviderTile(
                            submission: filteredItems[i],
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AdminVerificationScreen(
                                  service: widget.service,
                                  submission: filteredItems[i],
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
              ],
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
    final docCount = (s.idFront != null ? 1 : 0) +
        (s.idBack != null ? 1 : 0) +
        (s.selfie != null ? 1 : 0) +
        (s.cv != null ? 1 : 0) +
        s.certificates.length;

    return AppCard(
      key: ValueKey('provider-tile-${s.uid}'),
      onTap: onTap,
      border: Border.all(color: AppColors.borderSubtle),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.brand100,
                    width: 2,
                  ),
                ),
                child: PersonAvatar(name: s.fullName, size: 48),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textStyles.label.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${s.profession.isEmpty ? 'Provider' : s.profession} · '
                      '${s.experienceYears} yr${s.experienceYears == 1 ? '' : 's'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textStyles.bodySmall.copyWith(
                        color: AppColors.ink2,
                      ),
                    ),
                    Text(
                      s.submittedAt == null
                          ? 'Submitted'
                          : 'Submitted ${Formatters.shortDate(s.submittedAt!)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textStyles.caption.copyWith(
                        color: AppColors.ink3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              switch (s.status) {
                VerificationStatus.verified => StatusPill(
                  label: s.providerCode ?? 'Verified',
                  background: AppColors.brand100,
                  color: AppColors.brand700,
                  icon: LucideIcons.badgeCheck,
                ),
                VerificationStatus.rejected => const StatusPill(
                  label: 'Rejected',
                  background: AppColors.errorSoft,
                  color: AppColors.errorText,
                  icon: LucideIcons.circleAlert,
                ),
                _ => const StatusPill(
                  label: 'Review',
                  background: AppColors.accent100,
                  color: AppColors.accent700,
                  icon: LucideIcons.clock,
                ),
              },
              const SizedBox(width: 4),
              const Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: AppColors.ink3,
              ),
            ],
          ),
          if (s.phone.isNotEmpty || docCount > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (s.phone.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.phone, size: 12, color: AppColors.brand700),
                        const SizedBox(width: 4),
                        Text(
                          s.phone,
                          style: context.textStyles.caption.copyWith(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.fileText, size: 12, color: AppColors.ink3),
                      const SizedBox(width: 4),
                      Text(
                        docCount == 0 ? 'No docs' : '$docCount doc${docCount == 1 ? '' : 's'}',
                        style: context.textStyles.caption.copyWith(
                          color: AppColors.ink2,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
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
    this.onNavigateToRatings,
  });

  final AppUser user;
  final AuthService authService;
  final AdminService service;
  final VoidCallback? onNavigateToRatings;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(AppSpacing.screen),
    children: [
      ClipRRect(
        borderRadius: AppRadius.card,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.brand900, AppColors.brand700],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -16,
                bottom: -16,
                child: ExcludeSemantics(
                  child: Icon(
                    LucideIcons.shieldCheck,
                    size: 140,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: PersonAvatar(name: user.name, size: 72),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      user.name,
                      style: context.textStyles.h2.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: context.textStyles.caption.copyWith(
                        color: AppColors.brand100,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            LucideIcons.shieldCheck,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Administrator',
                            style: context.textStyles.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
      const SizedBox(height: AppSpacing.md),
      _RatingsMonitorCard(
        service: service,
        onTap: () {
          if (onNavigateToRatings != null) {
            onNavigateToRatings!();
          } else {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    AdminRatingsScreen(service: service, standalone: true),
              ),
            );
          }
        },
      ),
      const SizedBox(height: AppSpacing.lg),
      LogoutButton(authService: authService),
    ],
  );
}

class _RatingsMonitorCard extends StatelessWidget {
  const _RatingsMonitorCard({required this.service, required this.onTap});
  final AdminService service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AppCard(
    onTap: onTap,
    padding: const EdgeInsets.all(AppSpacing.md),
    border: Border.all(color: AppColors.borderSubtle),
    child: StreamBuilder<List<Professional>>(
      stream: service.watchAllProfessionals(),
      builder: (context, snapshot) {
        final professionals = snapshot.data ?? [];
        final rated = professionals.where((p) => p.rating != null).toList();
        final avgRating = rated.isEmpty
            ? null
            : rated.fold<double>(0, (s, p) => s + p.rating!) / rated.length;
        final totalReviews = professionals.fold<int>(
          0,
          (s, p) => s + p.reviewCount,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.accent100,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(
                    LucideIcons.star,
                    size: 20,
                    color: AppColors.accent700,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ratings & Reviews Monitor',
                        style: context.textStyles.label.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Monitor provider ratings by service category',
                        style: context.textStyles.caption.copyWith(
                          color: AppColors.ink3,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  LucideIcons.chevronRight,
                  size: 20,
                  color: AppColors.ink3,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.sm,
                horizontal: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _Metric(
                    label: 'Avg Rating',
                    value: avgRating == null
                        ? '—'
                        : '${avgRating.toStringAsFixed(1)} ★',
                    color: AppColors.accent700,
                  ),
                  Container(width: 1, height: 28, color: AppColors.borderSubtle),
                  _Metric(
                    label: 'Total Reviews',
                    value: '$totalReviews',
                    color: AppColors.brand700,
                  ),
                  Container(width: 1, height: 28, color: AppColors.borderSubtle),
                  _Metric(
                    label: 'Active Providers',
                    value: '${professionals.length}',
                    color: AppColors.success,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        style: TextStyle(
          color: color,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      Text(
        label,
        style: const TextStyle(
          color: AppColors.ink2,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}

class _CountCard extends StatelessWidget {
  const _CountCard({required this.service, required this.status});
  final AdminService service;
  final VerificationStatus status;

  @override
  Widget build(BuildContext context) {
    final (icon, iconColor, iconBg) = switch (status) {
      VerificationStatus.pending => (
        LucideIcons.clock,
        AppColors.accent700,
        AppColors.accent100,
      ),
      VerificationStatus.verified => (
        LucideIcons.badgeCheck,
        AppColors.brand700,
        AppColors.brand100,
      ),
      VerificationStatus.rejected => (
        LucideIcons.circleAlert,
        AppColors.errorText,
        AppColors.errorSoft,
      ),
      _ => (
        LucideIcons.clock,
        AppColors.ink2,
        AppColors.surfaceAlt,
      ),
    };

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      border: Border.all(color: AppColors.borderSubtle),
      child: StreamBuilder<List<ProviderVerification>>(
        stream: service.watchByStatus(status),
        builder: (context, snapshot) => Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${snapshot.data?.length ?? 0}',
              key: ValueKey('count-${status.name}'),
              style: context.textStyles.h2.copyWith(
                color: AppColors.brand900,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${status.name[0].toUpperCase()}${status.name.substring(1)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textStyles.caption.copyWith(
                color: AppColors.ink2,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
