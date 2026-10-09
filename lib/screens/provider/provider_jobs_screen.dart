import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/booking.dart';
import '../../models/review.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/app_buttons.dart';
import '../../widgets/common/review_widgets.dart';
import '../../widgets/provider/job_widgets.dart';
import '../../widgets/provider/provider_widgets.dart';

class ProviderJobsScreen extends StatelessWidget {
  const ProviderJobsScreen({
    super.key,
    required this.bookings,
    required this.tab,
    required this.onTab,
    required this.onOpen,
    this.watchReview,
  });
  final List<Booking> bookings;
  final int tab;
  final ValueChanged<int> onTab;
  final ValueChanged<Booking> onOpen;

  /// Streams the customer's review of a job, shown on completed jobs.
  final Stream<Review?> Function(String bookingId)? watchReview;

  @override
  Widget build(BuildContext context) {
    final requests = bookings
        .where((b) => b.status == BookingStatus.pending)
        .length;
    final filtered = bookings
        .where(
          (b) => switch (tab) {
            0 => b.status == BookingStatus.pending,
            1 => b.status == BookingStatus.confirmed,
            _ => b.status.isHistory,
          },
        )
        .toList();
    if (tab == 1) {
      filtered.sort(
        (a, b) => (a.scheduledAt ?? DateTime(9999)).compareTo(
          b.scheduledAt ?? DateTime(9999),
        ),
      );
    }
    final confirmed = tab == 1
        ? filtered.length
        : bookings.where((b) => b.status == BookingStatus.confirmed).length;
    final styles = context.textStyles;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.xs,
            AppSpacing.screen,
            0,
          ),
          child: _TabPills(
            tab: tab,
            onTab: onTab,
            requests: requests,
            confirmed: confirmed,
          ),
        ),
        Expanded(
          child: ProviderPage(
            children: [
              if (tab == 1 && filtered.isNotEmpty)
                _BookedSummary(jobs: filtered),
              if (tab == 2 && filtered.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: AppSpacing.xs,
                    children: [
                      Text('Past Jobs', style: styles.h3),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.brand100,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          '${filtered.length} Total',
                          key: const ValueKey('history-total'),
                          style: styles.caption.copyWith(
                            color: AppColors.brand900,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (filtered.isEmpty)
                ProviderEmpty(
                  title: [
                    'No new job requests',
                    'No confirmed jobs',
                    'No job history yet',
                  ][tab],
                  message: [
                    'New requests assigned to you will appear here.',
                    'Accept a request to add it to your confirmed jobs.',
                    'Completed, declined and cancelled jobs remain here for your records.',
                  ][tab],
                ),
              ...filtered.map(
                (b) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: switch (tab) {
                    0 => _RequestCard(booking: b, onTap: () => onOpen(b)),
                    1 => _ConfirmedCard(booking: b, onTap: () => onOpen(b)),
                    _ => _HistoryCard(
                      booking: b,
                      onTap: () => onOpen(b),
                      footer:
                          b.status == BookingStatus.completed &&
                              watchReview != null
                          ? ReviewRatingLine(
                              prefix: 'Customer rating',
                              stream: watchReview!(b.id),
                            )
                          : null,
                    ),
                  },
                ),
              ),
              if (tab == 2 && filtered.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Column(
                    children: [
                      Container(
                        width: 32,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.brand100,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text('End of recorded history', style: styles.caption),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Requests / Confirmed / History as one pill-shaped switch. The first two
/// show how many jobs are waiting in them.
class _TabPills extends StatelessWidget {
  const _TabPills({
    required this.tab,
    required this.onTab,
    required this.requests,
    required this.confirmed,
  });
  final int tab, requests, confirmed;
  final ValueChanged<int> onTab;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(6),
    decoration: BoxDecoration(
      color: AppColors.surfaceAlt,
      borderRadius: BorderRadius.circular(AppRadius.pill),
    ),
    child: Row(
      children: [
        _Pill(
          index: 0,
          label: 'Requests',
          count: requests,
          selected: tab == 0,
          onTap: onTab,
          badgeColor: AppColors.accent500,
          badgeText: AppColors.ink,
        ),
        _Pill(
          index: 1,
          label: 'Confirmed',
          count: confirmed,
          selected: tab == 1,
          onTap: onTab,
          badgeColor: AppColors.brand700,
          badgeText: Colors.white,
        ),
        _Pill(
          index: 2,
          label: 'History',
          count: 0,
          selected: tab == 2,
          onTap: onTab,
          badgeColor: AppColors.brand700,
          badgeText: Colors.white,
        ),
      ],
    ),
  );
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.index,
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    required this.badgeColor,
    required this.badgeText,
  });
  final int index, count;
  final String label;
  final bool selected;
  final ValueChanged<int> onTap;
  final Color badgeColor, badgeText;

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: count > 0 ? '$label, $count' : label,
        child: InkWell(
          key: ValueKey('jobs-tab-$index'),
          onTap: () => onTap(index),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Container(
            constraints: const BoxConstraints(minHeight: AppSizes.minTap),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            decoration: BoxDecoration(
              color: selected ? AppColors.brand900 : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            alignment: Alignment.center,
            child: ExcludeSemantics(
              // Scale the label down a little instead of cutting it off.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      style: styles.label.copyWith(
                        color: selected ? Colors.white : AppColors.ink2,
                      ),
                    ),
                    if (count > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        key: ValueKey('jobs-count-$index'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          '$count',
                          style: styles.caption.copyWith(
                            color: badgeText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "2 Jobs Booked", the next one and what they add up to.
class _BookedSummary extends StatelessWidget {
  const _BookedSummary({required this.jobs});
  final List<Booking> jobs;

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    final next = jobs.where((b) => b.scheduledAt != null).firstOrNull;
    final priced = jobs.map(jobAmount).whereType<double>();
    final total = priced.fold<double>(0, (sum, value) => sum + value);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.brand50,
        borderRadius: AppRadius.card,
      ),
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
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.brand100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.calendarDays,
                  color: AppColors.brand700,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${jobs.length} ${jobs.length == 1 ? 'Job' : 'Jobs'} Booked',
                      key: const ValueKey('booked-count'),
                      style: styles.label,
                    ),
                    if (next != null)
                      Text(
                        'Next: ${dateLabel(context, next.scheduledAt)}',
                        style: styles.caption,
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (priced.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'TOTAL BOOKED',
                  style: styles.caption.copyWith(
                    color: AppColors.accent700,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  money(total),
                  key: const ValueKey('booked-total'),
                  style: styles.amount.copyWith(color: AppColors.brand900),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// The amount a job is worth with a small caption, or "Not provided".
class _Amount extends StatelessWidget {
  const _Amount({required this.caption, required this.booking});
  final String caption;
  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    final amount = jobAmount(booking);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(caption.toUpperCase(), style: styles.caption),
        if (amount != null)
          Text(
            money(amount),
            style: styles.amount.copyWith(color: AppColors.brand900),
          )
        else
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text('Not provided', style: styles.caption),
          ),
      ],
    );
  }
}

/// A new request: what, who, when and where, the fare and one button.
class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.booking, required this.onTap});
  final Booking booking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final b = booking;
    final styles = context.textStyles;
    final note = jobNoteLine(b);
    final duration = estimatedDuration(b);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: jobCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              JobIconTile(
                icon: serviceIconFor(b.serviceName),
                color: AppColors.accent700,
                background: AppColors.accent100,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b.serviceName, style: styles.label),
                    if (note != null)
                      Text(
                        note,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: styles.caption,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
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
                JobInfoRow(
                  icon: LucideIcons.user,
                  text: b.customerName,
                  strong: true,
                  iconColor: AppColors.ink3,
                ),
                const SizedBox(height: AppSpacing.xs),
                JobInfoRow(
                  icon: LucideIcons.calendarDays,
                  text: dateLabel(context, b.scheduledAt),
                ),
                const SizedBox(height: AppSpacing.xs),
                JobInfoRow(
                  icon: LucideIcons.mapPin,
                  text: b.address,
                  secondary: b.addressArea,
                  iconColor: AppColors.ink3,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.end,
            runSpacing: AppSpacing.xs,
            spacing: AppSpacing.sm,
            children: [
              _Amount(caption: 'Estimated payout', booking: b),
              if (duration != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      LucideIcons.clock,
                      size: 16,
                      color: AppColors.ink3,
                    ),
                    const SizedBox(width: 4),
                    Flexible(child: Text(duration, style: styles.caption)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          AppPrimaryButton(
            key: ValueKey('open-${b.id}'),
            label: 'View request details',
            icon: LucideIcons.arrowRight,
            onPressed: onTap,
          ),
        ],
      ),
    );
  }
}

/// A confirmed job: the customer (with a call button), time, place and fee.
class _ConfirmedCard extends StatelessWidget {
  const _ConfirmedCard({required this.booking, required this.onTap});
  final Booking booking;
  final VoidCallback onTap;

  Future<void> _call(String phone) =>
      launchUrl(Uri(scheme: 'tel', path: phone));

  @override
  Widget build(BuildContext context) {
    final b = booking;
    final styles = context.textStyles;
    final note = jobNoteLine(b);
    final phone = b.contactPhone.trim();
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: jobCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              JobIconTile(icon: serviceIconFor(b.serviceName)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b.serviceName, style: styles.label),
                    if (note != null)
                      Text(
                        note,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: styles.caption,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Flexible(child: BookingBadge(status: b.status)),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Divider(height: 1, color: AppColors.borderSubtle),
          ),
          Row(
            children: [
              InitialsAvatar(
                name: b.customerName,
                size: 32,
                background: AppColors.accent100,
                color: AppColors.accent700,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(child: Text(b.customerName, style: styles.label)),
              if (phone.isNotEmpty)
                IconButton(
                  key: ValueKey('call-${b.id}'),
                  tooltip: 'Call customer',
                  onPressed: () => _call(phone),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.brand100,
                    foregroundColor: AppColors.brand900,
                    minimumSize: const Size(AppSizes.minTap, AppSizes.minTap),
                  ),
                  icon: const Icon(LucideIcons.phone, size: 18),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          JobInfoRow(
            icon: LucideIcons.clock,
            text: dateLabel(context, b.scheduledAt),
            strong: true,
          ),
          const SizedBox(height: AppSpacing.xs),
          JobInfoRow(
            icon: LucideIcons.mapPin,
            text: b.address,
            secondary: b.addressArea,
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: AppSpacing.xs,
            spacing: AppSpacing.md,
            children: [
              _Amount(caption: 'Job amount', booking: b),
              AppPrimaryButton(
                key: ValueKey('open-${b.id}'),
                label: 'View details',
                icon: LucideIcons.chevronRight,
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

/// A finished job (completed, declined or cancelled) kept for the records.
class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.booking, required this.onTap, this.footer});
  final Booking booking;
  final VoidCallback onTap;

  /// Extra line, e.g. the customer's rating on a completed job.
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final b = booking;
    final styles = context.textStyles;
    final note = jobNoteLine(b);
    final done = b.status == BookingStatus.completed;
    final paid = done && b.paymentStatus == 'paid';
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: jobCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InitialsAvatar(
                name: b.customerName,
                background: done ? AppColors.brand100 : AppColors.surfaceAlt,
                color: done ? AppColors.brand900 : AppColors.ink3,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b.serviceName, style: styles.label),
                    Text(b.customerName, style: styles.caption),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Flexible(child: BookingBadge(status: b.status)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          JobInfoRow(
            icon: LucideIcons.calendarDays,
            text: dateLabel(context, b.scheduledAt),
            iconColor: done ? AppColors.brand700 : AppColors.ink3,
          ),
          const SizedBox(height: AppSpacing.xs),
          JobInfoRow(
            icon: LucideIcons.mapPin,
            text: b.address,
            iconColor: done ? AppColors.brand700 : AppColors.ink3,
          ),
          if (note != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.brand50,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                note,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: styles.caption,
              ),
            ),
          ],
          ?footer,
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: AppSpacing.xs,
            spacing: AppSpacing.md,
            children: [
              _Amount(
                caption: paid
                    ? 'Amount paid'
                    : jobAmount(b) == null
                    ? 'Fee status'
                    : 'Job amount',
                booking: b,
              ),
              AppSecondaryButton(
                key: ValueKey('open-${b.id}'),
                label: 'View details',
                icon: LucideIcons.chevronRight,
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
