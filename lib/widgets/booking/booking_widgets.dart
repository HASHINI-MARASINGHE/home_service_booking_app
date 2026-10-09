import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../models/booking.dart';
import '../../models/booking_price.dart';
import '../../models/professional.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../common/app_widgets.dart';

/// Picks a service icon from the booking's service name.
IconData serviceIcon(String serviceName) {
  final name = serviceName.toLowerCase();
  if (name.contains('ac') || name.contains('air') || name.contains('cool')) {
    return LucideIcons.snowflake;
  }
  if (name.contains('plumb') || name.contains('pipe')) {
    return LucideIcons.wrench;
  }
  if (name.contains('electr')) return LucideIcons.zap;
  if (name.contains('clean') || name.contains('disinfect')) {
    return LucideIcons.sparkles;
  }
  if (name.contains('carpent') || name.contains('furniture')) {
    return LucideIcons.hammer;
  }
  return LucideIcons.home;
}

/// Colors for a booking status pill.
(Color, Color) statusColors(BookingStatus status) => switch (status) {
  BookingStatus.pending => (AppColors.warning, AppColors.warningSoft),
  BookingStatus.confirmed ||
  BookingStatus.onTheWay ||
  BookingStatus.inProgress => (AppColors.primary, AppColors.primarySoft),
  BookingStatus.completed => (AppColors.success, AppColors.successSoft),
  BookingStatus.cancelled ||
  BookingStatus.declined => (AppColors.danger, AppColors.dangerSoft),
  BookingStatus.unknown => (AppColors.muted, AppColors.surfaceLavender),
};

class BookingStatusPill extends StatelessWidget {
  const BookingStatusPill({super.key, required this.status});
  final BookingStatus status;

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = statusColors(status);
    return StatusPill(
      label: status == BookingStatus.pending ? 'Requested' : status.label,
      color: fg,
      background: bg,
      dot: true,
    );
  }
}

/// Requested → Confirmed → On way → Active → Done.
class StatusTimeline extends StatelessWidget {
  const StatusTimeline({super.key, required this.status});
  final BookingStatus status;

  static const steps = ['Requested', 'Confirmed', 'On way', 'Active', 'Done'];

  static int indexOf(BookingStatus status) => switch (status) {
    BookingStatus.pending => 0,
    BookingStatus.confirmed => 1,
    BookingStatus.onTheWay => 2,
    BookingStatus.inProgress => 3,
    BookingStatus.completed => 4,
    _ => -1,
  };

  @override
  Widget build(BuildContext context) {
    final current = indexOf(status);
    return Semantics(
      label: 'Booking progress: ${current < 0 ? status.label : steps[current]}',
      child: Column(
        children: [
          SizedBox(
            height: 30,
            child: Row(
              children: [
                for (var i = 0; i < steps.length; i++) ...[
                  _Node(
                    state: i < current || current == 4
                        ? _NodeState.done
                        : i == current
                        ? _NodeState.current
                        : _NodeState.upcoming,
                  ),
                  if (i < steps.length - 1)
                    Expanded(
                      child: Container(
                        height: 3,
                        color: i < current
                            ? AppColors.primary
                            : AppColors.surfaceLavenderDeep,
                      ),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              for (var i = 0; i < steps.length; i++)
                Expanded(
                  child: Text(
                    steps[i],
                    textAlign: i == 0
                        ? TextAlign.left
                        : i == steps.length - 1
                        ? TextAlign.right
                        : TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                    softWrap: false,
                    style: AppTypography.caption.copyWith(
                      fontSize: 14,
                      color: i <= current ? AppColors.primary : AppColors.muted,
                      fontWeight: i <= current
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _NodeState { done, current, upcoming }

class _Node extends StatelessWidget {
  const _Node({required this.state});
  final _NodeState state;

  @override
  Widget build(BuildContext context) => switch (state) {
    _NodeState.done => Container(
      width: 28,
      height: 28,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.check, size: 16, color: Colors.white),
    ),
    _NodeState.current => Container(
      width: 30,
      height: 30,
      padding: const EdgeInsets.all(3),
      decoration: const BoxDecoration(
        color: AppColors.primarySoft,
        shape: BoxShape.circle,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          LucideIcons.badgeCheck,
          size: 14,
          color: Colors.white,
        ),
      ),
    ),
    _NodeState.upcoming => Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.surfaceLavenderDeep,
        shape: BoxShape.circle,
      ),
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: AppColors.muted,
          shape: BoxShape.circle,
        ),
      ),
    ),
  };
}

/// Assigned professional with rating and call/chat actions.
class ProfessionalCard extends StatelessWidget {
  const ProfessionalCard({
    super.key,
    required this.professional,
    this.onCall,
    this.onChat,
  });

  final Professional professional;
  final VoidCallback? onCall, onChat;

  @override
  Widget build(BuildContext context) {
    final p = professional;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            PersonAvatar(
              name: p.name,
              photoUrl: p.photoUrl,
              size: 60,
              verified: p.verified,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    style: AppTypography.title.copyWith(fontSize: 18),
                  ),
                  if (p.specialty.isNotEmpty)
                    Text(p.specialty, style: AppTypography.body),
                  if (p.providerCode != null)
                    Text(
                      'Provider ID · ${p.providerCode}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (p.rating != null)
                        StatusPill(
                          label: p.rating!.toStringAsFixed(1),
                          icon: Icons.star_rounded,
                          color: AppColors.navy,
                          background: AppColors.surfaceSage,
                        ),
                      Text(
                        p.reviewCount > 0
                            ? '(${p.reviewCount} ${p.reviewCount == 1 ? 'review' : 'reviews'} · '
                                  '${p.completedJobs} jobs)'
                            : '(${p.completedJobs} verified jobs)',
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        if (onCall != null || onChat != null) ...[
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: 'Call ${p.firstName}',
                  icon: LucideIcons.phone,
                  background: AppColors.surfaceSage,
                  onPressed: onCall,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: SecondaryButton(
                  label: 'Chat',
                  icon: LucideIcons.messageSquare,
                  background: AppColors.surfaceSage,
                  onPressed: onChat,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Icon + bold line + optional secondary line.
class DetailRow extends StatelessWidget {
  const DetailRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Icon(icon, size: 19, color: AppColors.primary),
      ),
      const SizedBox(width: AppSpacing.sm),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTypography.bodyStrong),
            if (subtitle != null && subtitle!.isNotEmpty)
              Text(subtitle!, style: AppTypography.caption),
          ],
        ),
      ),
    ],
  );
}

/// Label/amount rows used by the booking payment summary.
class AmountRow extends StatelessWidget {
  const AmountRow({
    super.key,
    required this.label,
    required this.amount,
    this.detail,
    this.strong = false,
  });

  final String label;
  final String? detail;
  final double amount;
  final bool strong;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: strong ? AppTypography.bodyStrong : AppTypography.body,
              ),
              if (detail != null && detail!.isNotEmpty)
                Text(detail!, style: AppTypography.caption),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(Formatters.lkr(amount), style: AppTypography.bodyStrong),
      ],
    ),
  );
}

/// Human-readable payment status for the booking payment box.
(String, String) paymentStatusCopy(Booking b, String proName) =>
    switch (b.paymentStatus) {
      'escrow' => (
        'Payment Status: In Escrow',
        'Funds are held safely and only released to $proName after you sign '
            'off on satisfactory completion.',
      ),
      'paid' => (
        'Payment Status: Paid',
        'Payment settled with $proName after your sign-off.',
      ),
      'refund_pending' => (
        'Payment Status: Refund in progress',
        'Your refund has been initiated. Track it on the cancellation screen.',
      ),
      'refunded' => (
        'Payment Status: Refunded',
        'The full refund has been returned to your original payment method.',
      ),
      _ => (
        'Payment Status: Pay after service',
        'No payment has been taken yet. Pay $proName once the job is done.',
      ),
    };

class PaymentSummaryCard extends StatelessWidget {
  const PaymentSummaryCard({
    super.key,
    required this.booking,
    required this.professionalName,
  });

  final Booking booking;
  final String professionalName;

  @override
  Widget build(BuildContext context) {
    final b = booking;
    final (title, message) = paymentStatusCopy(b, professionalName);
    final completed = b.status == BookingStatus.completed;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(
            'Payment summary',
            trailing: b.cardLast4 == null
                ? null
                : StatusPill(
                    label: 'Card •• ${b.cardLast4}',
                    color: AppColors.body,
                    background: AppColors.surfaceLavender,
                  ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (b.approvedAmount == null && b.lineItems.isEmpty)
            Row(
              children: [
                Expanded(child: Text(b.serviceName, style: AppTypography.body)),
                Text(
                  BookingPrice.forCustomer(b),
                  style: AppTypography.bodyStrong,
                ),
              ],
            )
          else if (b.lineItems.isEmpty)
            AmountRow(label: b.serviceName, amount: b.chargeTotal)
          else
            for (final item in b.lineItems)
              AmountRow(label: item.label, amount: item.amount),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Divider(),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      completed
                          ? 'Total Paid'
                          : b.approvedAmount == null
                          ? 'Total'
                          : 'Approved price',
                      style: AppTypography.title,
                    ),
                    Text(
                      'Inclusive of all local levies',
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
              Text(
                BookingPrice.amountOr(b, 'Quote pending'),
                style: b.approvedAmount == null
                    ? AppTypography.subtitle
                    : AppTypography.amount,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceSage,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const IconTile(
                  icon: LucideIcons.lock,
                  circle: true,
                  size: 34,
                  background: AppColors.surface,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.subtitle.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(message, style: AppTypography.caption),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact booking row for Booking History.
class BookingCard extends StatelessWidget {
  const BookingCard({
    super.key,
    required this.booking,
    required this.onTap,
    this.footer,
  });

  final Booking booking;
  final VoidCallback onTap;

  /// Optional extra line under the price row, e.g. the customer's rating.
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final b = booking;
    final date = Formatters.parseIsoDate(b.slotDate) ?? b.scheduledAt;
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconTile(icon: serviceIcon(b.serviceName)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      b.serviceName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.title,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '#${b.displayReference}'
                      '${b.providerName == null ? '' : ' • ${b.providerName}'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              BookingStatusPill(status: b.status),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (date != null)
            _MetaLine(
              icon: LucideIcons.calendar,
              text: [
                Formatters.longDate(date),
                if (b.startTime != null && b.endTime != null)
                  Formatters.timeRange(b.startTime!, b.endTime!),
              ].join('  •  '),
            ),
          const SizedBox(height: 4),
          _MetaLine(icon: LucideIcons.mapPin, text: b.address),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _PriceChip(booking: b),
                ),
              ),
              Text(
                b.status == BookingStatus.completed
                    ? 'View receipt'
                    : 'View details',
                style: AppTypography.label.copyWith(color: AppColors.primary),
              ),
              const Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: AppColors.primary,
              ),
            ],
          ),
          ?footer,
        ],
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 15, color: AppColors.muted),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.caption,
        ),
      ),
    ],
  );
}

enum TrackerState { done, active, pending }

class TrackerStep {
  const TrackerStep({
    required this.title,
    required this.description,
    required this.state,
    this.trailing,
  });

  final String title, description;
  final TrackerState state;
  final String? trailing;
}

/// Vertical progress list used by the refund Transfer Tracker.
class VerticalTracker extends StatelessWidget {
  const VerticalTracker({super.key, required this.steps});
  final List<TrackerStep> steps;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var i = 0; i < steps.length; i++)
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 28,
                child: Column(
                  children: [
                    _TrackerDot(state: steps[i].state),
                    if (i < steps.length - 1)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: AppColors.surfaceLavenderDeep,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: i < steps.length - 1 ? AppSpacing.lg : 0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              steps[i].title,
                              style: AppTypography.title.copyWith(
                                color: switch (steps[i].state) {
                                  TrackerState.done => AppColors.navy,
                                  TrackerState.active => AppColors.primary,
                                  TrackerState.pending => AppColors.muted,
                                },
                              ),
                            ),
                          ),
                          if (steps[i].trailing != null)
                            Padding(
                              padding: const EdgeInsets.only(
                                left: AppSpacing.xs,
                                top: 2,
                              ),
                              child: Text(
                                steps[i].trailing!,
                                style: AppTypography.caption.copyWith(
                                  color: steps[i].state == TrackerState.active
                                      ? AppColors.primary
                                      : AppColors.muted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(steps[i].description, style: AppTypography.caption),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
    ],
  );
}

class _TrackerDot extends StatelessWidget {
  const _TrackerDot({required this.state});
  final TrackerState state;

  @override
  Widget build(BuildContext context) => switch (state) {
    TrackerState.done => const IconTile(
      icon: Icons.check,
      circle: true,
      size: 26,
      color: Colors.white,
      background: AppColors.primary,
    ),
    TrackerState.active => const IconTile(
      icon: LucideIcons.refreshCw,
      circle: true,
      size: 26,
      background: AppColors.primarySoft,
    ),
    TrackerState.pending => Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      child: Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: AppColors.muted,
          shape: BoxShape.circle,
        ),
      ),
    ),
  };
}

/// The price of a booking as a status chip: "Quote pending", "Quote
/// received: LKR 3,500" or "Confirmed: LKR 3,500". Never "LKR 0".
class _PriceChip extends StatelessWidget {
  const _PriceChip({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final b = booking;
    final (background, color, icon) = b.awaitingCustomer
        ? (AppColors.primarySoft, AppColors.primaryDark, LucideIcons.receipt)
        : b.approvedAmount != null
        ? (AppColors.successSoft, AppColors.success, LucideIcons.lock)
        : b.status.isHistory
        ? (AppColors.surfaceLavender, AppColors.body, LucideIcons.circleSlash)
        : (AppColors.warningSoft, AppColors.warning, LucideIcons.hourglass);
    return StatusPill(
      key: const ValueKey('price-chip'),
      label: BookingPrice.forCustomer(b),
      background: background,
      color: color,
      icon: icon,
    );
  }
}
