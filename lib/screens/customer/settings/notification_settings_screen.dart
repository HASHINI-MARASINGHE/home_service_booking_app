import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/customer_home_theme.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  static const _kBookingUpdates = 'notif_booking_updates';
  static const _kProviderArrival = 'notif_provider_arrival';
  static const _kBookingReminders = 'notif_booking_reminders';
  static const _kPaymentNotifications = 'notif_payment_notifications';
  static const _kPromotionsOffers = 'notif_promotions_offers';

  bool _bookingUpdates = true;
  bool _providerArrival = true;
  bool _bookingReminders = true;
  bool _paymentNotifications = true;
  bool _promotionsOffers = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _bookingUpdates = prefs.getBool(_kBookingUpdates) ?? true;
        _providerArrival = prefs.getBool(_kProviderArrival) ?? true;
        _bookingReminders = prefs.getBool(_kBookingReminders) ?? true;
        _paymentNotifications = prefs.getBool(_kPaymentNotifications) ?? true;
        _promotionsOffers = prefs.getBool(_kPromotionsOffers) ?? false;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveSetting(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomerHomeTheme.background,
      appBar: AppBar(
        backgroundColor: CustomerHomeTheme.background,
        foregroundColor: CustomerHomeTheme.primaryDark,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screen,
                  vertical: AppSpacing.lg,
                ),
                children: [
                  const Text(
                    'Notification preferences',
                    style: TextStyle(
                      color: CustomerHomeTheme.primaryDark,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Choose the types of updates and alerts you wish to receive.',
                    style: TextStyle(
                      color: CustomerHomeTheme.mutedText,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: CustomerHomeTheme.border),
                      boxShadow: const [
                        BoxShadow(
                          color: CustomerHomeTheme.shadow,
                          blurRadius: 18,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _NotificationSwitchTile(
                          icon: Icons.assignment_outlined,
                          title: 'Booking updates',
                          subtitle:
                              'Get notified when your booking status changes or request is accepted.',
                          value: _bookingUpdates,
                          onChanged: (val) {
                            setState(() => _bookingUpdates = val);
                            _saveSetting(_kBookingUpdates, val);
                          },
                        ),
                        const Divider(
                          height: 1,
                          indent: 64,
                          color: CustomerHomeTheme.border,
                        ),
                        _NotificationSwitchTile(
                          icon: Icons.navigation_outlined,
                          title: 'Service provider arrival updates',
                          subtitle:
                              'Live updates when your provider is on the way or has reached your home.',
                          value: _providerArrival,
                          onChanged: (val) {
                            setState(() => _providerArrival = val);
                            _saveSetting(_kProviderArrival, val);
                          },
                        ),
                        const Divider(
                          height: 1,
                          indent: 64,
                          color: CustomerHomeTheme.border,
                        ),
                        _NotificationSwitchTile(
                          icon: Icons.alarm_outlined,
                          title: 'Booking reminders',
                          subtitle:
                              'Reminders before scheduled home appointments.',
                          value: _bookingReminders,
                          onChanged: (val) {
                            setState(() => _bookingReminders = val);
                            _saveSetting(_kBookingReminders, val);
                          },
                        ),
                        const Divider(
                          height: 1,
                          indent: 64,
                          color: CustomerHomeTheme.border,
                        ),
                        _NotificationSwitchTile(
                          icon: Icons.receipt_long_outlined,
                          title: 'Payment notifications',
                          subtitle:
                              'Invoices, receipts, and refund alerts upon service completion.',
                          value: _paymentNotifications,
                          onChanged: (val) {
                            setState(() => _paymentNotifications = val);
                            _saveSetting(_kPaymentNotifications, val);
                          },
                        ),
                        const Divider(
                          height: 1,
                          indent: 64,
                          color: CustomerHomeTheme.border,
                        ),
                        _NotificationSwitchTile(
                          icon: Icons.local_offer_outlined,
                          title: 'Promotions & offers',
                          subtitle:
                              'Discounts, seasonal maintenance deals, and promotional campaigns.',
                          value: _promotionsOffers,
                          onChanged: (val) {
                            setState(() => _promotionsOffers = val);
                            _saveSetting(_kPromotionsOffers, val);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _NotificationSwitchTile extends StatelessWidget {
  const _NotificationSwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: CustomerHomeTheme.mint,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: CustomerHomeTheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: CustomerHomeTheme.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: CustomerHomeTheme.mutedText,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: value,
            activeTrackColor: AppColors.brand700,
            activeThumbColor: Colors.white,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
