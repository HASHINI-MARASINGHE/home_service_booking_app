import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../models/booking.dart';
import '../../../models/booking_policy.dart';
import '../../../models/professional.dart';
import '../../../models/review.dart';
import '../../../services/app_error.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/booking/booking_widgets.dart';
import '../../../widgets/booking/payment_method_sheet.dart';
import '../../../widgets/booking/quote_card.dart';
import '../../../widgets/common/app_widgets.dart';
import '../../../widgets/common/review_widgets.dart';
import '../customer_scope.dart';
import 'booking_cancelled_screen.dart';
import 'cancel_booking_screen.dart';
import '../disputes/dispute_screen.dart';
import 'edit_booking_screen.dart';
import 'receipt_screen.dart';
import 'reschedule_booking_screen.dart';
import 'review_screen.dart';

class BookingDetailsScreen extends StatefulWidget {
  const BookingDetailsScreen({super.key, required this.bookingId});
  final String bookingId;

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  Stream<Booking?>? _booking;
  Future<Professional?>? _professional;
  String? _providerId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _booking ??= CustomerScope.of(context).bookings
        .watchBooking(widget.bookingId);
  }

  void _retry() => setState(() {
    _booking = CustomerScope.of(context).bookings
        .watchBooking(widget.bookingId);
    _providerId = null;
  });

  Future<Professional?> _professionalFor(Booking booking) {
    if (_providerId != booking.providerId || _professional == null) {
      _providerId = booking.providerId;
      _professional = CustomerScope.of(context).bookings
          .getProfessional(booking.providerId)
          .catchError((_) => null);
    }
    return _professional!;
  }

  Future<void> _push(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    // A review given meanwhile changes the provider's overall rating.
    if (mounted) setState(() => _professional = null);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      bottom: false,
      child: StreamBuilder<Booking?>(
        stream: _booking,
        builder: (context, snapshot) {
          final booking = snapshot.data;
          final header = ScreenHeader(
            title: 'Booking Details',
            trailing: booking == null
                ? null
                : StatusPill(
                    label: '#${booking.displayReference}',
                    background: AppColors.successSoft,
                    color: AppColors.success,
                  ),
          );
          Widget body;
          if (snapshot.hasError) {
            body = ErrorState(error: snapshot.error!, onRetry: _retry);
          } else if (snapshot.connectionState == ConnectionState.waiting) {
            body = const LoadingState();
          } else if (booking == null) {
            body = ErrorState(
              error: StateError(
                'This booking was not found or is not linked to your account.',
              ),
            );
          } else {
            body = FutureBuilder<Professional?>(
              future: _professionalFor(booking),
              builder: (context, pro) => _Details(
                booking: booking,
                professional: pro.data,
                loadingProfessional:
                    pro.connectionState != ConnectionState.done,
                onPush: _push,
              ),
            );
          }
          return Column(
            children: [
              header,
              Expanded(child: body),
            ],
          );
        },
      ),
    ),
  );
}

class _Details extends StatelessWidget {
  const _Details({
    required this.booking,
    required this.professional,
    required this.loadingProfessional,
    required this.onPush,
  });

  final Booking booking;
  final Professional? professional;
  final bool loadingProfessional;
  final Future<void> Function(Widget) onPush;

  @override
  Widget build(BuildContext context) {
    final b = booking;
    final now = CustomerScope.of(context).bookings.now();
    final proName = professional?.name ?? b.providerName ?? 'your professional';
    final date = Formatters.parseIsoDate(b.slotDate) ?? b.scheduledAt;
    final duration = b.scheduledAt != null && b.endAt != null
        ? b.endAt!.difference(b.scheduledAt!).inMinutes
        : null;
    final open = BookingPolicy.canEdit(b);
    final canReschedule = BookingPolicy.canReschedule(b, now);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.xs,
        AppSpacing.screen,
        AppSpacing.xxl,
      ),
      children: [
        if (b.addressNeedsUpdate && open) ...[
          _AddressWarning(
            onUpdate: () => onPush(EditBookingScreen(booking: b)),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('SERVICE STATUS', style: AppTypography.overline),
                        Text(
                          'Code #${b.displayReference}',
                          style: AppTypography.title.copyWith(fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                  BookingStatusPill(status: b.status),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              if (StatusTimeline.indexOf(b.status) >= 0)
                StatusTimeline(status: b.status)
              else
                Text(
                  b.status == BookingStatus.cancelled
                      ? 'This booking was cancelled'
                            '${b.cancelledAt == null ? '' : ' on ${Formatters.shortDate(b.cancelledAt!)}'}'
                            '${b.cancellationReason == null ? '.' : ' (${b.cancellationReason}).'}'
                      : b.status == BookingStatus.declined
                      ? 'The professional could not take this job. '
                            'No payment was taken.'
                      : 'Status update pending.',
                  style: AppTypography.body,
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionLabel(
                'Assigned professional',
                trailing: professional?.verified == true
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            LucideIcons.badgeCheck,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Verified Pro',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      )
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              if (loadingProfessional)
                const LinearProgressIndicator(minHeight: 2)
              else if (professional == null)
                Text(
                  b.providerName == null
                      ? 'We are assigning a professional to your job.'
                      : b.providerName!,
                  style: AppTypography.bodyStrong,
                )
              else
                ProfessionalCard(
                  professional: professional!,
                  onCall: b.status.isUpcoming
                      ? () => launchContact(context, 'tel', professional!.phone)
                      : null,
                  onChat: b.status.isUpcoming
                      ? () => launchContact(context, 'sms', professional!.phone)
                      : null,
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionLabel(
                'Service summary',
                trailing: b.serviceTier == null
                    ? null
                    : Text(b.serviceTier!, style: AppTypography.caption),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  IconTile(icon: serviceIcon(b.serviceName), size: 48),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(b.serviceName, style: AppTypography.title),
                        if (b.serviceDetail != null)
                          Text(b.serviceDetail!, style: AppTypography.caption),
                      ],
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Divider(),
              ),
              if (date != null) ...[
                DetailRow(
                  icon: LucideIcons.calendar,
                  title: Formatters.longDate(date),
                  subtitle: b.startTime == null || b.endTime == null
                      ? null
                      : '${Formatters.timeRange(b.startTime!, b.endTime!)}'
                            '${duration == null ? '' : ' (Approx. $duration mins)'}',
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              DetailRow(
                icon: LucideIcons.mapPin,
                title: b.address,
                subtitle: b.addressArea,
              ),
              if (b.accessNotes.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(
                        LucideIcons.info,
                        size: 19,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLavender,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Access Instructions',
                              style: AppTypography.label,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '"${b.accessNotes}"',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.body,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (b.photoUrls.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Text('Issue Photos', style: AppTypography.label),
                const SizedBox(height: AppSpacing.xs),
                _PhotoStrip(urls: b.photoUrls),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        QuoteCard(booking: b),
        const SizedBox(height: AppSpacing.md),
        PaymentSummaryCard(
          booking: b,
          professionalName: professional?.firstName ?? proName,
        ),
        if (b.status == BookingStatus.completed)
          StreamBuilder<Review?>(
            stream: CustomerScope.of(context).bookings.watchReview(b.id),
            builder: (context, snapshot) {
              final review = snapshot.data;
              if (review == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: AppCard(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  onTap: () => onPush(ReviewScreen(bookingId: b.id)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionLabel('Your review'),
                      const SizedBox(height: AppSpacing.sm),
                      ReviewBody(review: review),
                    ],
                  ),
                ),
              );
            },
          ),
        const SizedBox(height: AppSpacing.md),
        const HomeCareGuarantee(
          message: '100% Satisfaction or free complimentary rework',
        ),
        const SizedBox(height: AppSpacing.lg),
        ..._actions(context, professional, canReschedule, open, now),
      ],
    );
  }

  List<Widget> _actions(
    BuildContext context,
    Professional? pro,
    bool canReschedule,
    bool open,
    DateTime now,
  ) {
    final b = booking;
    switch (b.status) {
      case BookingStatus.completed:
        final isPaid = b.paymentStatus == 'paid';
        return [
          if (!isPaid) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.brand100.withValues(alpha: 0.5),
                borderRadius: AppRadius.card,
                border: Border.all(color: AppColors.primary, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.checkCircle, color: AppColors.primary),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          'Professional marked work as completed',
                          style: AppTypography.subtitle.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Please verify that the job was done to your satisfaction before confirming payment.',
                    style: AppTypography.caption.copyWith(color: AppColors.body),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  PrimaryButton(
                    label: 'Confirm Job & Pay ${Formatters.lkr(b.chargeTotal)}',
                    icon: LucideIcons.badgeCheck,
                    onPressed: () => _confirmPaymentAndSignOff(context),
                  ),
                ],
              ),
            ),
          ],
          PrimaryButton(
            label: 'View Receipt',
            icon: LucideIcons.receipt,
            onPressed: () => onPush(ReceiptScreen(bookingId: b.id)),
          ),
          const SizedBox(height: AppSpacing.sm),
          StreamBuilder<Review?>(
            stream: CustomerScope.of(context).bookings.watchReview(b.id),
            builder: (context, snapshot) => SecondaryButton(
              label: snapshot.data == null
                  ? 'Rate & Review'
                  : 'View Your Review',
              icon: Icons.star_outline_rounded,
              onPressed: () => onPush(ReviewScreen(bookingId: b.id)),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Opens the dispute form, or the existing dispute's status.
          SecondaryButton(
            key: const ValueKey('report-problem'),
            label: 'Report a Problem / Dispute',
            icon: LucideIcons.triangleAlert,
            foreground: AppColors.danger,
            onPressed: () => onPush(DisputeScreen(bookingId: b.id)),
          ),
        ];
      case BookingStatus.cancelled:
        return [
          PrimaryButton(
            label: 'View Refund Status',
            icon: LucideIcons.refreshCw,
            onPressed: () => onPush(BookingCancelledScreen(bookingId: b.id)),
          ),
        ];
      case BookingStatus.onTheWay || BookingStatus.inProgress:
        return [
          Text(
            'Your professional is on the job. Changes are locked; use Call '
            'or Chat above if you need anything.',
            textAlign: TextAlign.center,
            style: AppTypography.caption,
          ),
        ];
      case BookingStatus.pending || BookingStatus.confirmed:
        return [
          PrimaryButton(
            label: 'Reschedule Booking',
            icon: LucideIcons.clock,
            onPressed: canReschedule
                ? () => _openReschedule(context, pro)
                : null,
          ),
          if (!canReschedule)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                'Online rescheduling closes 2 hours before the start time.',
                textAlign: TextAlign.center,
                style: AppTypography.caption,
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          SecondaryButton(
            label: 'Edit Details',
            icon: LucideIcons.fileEdit,
            onPressed: open
                ? () => onPush(EditBookingScreen(booking: b))
                : null,
          ),
          const SizedBox(height: AppSpacing.xs),
          TextButton(
            onPressed: () =>
                onPush(CancelBookingScreen(booking: b, professional: pro)),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.danger,
              minimumSize: const Size.fromHeight(48),
              textStyle: AppTypography.button,
            ),
            child: const Text('Cancel Booking'),
          ),
        ];
      case BookingStatus.declined || BookingStatus.unknown:
        return const [];
    }
  }

  Future<void> _confirmPaymentAndSignOff(BuildContext context) async {
    final b = booking;
    final choice = await PaymentMethodSelectionSheet.show(
      context,
      amount: b.chargeTotal,
      initialMethod: b.paymentMethod,
      initialCardLast4: b.cardLast4,
    );
    if (choice == null || !context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Confirm Service Satisfaction & Payment'),
        content: Text(
          choice.method == 'cash'
              ? 'Are you satisfied with the work and have you paid ${Formatters.lkr(b.chargeTotal)} in cash directly to your provider?'
              : 'Are you satisfied with the work and authorize releasing ${Formatters.lkr(b.chargeTotal)} from your card ending in ${choice.cardLast4 ?? "card"}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Not Yet'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Confirm & Pay'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final service = CustomerScope.of(context).bookings;
      await service.confirmPayment(
        b.id,
        paymentMethod: choice.method,
        cardLast4: choice.cardLast4,
      );
      if (!context.mounted) return;
      showAppSnack(
        context,
        choice.method == 'cash'
            ? 'Cash payment recorded. Thank you!'
            : 'Payment authorized and receipt issued. Thank you!',
      );
    } catch (error) {
      if (!context.mounted) return;
      showAppSnack(context, AppError.message(error), error: true);
    }
  }

  Future<void> _openReschedule(BuildContext context, Professional? pro) async {
    if (pro == null) {
      showAppSnack(
        context,
        AppError.message(
          StateError('Professional availability is unavailable right now.'),
        ),
        error: true,
      );
      return;
    }
    await onPush(RescheduleBookingScreen(booking: booking, professional: pro));
  }
}

class _AddressWarning extends StatelessWidget {
  const _AddressWarning({required this.onUpdate});
  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.warningSoft,
      borderRadius: AppRadius.card,
      border: Border.all(color: AppColors.warningBorder),
    ),
    child: Row(
      children: [
        const Icon(LucideIcons.mapPinOff, color: AppColors.warning, size: 20),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            'The saved address for this booking was deleted. Confirm the '
            'service location so your pro knows where to go.',
            style: AppTypography.caption.copyWith(color: AppColors.body),
          ),
        ),
        TextButton(onPressed: onUpdate, child: const Text('Update')),
      ],
    ),
  );
}

/// Thumbnails of the customer's issue photos (Cloudinary or any https URL).
class _PhotoStrip extends StatelessWidget {
  const _PhotoStrip({required this.urls});
  final List<String> urls;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 76,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: urls.length,
      separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
      itemBuilder: (context, i) => ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Image.network(
          urls[i],
          width: 76,
          height: 76,
          fit: BoxFit.cover,
          semanticLabel: 'Issue photo ${i + 1}',
          loadingBuilder: (context, child, progress) => progress == null
              ? child
              : const ColoredBox(
                  color: AppColors.surfaceLavender,
                  child: SizedBox(width: 76, height: 76),
                ),
          errorBuilder: (_, _, _) => Container(
            width: 76,
            height: 76,
            color: AppColors.surfaceLavender,
            child: const Icon(LucideIcons.imageOff, color: AppColors.muted),
          ),
        ),
      ),
    ),
  );
}
