import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../models/booking.dart';
import '../../../models/booking_policy.dart';
import '../../../models/booking_price.dart';
import '../../../models/professional.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/booking/booking_widgets.dart';
import '../../../widgets/common/app_widgets.dart';
import '../customer_scope.dart';
import 'booking_cancelled_screen.dart';

class CancelBookingScreen extends StatefulWidget {
  const CancelBookingScreen({
    super.key,
    required this.booking,
    this.professional,
  });

  final Booking booking;
  final Professional? professional;

  @override
  State<CancelBookingScreen> createState() => _CancelBookingScreenState();
}

class _CancelBookingScreenState extends State<CancelBookingScreen> {
  String? _reason;

  Booking get _b => widget.booking;
  String get _proName =>
      widget.professional?.name ?? _b.providerName ?? 'your professional';

  Future<void> _confirm() async {
    final reason = _reason;
    if (reason == null) return;
    final service = CustomerScope.of(context).bookings;
    final now = service.now();
    final refund = BookingPolicy.refundAmount(_b, now);
    final captured = BookingPolicy.hasCapturedPayment(_b);
    final bold = const TextStyle(
      color: AppColors.navy,
      fontWeight: FontWeight.w700,
    );
    final cancelled = await ConfirmationBottomSheet.show(
      context,
      ConfirmationBottomSheet(
        icon: LucideIcons.alertTriangle,
        title: 'Cancel this booking?',
        message: TextSpan(
          children: [
            const TextSpan(text: 'Are you sure you want to cancel booking '),
            TextSpan(text: '#${_b.displayReference}', style: bold),
            const TextSpan(text: ' with '),
            TextSpan(text: _proName, style: bold),
            const TextSpan(text: ' for '),
            TextSpan(text: _b.serviceName, style: bold),
            const TextSpan(
              text: '? This reserved slot cannot be retrieved once released.',
            ),
          ],
        ),
        highlight: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceSage,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            children: [
              const Icon(
                LucideIcons.refreshCw,
                color: AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      captured
                          ? 'Instant refund authorization'
                          : 'No payment has been taken',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.navy,
                      ),
                    ),
                    Text(
                      captured ? Formatters.lkr(refund) : 'Nothing to refund',
                      style: AppTypography.amount.copyWith(fontSize: 18),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        keepLabel: 'Keep My Booking',
        keepIcon: LucideIcons.checkCircle,
        confirmLabel: 'Yes, Cancel Booking',
        confirmIcon: LucideIcons.xCircle,
        footer: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.lock, size: 13, color: AppColors.muted),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                'Protected by HomeCare Shield',
                style: AppTypography.caption,
              ),
            ),
          ],
        ),
        onConfirm: () => service.cancel(_b, reason),
      ),
    );
    if (!cancelled || !mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => BookingCancelledScreen(bookingId: _b.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = CustomerScope.of(context).bookings.now();
    final free = BookingPolicy.isFreeCancellation(_b, now);
    final fee = BookingPolicy.cancellationFee(_b, now);
    final refund = BookingPolicy.refundAmount(_b, now);
    final captured = BookingPolicy.hasCapturedPayment(_b);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const ScreenHeader(title: 'Cancel Booking'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screen,
                  AppSpacing.xs,
                  AppSpacing.screen,
                  AppSpacing.xxl,
                ),
                children: [
                  AppCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconTile(icon: serviceIcon(_b.serviceName)),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'REF #${_b.displayReference}',
                                style: AppTypography.overline,
                              ),
                              Text(_b.serviceName, style: AppTypography.title),
                              Text(
                                '$_proName • ${_b.address}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.caption,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              BookingPrice.amountOr(_b, 'Quote pending'),
                              style: AppTypography.bodyStrong,
                            ),
                            Text(
                              captured ? 'Paid Online' : 'Pay on site',
                              style: AppTypography.caption,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const SectionLabel('Reason for cancellation'),
                  const SizedBox(height: AppSpacing.sm),
                  RadioGroup<String>(
                    groupValue: _reason,
                    onChanged: (value) => setState(() => _reason = value),
                    child: Column(
                      children: [
                        for (final reason in BookingPolicy.cancellationReasons)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.xs,
                            ),
                            child: _ReasonTile(
                              reason: reason,
                              selected: reason == _reason,
                              onTap: () => setState(() => _reason = reason),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppCard(
                    color: free ? AppColors.surfaceSage : AppColors.warningSoft,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          free
                              ? LucideIcons.badgeCheck
                              : LucideIcons.alertTriangle,
                          size: 20,
                          color: free ? AppColors.primary : AppColors.warning,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                free
                                    ? 'Free cancellation'
                                    : 'Late cancellation fee: ${Formatters.lkr(fee)}',
                                style: AppTypography.subtitle,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                free
                                    ? 'You are cancelling more than 2 hours '
                                          'before the start time.'
                                    : 'Cancellations within 2 hours of the '
                                          'start time keep 20% to cover the '
                                          "professional's reserved time.",
                                style: AppTypography.caption,
                              ),
                              if (captured) ...[
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  'Refund to your card: ${Formatters.lkr(refund)}',
                                  style: AppTypography.bodyStrong.copyWith(
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  PrimaryButton(
                    label: 'Cancel Booking',
                    icon: LucideIcons.xCircle,
                    color: AppColors.danger,
                    onPressed: _reason == null ? null : _confirm,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SecondaryButton(
                    label: 'Keep My Booking',
                    onPressed: () => Navigator.of(context).pop(),
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

class _ReasonTile extends StatelessWidget {
  const _ReasonTile({
    required this.reason,
    required this.selected,
    required this.onTap,
  });

  final String reason;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AppCard(
    onTap: onTap,
    border: selected ? Border.all(color: AppColors.primary) : null,
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2),
    child: Row(
      children: [
        Radio<String>(value: reason),
        Expanded(
          child: Text(
            reason,
            style: AppTypography.bodyStrong.copyWith(
              color: selected ? AppColors.navy : AppColors.body,
            ),
          ),
        ),
        if (selected)
          const Padding(
            padding: EdgeInsets.only(right: AppSpacing.sm),
            child: Icon(LucideIcons.check, color: AppColors.primary, size: 18),
          ),
      ],
    ),
  );
}
