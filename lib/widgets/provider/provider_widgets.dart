import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/app_localizations_en.dart';
import '../../l10n/l10n_context.dart';
import '../../models/booking.dart';
import '../../models/booking_price.dart';
import '../../screens/provider/provider_theme.dart';
import '../../theme/app_theme.dart';
import '../common/app_buttons.dart';
import '../common/empty_state.dart';
import '../common/status_chip.dart';

String money(double? value) {
  if (value == null) return 'No price yet';
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
  if (date == null) return context.l10n.notScheduled;
  final local = date.toLocal();
  final locale = MaterialLocalizations.of(context);
  return '${locale.formatMediumDate(local)}, ${locale.formatTimeOfDay(TimeOfDay.fromDateTime(local))}';
}

/// A calm message for [error]. Pass [l10n] to show it in the app language;
/// without it the message is English.
String providerError(Object? error, {AppLocalizations? l10n}) {
  final t = l10n ?? AppLocalizationsEn();
  if (error is StateError) return error.message;
  if (error is FirebaseException) {
    return switch (error.code) {
      'permission-denied' => t.errorAccessDenied,
      'unavailable' || 'network-request-failed' => t.errorUnableToConnect,
      'failed-precondition' => t.errorNotAvailableYet,
      _ => t.errorUnableToSave,
    };
  }
  return t.errorUnableToLoad;
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
    margin: const EdgeInsets.only(bottom: AppSpacing.md),
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: color,
      borderRadius: AppRadius.card,
      border: Border.all(
        color: ProviderTheme.border,
        width: AppSizes.borderControl,
      ),
      boxShadow: AppShadows.soft,
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
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.md),
    child: EmptyState(title: title, message: message, icon: icon),
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
          Text(
            providerError(error, l10n: context.l10n),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          AppPrimaryButton(
            label: context.l10n.retry,
            onPressed: onRetry,
            expand: false,
          ),
        ],
      ),
    ),
  );
}

/// A booking status as a [StatusChip]: icon shape, word and color together.
class BookingBadge extends StatelessWidget {
  const BookingBadge({super.key, required this.status});
  final BookingStatus status;

  @override
  Widget build(BuildContext context) => StatusChip(
    type: switch (status) {
      BookingStatus.pending => StatusType.warning,
      BookingStatus.confirmed ||
      BookingStatus.onTheWay ||
      BookingStatus.inProgress => StatusType.info,
      BookingStatus.completed => StatusType.success,
      BookingStatus.declined => StatusType.error,
      BookingStatus.cancelled || BookingStatus.unknown => StatusType.neutral,
    },
    label: status.localizedLabel(context.l10n),
  );
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
  const BookingTile({
    super.key,
    required this.booking,
    required this.onTap,
    this.footer,
  });
  final Booking booking;
  final VoidCallback onTap;

  /// Optional extra line, e.g. the customer's rating on a finished job.
  final Widget? footer;

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
            // Flexible so a long label wraps instead of overflowing at large
            // text sizes.
            Flexible(child: BookingBadge(status: booking.status)),
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
              BookingPrice.forProvider(booking),
              style: const TextStyle(
                color: ProviderTheme.teal,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextButton(
              onPressed: onTap,
              child: Text(
                booking.status == BookingStatus.pending
                    ? context.l10n.viewRequest
                    : context.l10n.viewDetails,
              ),
            ),
          ],
        ),
        ?footer,
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
