import 'package:flutter/material.dart';

import '../../models/booking.dart';
import '../../widgets/provider/provider_widgets.dart';
import 'provider_theme.dart';

class ProviderEarningsScreen extends StatelessWidget {
  const ProviderEarningsScreen({
    super.key,
    required this.bookings,
    required this.onOpen,
  });
  final List<Booking> bookings;
  final ValueChanged<Booking> onOpen;

  @override
  Widget build(BuildContext context) {
    final earnings = ProviderEarnings(bookings, DateTime.now());
    return ProviderPage(
      children: [
        ProviderCard(
          color: ProviderTheme.teal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "This month's earnings",
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 10),
              Text(
                money(earnings.monthlyTotal),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Completed and paid jobs only',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
        ProviderCard(
          child: Column(
            children: [
              DetailRow(
                icon: Icons.task_alt,
                label: 'Completed jobs · all time',
                value: '${earnings.completedCount}',
              ),
              DetailRow(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Total earnings · all time',
                value: money(earnings.total),
              ),
            ],
          ),
        ),
        Text('Recent earnings', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        const Text(
          'Earnings use your labor charge, or total less the service fee, and the job completion date. Unpaid jobs are excluded.',
          style: TextStyle(color: ProviderTheme.muted),
        ),
        const SizedBox(height: 16),
        if (earnings.entries.isEmpty)
          const ProviderEmpty(
            title: 'No earnings yet',
            message: 'Completed jobs with confirmed payment and payout details will appear here.',
            icon: Icons.wallet_outlined,
          ),
        ...earnings.entries.map(
          (b) => ProviderCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  b.serviceName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  dateLabel(context, b.completedAt),
                  style: const TextStyle(color: ProviderTheme.muted),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        money(b.providerPayout),
                        style: const TextStyle(
                          color: ProviderTheme.teal,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => onOpen(b),
                      child: const Text('View details'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
