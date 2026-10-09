import 'package:flutter/material.dart';

import '../../models/booking.dart';
import '../../models/booking_price.dart';
import '../../services/provider_booking_service.dart';
import '../../widgets/provider/provider_widgets.dart';
import 'provider_job_actions.dart';
import 'provider_theme.dart';

class ProviderPaymentScreen extends StatelessWidget {
  const ProviderPaymentScreen({
    super.key,
    required this.booking,
    required this.service,
    required this.onChanged,
  });
  final Booking booking;
  final ProviderBookingService service;
  final ValueChanged<BookingStatus> onChanged;

  @override
  Widget build(BuildContext context) => ProviderPage(
    children: [
      ProviderCard(
        child: Column(
          children: [
            BookingBadge(status: booking.status),
            DetailRow(
              icon: Icons.build_outlined,
              label: 'Service',
              value: booking.serviceName,
            ),
            DetailRow(
              icon: Icons.person_outline,
              label: 'Customer',
              value: booking.customerName,
            ),
            DetailRow(
              icon: Icons.event_outlined,
              label: 'Date & time',
              value: dateLabel(context, booking.scheduledAt),
            ),
          ],
        ),
      ),
      ProviderCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment summary',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            DetailRow(
              icon: Icons.handyman_outlined,
              label: 'Labor charge / provider payout',
              value: booking.approvedAmount == null
                  ? BookingPrice.forProvider(booking)
                  : money(booking.providerPayout ?? booking.approvedAmount),
            ),
            DetailRow(
              icon: Icons.receipt_long_outlined,
              label: 'Service fee',
              value: (booking.serviceFee ?? 0) > 0
                  ? money(booking.serviceFee)
                  : 'No fee',
            ),
            const Divider(),
            DetailRow(
              icon: Icons.payments_outlined,
              label: 'Approved amount',
              value: BookingPrice.amountOr(
                booking,
                BookingPrice.forProvider(booking),
              ),
            ),
            DetailRow(
              icon: Icons.credit_card_outlined,
              label: 'Payment method',
              value: booking.cardLast4 != null
                  ? 'Card ending in •• ${booking.cardLast4}'
                  : booking.paymentMethod?.toLowerCase() == 'cash'
                  ? 'Cash on Service'
                  : booking.paymentMethod ?? 'Pay after the service',
            ),
            DetailRow(
              icon: Icons.info_outline,
              label: 'Payment status',
              value: booking.paymentStatus == 'paid'
                  ? 'Paid (Completed)'
                  : 'Unpaid (Awaiting completion sign-off)',
            ),
          ],
        ),
      ),
      const Text(
        'Marking a job complete records the work as finished. Payment is confirmed separately; only paid jobs contribute to earnings.',
        style: TextStyle(color: ProviderTheme.muted),
      ),
      const SizedBox(height: 20),
      ProviderJobActions(
        booking: booking,
        service: service,
        onChanged: onChanged,
      ),
    ],
  );
}
