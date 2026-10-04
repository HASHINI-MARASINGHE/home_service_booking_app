import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/booking.dart';
import '../../services/provider_booking_service.dart';
import '../../widgets/provider/provider_widgets.dart';
import 'provider_job_actions.dart';
import 'provider_theme.dart';

class ProviderJobDetailsScreen extends StatefulWidget {
  const ProviderJobDetailsScreen({
    super.key,
    required this.booking,
    required this.service,
    required this.onChanged,
    required this.onPayment,
  });
  final Booking booking;
  final ProviderBookingService service;
  final ValueChanged<BookingStatus> onChanged;
  final VoidCallback onPayment;

  @override
  State<ProviderJobDetailsScreen> createState() =>
      _ProviderJobDetailsScreenState();
}

class _ProviderJobDetailsScreenState extends State<ProviderJobDetailsScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (widget.booking.status == BookingStatus.pending &&
          widget.booking.expiresAt != null) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final pending = b.status == BookingStatus.pending;
    final expired = b.isExpired(DateTime.now());
    final remaining = b.expiresAt?.difference(DateTime.now());
    String time = 'Awaiting response';
    if (remaining != null) {
      final seconds = remaining.inSeconds.clamp(0, 999999999);
      time =
          '${(seconds ~/ 3600).toString().padLeft(2, '0')}:${((seconds ~/ 60) % 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
    }
    return ProviderPage(
      children: [
        if (pending) ...[
          Text(
            'New Job Request',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
        ],
        if (pending)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ProviderTheme.warningBackground,
              border: Border.all(color: ProviderTheme.orangeBorder),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.schedule, color: ProviderTheme.orange),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expired
                            ? 'Response window ended'
                            : b.expiresAt == null
                            ? 'A new opportunity'
                            : 'Respond before it expires',
                        style: const TextStyle(
                          color: ProviderTheme.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        expired
                            ? 'This request can no longer be accepted.'
                            : 'Review the job details before responding.',
                        style: const TextStyle(color: ProviderTheme.orange),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        time,
                        style: const TextStyle(
                          color: ProviderTheme.orange,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ProviderCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Job details',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  BookingBadge(status: b.status),
                ],
              ),
              const SizedBox(height: 6),
              DetailRow(
                icon: Icons.build_outlined,
                label: 'Job type',
                value: b.serviceName,
              ),
              const Divider(height: 1),
              DetailRow(
                icon: Icons.location_on_outlined,
                label: 'Location',
                value: b.address,
              ),
              const Divider(height: 1),
              DetailRow(
                icon: Icons.calendar_today_outlined,
                label: 'Date & time',
                value: dateLabel(context, b.scheduledAt),
              ),
              if (!pending) ...[
                const Divider(height: 1),
                DetailRow(
                  icon: Icons.person_outline,
                  label: 'Customer',
                  value: b.customerName,
                ),
              ],
            ],
          ),
        ),
        ProviderCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pending ? 'Estimated payout' : 'Job amount',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ProviderTheme.teal,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Customer-approved / estimated amount',
                      style: TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      money(b.estimatedPrice ?? b.totalAmount),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (b.payoutNote != null &&
                        b.payoutNote!.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        b.payoutNote!,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ],
                ),
              ),
              if (b.serviceFee != null) ...[
                const SizedBox(height: 10),
                Text(
                  'Service fee: ${money(b.serviceFee)}',
                  style: const TextStyle(color: ProviderTheme.muted),
                ),
              ],
              if (b.providerPayout != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Provider payout: ${money(b.providerPayout)}',
                  style: const TextStyle(color: ProviderTheme.teal),
                ),
              ],
            ],
          ),
        ),
        // Keep the action widget mounted during the transaction's realtime update.
        ProviderJobActions(
          key: const ValueKey('job-actions'),
          booking: b,
          service: widget.service,
          onChanged: widget.onChanged,
          allowComplete: false,
        ),
        if (b.status == BookingStatus.confirmed) ...[
          const SizedBox(height: 12),
          FilledButton(
            onPressed: widget.onPayment,
            child: const Text('Job completion / payment'),
          ),
        ],
        if (b.status.isHistory) ...[
          ProviderCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Payment: ${b.paymentStatus ?? 'Not provided'}'),
                const SizedBox(height: 8),
                Text('Method: ${b.paymentMethod ?? 'Not provided'}'),
                if (b.completedAt != null) ...[
                  const SizedBox(height: 8),
                  Text('Completed: ${dateLabel(context, b.completedAt)}'),
                ],
                if (b.declinedAt != null) ...[
                  const SizedBox(height: 8),
                  Text('Declined: ${dateLabel(context, b.declinedAt)}'),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
