import 'package:flutter/material.dart';

import '../../models/booking.dart';
import '../../services/provider_booking_service.dart';
import '../../widgets/provider/provider_widgets.dart';
import 'provider_theme.dart';

class ProviderJobActions extends StatefulWidget {
  const ProviderJobActions({
    super.key,
    required this.booking,
    required this.service,
    required this.onChanged,
    this.allowComplete = true,
  });
  final Booking booking;
  final bool allowComplete;
  final ProviderBookingService service;
  final ValueChanged<BookingStatus> onChanged;

  @override
  State<ProviderJobActions> createState() => _ProviderJobActionsState();
}

class _ProviderJobActionsState extends State<ProviderJobActions> {
  bool _busy = false;

  Future<void> _act(BookingStatus target) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (target == BookingStatus.declined ||
          target == BookingStatus.completed) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              target == BookingStatus.declined
                  ? 'Decline this job request?'
                  : 'Mark this job complete?',
            ),
            content: Text(
              target == BookingStatus.declined
                  ? 'The request will remain in your history.'
                  : 'Confirm that the work is finished. This does not mark the payment as paid.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  target == BookingStatus.declined
                      ? 'Confirm Decline'
                      : 'Mark Complete',
                ),
              ),
            ],
          ),
        );
        if (confirmed != true || !mounted) return;
      }
      switch (target) {
        case BookingStatus.confirmed:
          await widget.service.accept(widget.booking.id);
        case BookingStatus.declined:
          await widget.service.decline(widget.booking.id);
        case BookingStatus.completed:
          await widget.service.complete(widget.booking.id);
        default:
          throw StateError('Unsupported action.');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            target == BookingStatus.confirmed
                ? 'Job accepted.'
                : target == BookingStatus.declined
                ? 'Job request declined.'
                : 'Job marked complete.',
          ),
        ),
      );
      widget.onChanged(target);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(providerError(error))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_busy) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (widget.booking.status == BookingStatus.pending) {
      final decline = OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: ProviderTheme.red,
          side: BorderSide(color: ProviderTheme.red.withValues(alpha: 0.3)),
        ),
        onPressed: () => _act(BookingStatus.declined),
        child: const Text('Decline'),
      );
      // New requests are confirmed when the customer accepts the quote, so
      // only requests made before quotes existed can be accepted directly.
      if (!widget.booking.canAcceptWithoutQuote) {
        return SizedBox(width: double.infinity, child: decline);
      }
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: ProviderTheme.red,
                side: BorderSide(
                  color: ProviderTheme.red.withValues(alpha: 0.3),
                ),
              ),
              onPressed: () => _act(BookingStatus.declined),
              child: const Text('Decline'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: ProviderTheme.green,
              ),
              onPressed: widget.booking.isExpired(DateTime.now())
                  ? null
                  : () => _act(BookingStatus.confirmed),
              child: const Text('Accept'),
            ),
          ),
        ],
      );
    }
    if (widget.allowComplete &&
        widget.booking.status == BookingStatus.confirmed) {
      final blocker = widget.booking.completionBlocker;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: ProviderTheme.green),
            onPressed: blocker == null
                ? () => _act(BookingStatus.completed)
                : null,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Mark Job Complete'),
          ),
          if (blocker != null) ...[
            const SizedBox(height: 8),
            Text(
              blocker,
              key: const ValueKey('complete-blocked'),
              style: const TextStyle(color: ProviderTheme.orange),
            ),
          ],
        ],
      );
    }
    return const SizedBox.shrink();
  }
}
