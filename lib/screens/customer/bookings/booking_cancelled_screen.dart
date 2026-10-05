import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../models/booking.dart';
import '../../../models/professional.dart';
import '../../../models/refund.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/booking/booking_widgets.dart';
import '../../../widgets/common/app_widgets.dart';
import '../customer_scope.dart';

/// Post-cancellation summary with live refund tracking from `refunds/{id}`.
class BookingCancelledScreen extends StatefulWidget {
  const BookingCancelledScreen({super.key, required this.bookingId});
  final String bookingId;

  @override
  State<BookingCancelledScreen> createState() => _BookingCancelledScreenState();
}

class _BookingCancelledScreenState extends State<BookingCancelledScreen> {
  Stream<Booking?>? _booking;
  Stream<Refund?>? _refund;
  Future<Professional?>? _professional;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_booking == null) _subscribe();
  }

  void _subscribe() {
    final service = CustomerScope.of(context).bookings;
    _booking = service.watchBooking(widget.bookingId);
    _refund = service.watchRefund(widget.bookingId);
    _professional = null;
  }

  Future<Professional?> _pro(Booking b) =>
      _professional ??= CustomerScope.of(context).bookings
          .getProfessional(b.providerId)
          .catchError((_) => null);

  void _backToBookings() =>
      CustomerScope.of(context).selectTab(CustomerTab.bookings, reset: true);

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      bottom: false,
      child: Column(
        children: [
          const ScreenHeader(title: 'Booking Cancelled'),
          Expanded(
            child: StreamBuilder<Booking?>(
              stream: _booking,
              builder: (context, booking) {
                if (booking.hasError) {
                  return ErrorState(
                    error: booking.error!,
                    onRetry: () => setState(_subscribe),
                  );
                }
                if (booking.connectionState == ConnectionState.waiting) {
                  return const LoadingState();
                }
                final b = booking.data;
                if (b == null) {
                  return ErrorState(
                    error: StateError('This booking could not be found.'),
                  );
                }
                return StreamBuilder<Refund?>(
                  stream: _refund,
                  builder: (context, refund) => FutureBuilder<Professional?>(
                    future: _pro(b),
                    builder: (context, pro) => _Content(
                      booking: b,
                      refund: refund.data,
                      refundLoading:
                          refund.connectionState == ConnectionState.waiting,
                      refundError: refund.error,
                      professional: pro.data,
                      onBackToBookings: _backToBookings,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

class _Content extends StatelessWidget {
  const _Content({
    required this.booking,
    required this.refund,
    required this.refundLoading,
    required this.refundError,
    required this.professional,
    required this.onBackToBookings,
  });

  final Booking booking;
  final Refund? refund;
  final bool refundLoading;
  final Object? refundError;
  final Professional? professional;
  final VoidCallback onBackToBookings;

  @override
  Widget build(BuildContext context) {
    final b = booking;
    final proName = professional?.name ?? b.providerName ?? 'your professional';
    final bold = const TextStyle(
      color: AppColors.navy,
      fontWeight: FontWeight.w700,
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.xs,
        AppSpacing.screen,
        AppSpacing.xxl,
      ),
      children: [
        const Center(child: _CancelledBadge()),
        const SizedBox(height: AppSpacing.sm),
        const Center(
          child: StatusPill(
            label: 'Cancelled & Released',
            icon: LucideIcons.calendarX,
            color: AppColors.danger,
            background: AppColors.dangerSoft,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          b.status == BookingStatus.cancelled
              ? 'Booking Cancelled'
              : 'Booking ${b.status.label}',
          textAlign: TextAlign.center,
          style: AppTypography.headline,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: 'Your ${b.serviceName} slot with '),
              TextSpan(text: proName, style: bold),
              const TextSpan(
                text: ' has been safely released back to schedule.',
              ),
            ],
          ),
          textAlign: TextAlign.center,
          style: AppTypography.body,
        ),
        const SizedBox(height: AppSpacing.lg),
        if (refundError != null)
          AppCard(child: ErrorState(error: refundError!))
        else if (refundLoading)
          const AppCard(child: LoadingState())
        else if (refund == null)
          _NoRefund(booking: b)
        else ...[
          _RefundDetails(
            refund: refund!,
            booking: b,
            professional: professional,
          ),
          const SizedBox(height: AppSpacing.md),
          _TransferTracker(refund: refund!),
        ],
        const SizedBox(height: AppSpacing.md),
        InfoBanner(
          title: 'HomeCare 24/7 Concierge',
          message:
              'Questions regarding this refund? We are ready to assist you '
              'right now.',
          icon: LucideIcons.headphones,
          iconFilled: false,
          background: AppColors.surfaceLavender,
          trailing: SizedBox(
            width: 72,
            child: FilledButton(
              onPressed: () => launchContact(context, 'tel', homeCareHotline),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.primary,
                minimumSize: const Size(0, 42),
                padding: EdgeInsets.zero,
              ),
              child: const Text('Help'),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceSage,
            borderRadius: AppRadius.card,
          ),
          child: Row(
            children: [
              const Icon(
                LucideIcons.shieldCheck,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: 'HomeCare Buyer Guarantee: ', style: bold),
                      const TextSpan(
                        text:
                            'If funds do not reflect within 5 working days, '
                            'our financial escalation desk investigates '
                            'immediately.',
                      ),
                    ],
                  ),
                  style: AppTypography.caption.copyWith(color: AppColors.body),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        PrimaryButton(
          label: 'Back to Bookings',
          icon: LucideIcons.calendarDays,
          onPressed: onBackToBookings,
        ),
        const SizedBox(height: AppSpacing.sm),
        SecondaryButton(
          label: 'Book Another Service',
          icon: LucideIcons.compass,
          onPressed: () =>
              CustomerScope.of(context)
                  .selectTab(CustomerTab.home, reset: true),
        ),
      ],
    );
  }
}

class _CancelledBadge extends StatelessWidget {
  const _CancelledBadge();

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 96,
    height: 96,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: AppColors.dangerSoft.withValues(alpha: 0.6),
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 60,
          height: 60,
          decoration: const BoxDecoration(
            color: AppColors.dangerSoft,
            shape: BoxShape.circle,
          ),
        ),
        const IconTile(
          icon: LucideIcons.x,
          circle: true,
          size: 36,
          color: Colors.white,
          background: AppColors.danger,
        ),
        const Positioned(
          right: 6,
          bottom: 6,
          child: IconTile(
            icon: Icons.check,
            circle: true,
            size: 26,
            color: Colors.white,
            background: AppColors.primary,
          ),
        ),
      ],
    ),
  );
}

class _NoRefund extends StatelessWidget {
  const _NoRefund({required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(AppSpacing.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(LucideIcons.receipt, size: 18, color: AppColors.primary),
            const SizedBox(width: AppSpacing.xs),
            Text('PAYMENT', style: AppTypography.overline),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text('No refund needed', style: AppTypography.title),
        const SizedBox(height: 4),
        Text(
          'No payment was collected for this booking, so nothing will be '
          'charged and there is nothing to refund.',
          style: AppTypography.body,
        ),
        if ((booking.cancellationFee ?? 0) > 0) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Late cancellation fee due: '
            '${Formatters.lkr(booking.cancellationFee)}',
            style: AppTypography.bodyStrong.copyWith(color: AppColors.warning),
          ),
        ],
      ],
    ),
  );
}

class _RefundDetails extends StatelessWidget {
  const _RefundDetails({
    required this.refund,
    required this.booking,
    required this.professional,
  });

  final Refund refund;
  final Booking booking;
  final Professional? professional;

  @override
  Widget build(BuildContext context) {
    final r = refund;
    final method = r.method.toLowerCase() == 'card' || r.cardLast4 != null
        ? 'Visa Card${r.cardLast4 == null ? '' : ' •• ${r.cardLast4}'}'
        : r.method;
    return ClipRRect(
      borderRadius: AppRadius.card,
      child: AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: AppColors.surfaceLavender,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.refreshCw,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'REFUND DETAILS',
                      style: AppTypography.overline.copyWith(
                        color: AppColors.body,
                      ),
                    ),
                  ),
                  const StatusPill(
                    label: 'Auto-Triggered',
                    color: AppColors.body,
                    background: AppColors.primarySoft,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          'Total Amount Refunded',
                          style: AppTypography.body,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            Formatters.lkr(r.amount),
                            style: AppTypography.headline,
                          ),
                          Text(
                            r.percentage >= 100
                                ? '100% Full Refund'
                                : '${r.percentage}% Refund',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (professional != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLavender,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Row(
                        children: [
                          PersonAvatar(
                            name: professional!.name,
                            photoUrl: professional!.photoUrl,
                            size: 50,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  professional!.name,
                                  style: AppTypography.title,
                                ),
                                Text(
                                  [
                                    professional!.specialty,
                                    professional!.area,
                                  ].where((s) => s.isNotEmpty).join(' • '),
                                  style: AppTypography.caption,
                                ),
                              ],
                            ),
                          ),
                          if (professional!.verified)
                            const Icon(
                              LucideIcons.badgeCheck,
                              color: AppColors.muted,
                            ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  _InfoLine(
                    icon: LucideIcons.creditCard,
                    label: 'Method',
                    value: Text(method, style: AppTypography.bodyStrong),
                  ),
                  _InfoLine(
                    icon: LucideIcons.hash,
                    label: 'Refund Ref',
                    value: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLavenderDeep,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: SelectableText(
                        r.refundReference,
                        style: AppTypography.label.copyWith(
                          fontFamily: 'monospace',
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  _InfoLine(
                    icon: LucideIcons.shield,
                    label: 'Cancellation Fee',
                    value: Text(
                      r.cancellationFee == 0
                          ? 'LKR 0 (Free Cancellation)'
                          : Formatters.lkr(r.cancellationFee),
                      style: AppTypography.bodyStrong.copyWith(
                        color: r.cancellationFee == 0
                            ? AppColors.primary
                            : AppColors.warning,
                      ),
                    ),
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

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Icon(icon, size: 16, color: AppColors.muted),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: AppTypography.body),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Align(alignment: Alignment.centerRight, child: value),
        ),
      ],
    ),
  );
}

class _TransferTracker extends StatelessWidget {
  const _TransferTracker({required this.refund});
  final Refund refund;

  @override
  Widget build(BuildContext context) {
    final r = refund;
    final now = DateTime.now();
    final refunded = r.status == RefundStatus.refunded;
    final failed = r.status == RefundStatus.failed;
    final via = [
      if (r.gateway.isNotEmpty) 'via ${r.gateway} Gateway',
      if (r.bankName.isNotEmpty) 'to ${r.bankName}',
    ].join(' ');
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Transfer Tracker', style: AppTypography.title),
              ),
              StatusPill(
                label: refunded
                    ? 'Completed'
                    : failed
                    ? 'Needs attention'
                    : 'In Progress',
                dot: true,
                color: failed ? AppColors.danger : AppColors.primary,
                background: Colors.transparent,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          VerticalTracker(
            steps: [
              TrackerStep(
                title: 'Cancellation Confirmed',
                description:
                    'Booking removed and refund initiated '
                    'automatically.',
                state: TrackerState.done,
                trailing: r.createdAt == null
                    ? null
                    : Formatters.relativeStamp(r.createdAt!.toLocal(), now),
              ),
              TrackerStep(
                title: failed ? 'Refund Needs Attention' : 'Refund Processing',
                description: failed
                    ? 'The payment gateway rejected the transfer. Our team '
                          'will contact you.'
                    : 'Initiated${via.isEmpty ? '' : ' $via'}.',
                state: refunded ? TrackerState.done : TrackerState.active,
                trailing: refunded ? null : 'Active',
              ),
              TrackerStep(
                title: 'Refunded to Bank',
                description: refunded && r.refundedAt != null
                    ? 'Completed ${Formatters.relativeStamp(r.refundedAt!.toLocal(), now)}.'
                    : 'Estimated 3–5 working days based on your card issuer.',
                state: refunded ? TrackerState.done : TrackerState.pending,
                trailing: refunded ? 'Done' : 'Pending',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
