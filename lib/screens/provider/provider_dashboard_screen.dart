import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../l10n/l10n_context.dart';
import '../../models/app_user.dart';
import '../../models/booking.dart';
import '../../models/service_category.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/common/app_buttons.dart';
import '../../widgets/common/motion_widgets.dart';
import '../../widgets/provider/provider_widgets.dart';

class ProviderDashboardScreen extends StatelessWidget {
  const ProviderDashboardScreen({
    super.key,
    required this.user,
    required this.bookings,
    required this.onOpen,
    required this.onViewJobs,
  });
  final AppUser user;
  final List<Booking> bookings;
  final ValueChanged<Booking> onOpen;
  final VoidCallback onViewJobs;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final requests = bookings
        .where((b) => b.status == BookingStatus.pending)
        .toList();
    final today = bookings.where((b) {
      final date = b.scheduledAt?.toLocal();
      return (b.status == BookingStatus.confirmed ||
              b.status == BookingStatus.completed) &&
          date != null &&
          date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    }).length;
    final upcoming =
        bookings
            .where(
              (b) =>
                  b.status == BookingStatus.confirmed &&
                  b.scheduledAt != null &&
                  b.scheduledAt!.isAfter(now),
            )
            .toList()
          ..sort((a, b) => a.scheduledAt!.compareTo(b.scheduledAt!));
    final earnings = ProviderEarnings(bookings, now);
    final l10n = context.l10n;
    return ProviderPage(
      children: [
        _Hero(
          greeting: l10n.providerGreeting(user.name),
          tagline: l10n.providerTagline,
        ),
        const SizedBox(height: AppSpacing.md),
        // IntrinsicHeight so the two cards are the same height.
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _StatCard(
                  label: l10n.newRequests,
                  value: '${requests.length}',
                  icon: LucideIcons.bellRing,
                  iconColor: AppColors.accent700,
                  iconBackground: AppColors.accent100,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatCard(
                  label: l10n.todaysJobs,
                  value: '$today',
                  icon: LucideIcons.calendarDays,
                  iconColor: AppColors.brand700,
                  iconBackground: AppColors.brand100,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _EarningsCard(
          label: l10n.monthlyEarnings,
          value: money(earnings.monthlyTotal),
          month: '${Formatters.month(now)} ${now.year}',
        ),
        const SizedBox(height: AppSpacing.lg),
        _SectionTitle(dot: AppColors.brand900, title: l10n.upcomingJob),
        const SizedBox(height: AppSpacing.sm),
        if (upcoming.isEmpty)
          ProviderEmpty(
            title: l10n.noUpcomingTitle,
            message: l10n.noUpcomingMessage,
            icon: Icons.event_available_outlined,
          )
        else
          FadeSlideIn(
            child: _LeadCard(
              booking: upcoming.first,
              onTap: () => onOpen(upcoming.first),
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        // A Wrap so the title and button stack instead of overflowing when
        // the text is long (Sinhala) or large.
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          children: [
            _SectionTitle(dot: AppColors.accent500, title: l10n.newRequests),
            TextButton(
              onPressed: onViewJobs,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.accent700,
                minimumSize: const Size(AppSizes.minTap, AppSizes.minTap),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Flexible so "View all" wraps at large text sizes.
                  Flexible(child: Text(l10n.viewAll)),
                  if (requests.isNotEmpty) Text(' (${requests.length})'),
                  const Icon(LucideIcons.chevronRight, size: 18),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (requests.isEmpty)
          ProviderEmpty(
            title: l10n.noNewRequestsTitle,
            message: l10n.noNewRequestsMessage,
          )
        else
          ...requests
              .take(3)
              .indexed
              .map(
                (r) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: FadeSlideIn(
                    index: r.$1,
                    child: _LeadCard(booking: r.$2, onTap: () => onOpen(r.$2)),
                  ),
                ),
              ),
      ],
    );
  }
}

/// Shared look of the white cards on this screen.
BoxDecoration _cardDecoration() => BoxDecoration(
  color: AppColors.surface,
  borderRadius: AppRadius.card,
  border: Border.all(
    color: AppColors.borderSubtle,
    width: AppSizes.borderControl,
  ),
);

/// The blue welcome banner: greeting and tagline over a soft gradient.
class _Hero extends StatelessWidget {
  const _Hero({required this.greeting, required this.tagline});
  final String greeting, tagline;

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.brand900, AppColors.brand700],
          ),
        ),
        child: Stack(
          children: [
            // A faint shield, only decoration.
            Positioned(
              right: -12,
              bottom: -24,
              child: ExcludeSemantics(
                child: Icon(
                  LucideIcons.shieldCheck,
                  size: 140,
                  color: Colors.white.withValues(alpha: 0.10),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          greeting,
                          style: styles.h2.copyWith(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      const ExcludeSemantics(
                        child: Text('👋', style: TextStyle(fontSize: 24)),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    tagline,
                    style: styles.bodySmall.copyWith(color: AppColors.brand100),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A count with a label and a small icon, like "New requests 1".
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
  });
  final String label, value;
  final IconData icon;
  final Color iconColor, iconBackground;

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(label, style: styles.bodySmall)),
              const SizedBox(width: AppSpacing.xs),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(value, style: styles.h1.copyWith(color: AppColors.brand900)),
        ],
      ),
    );
  }
}

/// This month's earnings, full width, with the month it is for.
class _EarningsCard extends StatelessWidget {
  const _EarningsCard({
    required this.label,
    required this.value,
    required this.month,
  });
  final String label, value, month;

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _cardDecoration(),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: AppSpacing.xs,
        spacing: AppSpacing.sm,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.brand100,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(
                  LucideIcons.wallet,
                  color: AppColors.brand700,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Flexible so a long label or amount wraps on a narrow phone.
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: styles.bodySmall),
                    Text(
                      value,
                      style: styles.amount.copyWith(color: AppColors.brand900),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xxs,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(month, style: styles.caption),
          ),
        ],
      ),
    );
  }
}

/// A small coloured dot and a heading, like "● Upcoming job".
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.dot, required this.title});
  final Color dot;
  final String title;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
      ),
      const SizedBox(width: AppSpacing.xs),
      Flexible(child: Text(title, style: context.textStyles.h3)),
    ],
  );
}

/// One job or request: who and what, when and where, the amount and the
/// button that opens it.
class _LeadCard extends StatelessWidget {
  const _LeadCard({required this.booking, required this.onTap});
  final Booking booking;
  final VoidCallback onTap;

  /// The icon of the service category the job belongs to.
  static IconData _iconFor(String serviceName) {
    final text = ' $serviceName '.toLowerCase();
    for (final category in ServiceCategory.all) {
      if (category.keywords.any(text.contains)) return category.icon;
    }
    return LucideIcons.briefcase;
  }

  @override
  Widget build(BuildContext context) {
    final b = booking;
    final l10n = context.l10n;
    final styles = context.textStyles;
    final isRequest = b.status == BookingStatus.pending;
    final amount = switch (b.totalAmount ?? b.estimatedPrice) {
      final value? => money(value),
      null => l10n.notProvided,
    };
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isRequest ? AppColors.accent100 : AppColors.brand100,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  _iconFor(b.serviceName),
                  color: isRequest ? AppColors.accent700 : AppColors.brand700,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b.serviceName, style: styles.label),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.user,
                          size: 16,
                          color: AppColors.ink3,
                        ),
                        const SizedBox(width: AppSpacing.xxs),
                        Expanded(
                          child: Text(b.customerName, style: styles.caption),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              // Flexible so a long label wraps instead of overflowing at large
              // text sizes.
              Flexible(child: BookingBadge(status: b.status)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      LucideIcons.clock,
                      size: 18,
                      color: AppColors.brand700,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        dateLabel(context, b.scheduledAt),
                        style: styles.label,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      LucideIcons.mapPin,
                      size: 18,
                      color: AppColors.ink3,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(child: Text(b.address, style: styles.caption)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: AppSpacing.xs,
            spacing: AppSpacing.md,
            children: [
              Text(
                amount,
                style: styles.amount.copyWith(color: AppColors.brand900),
              ),
              AppPrimaryButton(
                label: isRequest ? l10n.viewRequest : l10n.viewDetails,
                icon: isRequest
                    ? LucideIcons.externalLink
                    : LucideIcons.arrowRight,
                expand: false,
                onPressed: onTap,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
