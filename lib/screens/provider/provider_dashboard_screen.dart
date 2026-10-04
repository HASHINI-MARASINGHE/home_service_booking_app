import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../models/booking.dart';
import '../../widgets/provider/provider_widgets.dart';
import 'provider_theme.dart';

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
    return ProviderPage(
      children: [
        Text(
          'Hello, ${user.name}',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 6),
        const Text(
          'Your work, all in one place.',
          style: TextStyle(color: ProviderTheme.muted),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _Stat(
                label: 'New requests',
                value: '${requests.length}',
                icon: Icons.notifications_none,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Stat(
                label: "Today's jobs",
                value: '$today',
                icon: Icons.calendar_today_outlined,
              ),
            ),
          ],
        ),
        _Stat(
          label: 'Monthly earnings',
          value: money(earnings.monthlyTotal),
          icon: Icons.account_balance_wallet_outlined,
        ),
        const SizedBox(height: 10),
        Text('Upcoming job', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        if (upcoming.isEmpty)
          const ProviderEmpty(
            title: 'No upcoming jobs yet',
            message: 'Accepted jobs scheduled in the future will appear here.',
            icon: Icons.event_available_outlined,
          )
        else
          BookingTile(
            booking: upcoming.first,
            onTap: () => onOpen(upcoming.first),
          ),
        Row(
          children: [
            Expanded(
              child: Text(
                'New requests',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            TextButton(onPressed: onViewJobs, child: const Text('View all')),
          ],
        ),
        if (requests.isEmpty)
          const ProviderEmpty(
            title: 'No new job requests',
            message: 'Requests will appear here when a customer books your services.',
          )
        else
          ...requests
              .take(3)
              .map((b) => BookingTile(booking: b, onTap: () => onOpen(b))),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.icon});
  final String label, value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => ProviderCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: ProviderTheme.teal),
        const SizedBox(height: 12),
        Text(value, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: ProviderTheme.muted)),
      ],
    ),
  );
}
