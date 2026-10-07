import 'package:flutter/material.dart';

import '../../../models/professional.dart';
import '../../../theme/customer_home_theme.dart';
import '../bookings/booking_details_screen.dart';
import 'book_service_screen.dart';

/// "Book Now" on the provider profile: opens Book Service (service, date,
/// time and location). [serviceName] preselects one of the provider's
/// services. `Navigator.of(context)` keeps the page inside the Home tab so
/// the bottom navigation stays visible.
Future<void> openBookingFlow(
  BuildContext context,
  Professional provider, {
  String? serviceName,
}) => Navigator.of(context).push(
  MaterialPageRoute(
    builder: (_) => Material(
      child: BookServiceScreen(
        professional: provider,
        serviceName: serviceName,
      ),
    ),
  ),
);

/// Called after "Confirm Booking" saved the request as `bookings/[bookingId]`.
///
/// Next-step team (payment / confirmation page): replace the body with a
/// push to your screen, e.g. `Navigator.of(context).pushReplacement(
/// MaterialPageRoute(builder: (_) => YourScreen(bookingId: bookingId)))`.
/// Until then it opens the existing booking details page.
Future<void> onBookingCreated(BuildContext context, String bookingId) async {
  await showDialog<void>(
    context: context,
    builder: (dialog) => AlertDialog(
      icon: const Icon(
        Icons.check_circle_rounded,
        color: CustomerHomeTheme.primary,
        size: 56,
      ),
      title: const Text('Booking request sent', textAlign: TextAlign.center),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What happens next',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 8),
          Text('1. The provider reviews your request.'),
          SizedBox(height: 4),
          Text('2. You can follow the status under Bookings.'),
          SizedBox(height: 4),
          Text('3. Pay the provider after the service is done.'),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(dialog).pop(),
          style: FilledButton.styleFrom(
            backgroundColor: CustomerHomeTheme.primary,
            minimumSize: const Size(200, 48),
          ),
          child: const Text('View my booking'),
        ),
      ],
    ),
  );
  if (!context.mounted) return;
  await Navigator.of(context).pushReplacement(
    MaterialPageRoute(
      builder: (_) =>
          Material(child: BookingDetailsScreen(bookingId: bookingId)),
    ),
  );
}
