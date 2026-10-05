import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/app_user.dart';
import '../../services/address_service.dart';
import '../../services/customer_booking_service.dart';
import '../../services/location_service.dart';
import '../../services/receipt_pdf_service.dart';
import '../../widgets/common/app_widgets.dart';

abstract final class CustomerTab {
  static const home = 0;
  static const bookings = 1;
  static const saved = 2;
  static const profile = 3;
}

/// Gives every customer screen its repositories and shell navigation
/// without threading them through constructors (and lets tests inject fakes).
class CustomerScope extends InheritedWidget {
  const CustomerScope({
    super.key,
    required this.user,
    required this.addresses,
    required this.bookings,
    required this.location,
    required this.receipts,
    required this.selectTab,
    required super.child,
  });

  final AppUser user;
  final AddressService addresses;
  final CustomerBookingService bookings;
  final LocationService location;
  final ReceiptPdfService receipts;

  /// Switches bottom-navigation tab; `reset` pops that tab to its root.
  final void Function(int tab, {bool reset}) selectTab;

  static CustomerScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<CustomerScope>();
    assert(scope != null, 'CustomerScope missing above $context');
    return scope!;
  }

  @override
  bool updateShouldNotify(CustomerScope oldWidget) =>
      user != oldWidget.user ||
      addresses != oldWidget.addresses ||
      bookings != oldWidget.bookings;
}

/// Opens the dialer / messaging app, with friendly feedback on failure.
Future<void> launchContact(
  BuildContext context,
  String scheme,
  String number,
) async {
  final digits = number.replaceAll(RegExp(r'[^\d+]'), '');
  if (digits.isEmpty) {
    showAppSnack(context, 'No phone number is available.', error: true);
    return;
  }
  final ok = await launchUrl(Uri(scheme: scheme, path: digits));
  if (!ok && context.mounted) {
    showAppSnack(context, 'Could not open the $scheme app.', error: true);
  }
}

const homeCareHotline = '1344';
