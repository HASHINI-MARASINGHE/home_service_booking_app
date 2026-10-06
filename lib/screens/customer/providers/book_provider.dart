import 'package:flutter/material.dart';

import '../../../models/professional.dart';
import '../../../widgets/common/app_widgets.dart';
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
  showAppSnack(context, 'Booking request sent to the provider.');
  await Navigator.of(context).pushReplacement(
    MaterialPageRoute(
      builder: (_) =>
          Material(child: BookingDetailsScreen(bookingId: bookingId)),
    ),
  );
}
