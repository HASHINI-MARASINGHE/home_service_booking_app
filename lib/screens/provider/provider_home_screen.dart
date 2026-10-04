import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../models/booking.dart';
import '../../services/auth_service.dart';
import '../../services/provider_booking_service.dart';
import '../../services/provider_profile_service.dart';
import '../../widgets/provider/provider_widgets.dart';
import 'provider_dashboard_screen.dart';
import 'provider_earnings_screen.dart';
import 'provider_job_details_screen.dart';
import 'provider_jobs_screen.dart';
import 'provider_payment_screen.dart';
import 'provider_profile_screen.dart';
import 'provider_theme.dart';

// Provider-only shell; future mode switching can wrap this without changing it.
class ProviderHomeScreen extends StatefulWidget {
  const ProviderHomeScreen({
    super.key,
    required this.user,
    required this.authService,
  });
  final AppUser user;
  final AuthService authService;
  @override
  State<ProviderHomeScreen> createState() => _ProviderHomeScreenState();
}

class _ProviderHomeScreenState extends State<ProviderHomeScreen> {
  late final _bookingsService = ProviderBookingService();
  late final _profileService = ProviderProfileService();
  late Stream<List<Booking>> _bookings = _bookingsService.watchBookings();
  int _section = 0;
  int _jobsTab = 0;
  String? _selectedId;
  bool _payment = false;
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
    } else {
      _selectedId = null;
    }
  });
  void _changed(BookingStatus status) => setState(() {
    _selectedId = null;
    _payment = false;
    _section = 1;
    _jobsTab = status == BookingStatus.confirmed ? 1 : 2;
  });

  @override
  Widget build(BuildContext context) => Theme(
    data: ProviderTheme.data,
    child: Builder(
      builder: (context) => PopScope(
        canPop: _selectedId == null,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) _back();
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              _selectedId != null
                  ? (_payment ? 'Job completion / payment' : 'Job details')
                  : ['Leads', 'My Jobs', 'Earnings', 'Profile'][_section],
            ),
            leading: _selectedId == null ? null : BackButton(onPressed: _back),
          ),
          body: SafeArea(
            child: _section == 3
                ? ProviderProfileScreen(
                    user: widget.user,
                    authService: widget.authService,
                    service: _profileService,
                  )
                : StreamBuilder<List<Booking>>(
                    stream: _bookings,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return ProviderFailure(
                          error: snapshot.error,
                          onRetry: () => setState(
                            () => _bookings = _bookingsService.watchBookings(),
                          ),
                        );
                      }
                      if (snapshot.connectionState == ConnectionState.waiting ||
                          !snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final bookings = snapshot.data!;
                      if (_selectedId != null) {
                        final matches = bookings.where(
                          (b) => b.id == _selectedId,
                        );
                        if (matches.isEmpty) {
                          return const ProviderPage(
                            children: [
                              ProviderEmpty(
                                title: 'Job unavailable',
                                message: 'This job is no longer assigned to you. Go back to view your jobs.',
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
                        ),
                        _ => ProviderEarningsScreen(
                          bookings: bookings,
                          onOpen: _open,
                        ),
                      };
                    },
                  ),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _section,
            onDestinationSelected: (index) => setState(() {
              _section = index;
              _selectedId = null;
              _payment = false;
            }),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Leads',
              ),
              NavigationDestination(
                icon: Icon(Icons.calendar_today_outlined),
                label: 'My Jobs',
              ),
              NavigationDestination(
                icon: Icon(Icons.account_balance_wallet_outlined),
                label: 'Earnings',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
