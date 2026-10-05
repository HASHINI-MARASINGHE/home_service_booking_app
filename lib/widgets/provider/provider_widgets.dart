import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../models/booking.dart';
import '../../screens/provider/provider_theme.dart';

String money(double? value) {
  if (value == null) return 'Not provided';
  final parts = value
      .toStringAsFixed(value == value.roundToDouble() ? 0 : 2)
      .split('.');
  final digits = parts.first.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]},',
  );
  return 'LKR $digits${parts.length > 1 ? '.${parts.last}' : ''}';
}

String dateLabel(BuildContext context, DateTime? date) {
  if (date == null) return 'Not scheduled';
  final local = date.toLocal();
  final locale = MaterialLocalizations.of(context);
  return '${locale.formatMediumDate(local)}, ${locale.formatTimeOfDay(TimeOfDay.fromDateTime(local))}';
}

String providerError(Object? error) {
  if (error is StateError) return error.message;
  if (error is FirebaseException) {
    return switch (error.code) {
      'permission-denied' => 'Access was denied. Please contact support.',
      'unavailable' || 'network-request-failed' =>
        'Unable to connect. Check your connection and retry.',
      'failed-precondition' =>
        'This data is not available yet. Please contact support.',
      _ => 'Unable to save or load your data. Please try again.',
    };
  }
  return 'Unable to load your data. Please try again.';
}

class ProviderCard extends StatelessWidget {
  const ProviderCard({
    super.key,
    required this.child,
    this.color = ProviderTheme.surface,
  });
  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: ProviderTheme.border),
      boxShadow: const [
        BoxShadow(
          color: Color(0x060F172A),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: child,
  );
}

class ProviderEmpty extends StatelessWidget {
  const ProviderEmpty({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
  });
  final String title, message;
  final IconData icon;

  @override
  Widget build(BuildContext context) => ProviderCard(
    child: Column(
      children: [
        Icon(icon, size: 36, color: ProviderTheme.teal),
        const SizedBox(height: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: ProviderTheme.muted),
        ),
      ],
    ),
  );
}

class ProviderFailure extends StatelessWidget {
  const ProviderFailure({
    super.key,
    required this.error,
    required this.onRetry,
  });
  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 40,
            color: ProviderTheme.muted,
          ),
          const SizedBox(height: 12),
          Text(providerError(error), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    ),
  );
}

class BookingBadge extends StatelessWidget {
  const BookingBadge({super.key, required this.status});
  final BookingStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      BookingStatus.pending => ProviderTheme.teal,
      BookingStatus.confirmed || BookingStatus.completed => ProviderTheme.green,
      BookingStatus.declined => ProviderTheme.red,
      _ => ProviderTheme.grey,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class DetailRow extends StatelessWidget {
  const DetailRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label, value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: ProviderTheme.tealLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 22, color: ProviderTheme.teal),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  color: ProviderTheme.navy,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class BookingTile extends StatelessWidget {
  const BookingTile({super.key, required this.booking, required this.onTap});
  final Booking booking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ProviderCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                booking.serviceName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(width: 8),
            BookingBadge(status: booking.status),
          ],
        ),
        const SizedBox(height: 10),
        Text(booking.customerName),
        const SizedBox(height: 4),
        Text(
          dateLabel(context, booking.scheduledAt),
          style: const TextStyle(color: ProviderTheme.muted),
        ),
        const SizedBox(height: 4),
        Text(
          booking.address,
          style: const TextStyle(color: ProviderTheme.muted),
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          children: [
            Text(
              money(booking.totalAmount ?? booking.estimatedPrice),
              style: const TextStyle(
                color: ProviderTheme.teal,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextButton(
              onPressed: onTap,
              child: Text(
                booking.status == BookingStatus.pending
                    ? 'View request'
                    : 'View details',
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class ProviderPage extends StatelessWidget {
  const ProviderPage({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    ),
  );
}
