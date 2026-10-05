import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/customer_home_data.dart';
import '../../models/app_user.dart';
import '../../services/address_service.dart';
import '../../services/auth_service.dart';
import '../../services/customer_booking_service.dart';
import '../../services/location_service.dart';
import '../../services/receipt_pdf_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/customer_home_theme.dart';
import 'addresses/my_addresses_screen.dart';
import 'bookings/booking_history_screen.dart';
import 'customer_profile_screen.dart';
import 'customer_scope.dart';
import 'widgets/customer_home_widgets.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({
    super.key,
    required this.user,
    required this.authService,
    this.addressService,
    this.bookingService,
    this.locationService,
    this.receiptPdfService,
    this.initialTab = CustomerTab.home,
  });

  final AppUser user;
  final AuthService authService;
  final AddressService? addressService;
  final CustomerBookingService? bookingService;
  final LocationService? locationService;
  final ReceiptPdfService? receiptPdfService;
  final int initialTab;

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  late int _selectedIndex = widget.initialTab;
  late AppUser _currentUser = widget.user;
  late final _addresses = widget.addressService ?? AddressService();
  late final _bookings = widget.bookingService ?? CustomerBookingService();
  late final _location = widget.locationService ?? LocationService();
  late final _receipts = widget.receiptPdfService ?? ReceiptPdfService();

  // Each tab keeps its own navigation stack so detail screens stay inside
  // the shell (with the bottom navigation) and survive tab switches.
  final _navigators = List.generate(4, (_) => GlobalKey<NavigatorState>());

  // Tabs are built on first visit so unopened tabs don't start Firestore
  // listeners; once built they stay alive in the IndexedStack.
  late final _visited = {widget.initialTab};

  void _selectTab(int tab, {bool reset = false}) {
    if (reset || tab == _selectedIndex) {
      _navigators[tab].currentState?.popUntil((route) => route.isFirst);
    }
    if (tab != _selectedIndex) {
      setState(() {
        _selectedIndex = tab;
        _visited.add(tab);
      });
    }
  }

  Widget _tab(int index, Widget root) => _visited.contains(index)
      ? _TabNavigator(navigatorKey: _navigators[index], root: root)
      : const SizedBox.shrink();

  void _handleBack() {
    final navigator = _navigators[_selectedIndex].currentState;
    if (navigator != null && navigator.canPop()) {
      navigator.maybePop();
    } else if (_selectedIndex != CustomerTab.home) {
      _selectTab(CustomerTab.home);
    } else {
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) => CustomerScope(
    user: _currentUser,
    addresses: _addresses,
    bookings: _bookings,
    location: _location,
    receipts: _receipts,
    selectTab: _selectTab,
    child: Theme(
      data: AppTheme.light,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _handleBack();
        },
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: IndexedStack(
            index: _selectedIndex,
            children: [
              _tab(
                CustomerTab.home,
                ColoredBox(
                  color: CustomerHomeTheme.background,
                  child: _CustomerHomeContent(user: _currentUser),
                ),
              ),
              _tab(CustomerTab.bookings, const BookingHistoryScreen()),
              _tab(CustomerTab.saved, const MyAddressesScreen()),
              _tab(
                CustomerTab.profile,
                CustomerProfileScreen(
                  uid: _currentUser.uid,
                  authService: widget.authService,
                  onUserUpdated: (user) => setState(() => _currentUser = user),
                ),
              ),
            ],
          ),
          bottomNavigationBar: CustomerBottomNavigation(
            selectedIndex: _selectedIndex,
            onSelected: _selectTab,
          ),
        ),
      ),
    ),
  );
}

class _TabNavigator extends StatelessWidget {
  const _TabNavigator({required this.navigatorKey, required this.root});

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget root;

  @override
  Widget build(BuildContext context) => Navigator(
    key: navigatorKey,
    onGenerateRoute: (settings) => MaterialPageRoute(
      settings: settings,
      // Home/Profile were written as Scaffold bodies; give them a Material
      // ancestor for text styles and ink now that they live in a route.
      builder: (_) => Material(color: AppColors.background, child: root),
    ),
  );
}

class _CustomerHomeContent extends StatelessWidget {
  const _CustomerHomeContent({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 104),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome back',
                          style: TextStyle(
                            color: CustomerHomeTheme.mutedText,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Hi, ${user.name.split(' ').first}',
                          style: const TextStyle(
                            color: CustomerHomeTheme.text,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CustomerAvatar(photoUrl: user.photoUrl, radius: 21),
                ],
              ),
              const SizedBox(height: 24),
              const _TrustedProsBadge(),
              const SizedBox(height: 14),
              const Text(
                'Your Home, Our Care',
                style: TextStyle(
                  color: CustomerHomeTheme.primaryDark,
                  fontSize: 30,
                  height: 1.12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Book trusted professionals for every home need.',
                style: TextStyle(
                  color: CustomerHomeTheme.mutedText,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              const CustomerSearchBar(),
              const SizedBox(height: 28),
              const _SectionHeading(title: 'Provider Profiles'),
              const SizedBox(height: 14),
              SizedBox(
                height: 104,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: customerProviders.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 16),
                  itemBuilder: (context, index) => ProviderAvatar(
                    provider: customerProviders[index],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const _SectionHeading(title: 'Services for your home'),
              const SizedBox(height: 14),
              ...customerServices.map(
                (service) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ServiceCard(service: service),
                ),
              ),
            ]),
          ),
        ),
      ],
    ),
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            color: CustomerHomeTheme.text,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      TextButton(
        onPressed: () {
          // TODO: Open the full list for this section.
        },
        style: TextButton.styleFrom(
          foregroundColor: CustomerHomeTheme.primary,
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: const Text(
          'See all',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    ],
  );
}

class _TrustedProsBadge extends StatelessWidget {
  const _TrustedProsBadge();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: CustomerHomeTheme.mint,
      borderRadius: BorderRadius.circular(24),
    ),
    child: const Padding(
      padding: EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_outlined,
            color: CustomerHomeTheme.primary,
            size: 15,
          ),
          SizedBox(width: 6),
          Text(
            'Trusted pros',
            style: TextStyle(
              color: CustomerHomeTheme.primaryDark,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}
