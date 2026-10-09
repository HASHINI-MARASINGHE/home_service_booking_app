import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_context.dart';
import '../../models/app_user.dart';
import '../../models/app_notification.dart';
import '../../models/booking.dart';
import '../../models/provider_verification.dart';
import '../../services/auth_service.dart';
import '../../services/provider_booking_service.dart';
import '../../services/provider_notification_service.dart';
import '../../services/provider_profile_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/locale_typography.dart';
import '../../widgets/common/app_bottom_nav.dart';
import '../../widgets/provider/provider_widgets.dart';
import 'provider_dashboard_screen.dart';
import 'provider_dispute_screen.dart';
import 'provider_earnings_screen.dart';
import 'provider_job_details_screen.dart';
import 'provider_jobs_screen.dart';
import 'provider_notifications_screen.dart';
import 'provider_payment_screen.dart';
import 'provider_profile_screen.dart';
import 'provider_theme.dart';
import '../../widgets/common/homecare_logo.dart';

// Provider-only shell; future mode switching can wrap this without changing it.
class ProviderHomeScreen extends StatefulWidget {
  const ProviderHomeScreen({
    super.key,
    required this.user,
    required this.authService,
    this.verification,
  });
  final AppUser user;
  final AuthService authService;

  /// The approved verification (this shell is only shown to verified
  /// providers), used for the Provider ID on the profile.
  final ProviderVerification? verification;
  @override
  State<ProviderHomeScreen> createState() => _ProviderHomeScreenState();
}

class _ProviderHomeScreenState extends State<ProviderHomeScreen> {
  late final _bookingsService = ProviderBookingService();
  late final _profileService = ProviderProfileService();
  late final _notificationService = ProviderNotificationService();
  late Stream<List<Booking>> _bookings = _bookingsService.watchBookings();
  int _section = 0;
  int _jobsTab = 0;
  String? _selectedId;
  bool _payment = false;
  // Profile > Notifications list; a job opened from it returns to the list.
  bool _notifications = false;
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(minutes: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  void _open(Booking booking) => setState(() {
    _selectedId = booking.id;
    _payment = false;
  });
  void _back() => setState(() {
    if (_payment) {
      _payment = false;
    } else if (_selectedId != null) {
      _selectedId = null;
    } else {
      _notifications = false;
    }
  });
  void _changed(BookingStatus status) => setState(() {
    _selectedId = null;
    _payment = false;
    _notifications = false;
    _section = 1;
    _jobsTab = status == BookingStatus.confirmed ? 1 : 2;
  });

  /// One of the four tab pages (not a job or the notifications list).
  bool get _onTabPage => _selectedId == null && !_notifications;

  /// Notifications and the provider's profile, at the right of the header.
  List<Widget> _tabActions(AppLocalizations l10n) => [
    IconButton(
      key: const ValueKey('header-bell'),
      tooltip: l10n.titleNotifications,
      icon: StreamBuilder<int>(
        stream: _notificationService.watchUnreadCount(),
        builder: (context, snapshot) {
          final unread = snapshot.data ?? 0;
          return Badge(
            isLabelVisible: unread > 0,
            label: Text(unread > 9 ? '9+' : '$unread'),
            child: const Icon(LucideIcons.bell),
          );
        },
      ),
      onPressed: () => setState(() {
        _section = 3;
        _notifications = true;
      }),
    ),
    Padding(
      padding: const EdgeInsets.only(right: AppSpacing.xs),
      child: IconButton(
        key: const ValueKey('header-profile'),
        tooltip: l10n.navProfile,
        style: IconButton.styleFrom(
          backgroundColor: AppColors.brand900,
          foregroundColor: Colors.white,
        ),
        icon: const Icon(LucideIcons.user, size: 20),
        onPressed: () => setState(() => _section = 3),
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) => Theme(
    // The style guide theme with the font and line heights of the language.
    data: LocaleTypography.apply(context, ProviderTheme.data),
    child: Builder(
      builder: (context) {
        final l10n = context.l10n;
        return PopScope(
          canPop: _selectedId == null && !_notifications,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) _back();
          },
          child: BrandShell(
            backdrop: true,
            child: Scaffold(
              appBar: AppBar(
                // The four tab pages: title on the left, then the bell and the
                // provider's profile on the right.
                centerTitle: _onTabPage ? false : null,
                actions: _onTabPage ? _tabActions(l10n) : null,
                title: Text(
                  _selectedId != null
                      ? (_payment ? l10n.titleJobPayment : l10n.titleJobDetails)
                      : _notifications
                      ? l10n.titleNotifications
                      : [
                          l10n.navLeads,
                          l10n.navMyJobs,
                          l10n.navEarnings,
                          l10n.navProfile,
                        ][_section],
                ),
                leading: _selectedId == null && !_notifications
                    ? null
                    : BackButton(onPressed: _back),
              ),
              body: SafeArea(
                child: _section == 3 && _selectedId == null
                    ? (_notifications
                          ? ProviderNotificationsScreen(
                              service: _notificationService,
                              onOpen: (item) async {
                                if (item.type == AppNotification.disputeType) {
                                  // A dispute about one of this provider's jobs.
                                  final target =
                                      await Navigator.of(context).push<int>(
                                    MaterialPageRoute<int>(
                                      builder: (_) => Theme(
                                        data: ProviderTheme.data,
                                        child: ProviderDisputeScreen(
                                          bookingId: item.bookingId,
                                          selectedIndex: 3,
                                        ),
                                      ),
                                    ),
                                  );
                                  if (target != null && mounted) {
                                    setState(() {
                                      _section = target;
                                      _selectedId = null;
                                      _payment = false;
                                      _notifications = false;
                                    });
                                  }
                                  return;
                                }
                                setState(() {
                                  if (item.type == AppNotification.reviewType ||
                                      item.type == AppNotification.quoteType) {
                                    _selectedId = item.bookingId;
                                    _payment = false;
                                  } else {
                                    // e.g. verification news: back to the profile.
                                    _notifications = false;
                                  }
                                });
                              },
                            )
                          : ProviderProfileScreen(
                              user: widget.user,
                              authService: widget.authService,
                              service: _profileService,
                              notifications: _notificationService,
                              verificationStatus: VerificationStatus.verified,
                              verification: widget.verification,
                              onOpenNotifications: () =>
                                  setState(() => _notifications = true),
                              onSelectTab: (index) => setState(() {
                                _section = index;
                                _selectedId = null;
                                _payment = false;
                                _notifications = false;
                              }),
                            ))
                    : StreamBuilder<List<Booking>>(
                        stream: _bookings,
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return ProviderFailure(
                              error: snapshot.error,
                              onRetry: () => setState(
                                () => _bookings = _bookingsService
                                    .watchBookings(),
                              ),
                            );
                          }
                          if (snapshot.connectionState ==
                                  ConnectionState.waiting ||
                              !snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          final bookings = snapshot.data!;
                          if (_selectedId != null) {
                            final matches = bookings.where(
                              (b) => b.id == _selectedId,
                            );
                            if (matches.isEmpty) {
                              return ProviderPage(
                                children: [
                                  ProviderEmpty(
                                    title: l10n.jobUnavailableTitle,
                                    message: l10n.jobUnavailableMessage,
                                  ),
                                ],
                              );
                            }
                            final booking = matches.first;
                            if (_payment) {
                              return ProviderPaymentScreen(
                                key: ValueKey('payment-${booking.id}'),
                                booking: booking,
                                service: _bookingsService,
                                onChanged: _changed,
                              );
                            }
                            return ProviderJobDetailsScreen(
                              key: ValueKey(booking.id),
                              booking: booking,
                              service: _bookingsService,
                              onChanged: _changed,
                              onPayment: () => setState(() => _payment = true),
                            );
                          }
                          return switch (_section) {
                            0 => ProviderDashboardScreen(
                              user: widget.user,
                              bookings: bookings,
                              onOpen: _open,
                              onViewJobs: () => setState(() {
                                _section = 1;
                                _jobsTab = 0;
                              }),
                            ),
                            1 => ProviderJobsScreen(
                              bookings: bookings,
                              tab: _jobsTab,
                              onTab: (tab) => setState(() => _jobsTab = tab),
                              onOpen: _open,
                              watchReview: _bookingsService.watchReview,
                            ),
                            _ => ProviderEarningsScreen(
                              bookings: bookings,
                              onOpen: _open,
                              onExploreLeads: () =>
                                  setState(() => _section = 0),
                            ),
                          };
                        },
                      ),
              ),
              bottomNavigationBar: AppBottomNav(
                items: AppBottomNav.localizedProviderItems(context),
                selectedIndex: _section,
                onSelected: (index) => setState(() {
                  _section = index;
                  _selectedId = null;
                  _payment = false;
                  _notifications = false;
                }),
              ),
            ),
          ),
        );
      },
    ),
  );
}
