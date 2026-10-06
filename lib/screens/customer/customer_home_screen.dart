import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/professional.dart';
import '../../models/service_category.dart';
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
import 'widgets/provider_directory_widgets.dart';

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

class _CustomerHomeContent extends StatefulWidget {
  const _CustomerHomeContent({required this.user});

  final AppUser user;

  @override
  State<_CustomerHomeContent> createState() => _CustomerHomeContentState();
}

class _CustomerHomeContentState extends State<_CustomerHomeContent> {
  Stream<List<Professional>>? _directory;
  ServiceCategory? _category;
  String _query = '';

  AppUser get user => widget.user;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _directory ??= CustomerScope.of(context).bookings.watchProfessionals();
  }

  void _reload() => setState(
    () => _directory = CustomerScope.of(context).bookings.watchProfessionals(),
  );

  /// Verified providers matching the chosen category and the search text.
  List<Professional> _visible(List<Professional> all) {
    final query = _query.trim().toLowerCase();
    return [
      for (final p in all)
        if ((_category == null || _category!.matches(p)) &&
            (query.isEmpty ||
                '${p.name} ${p.specialty} ${p.services.join(' ')} ${p.providerCode ?? ''}'
                    .toLowerCase()
                    .contains(query)))
          p,
    ];
  }

  @override
  Widget build(BuildContext context) => CustomScrollView(
    slivers: [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        sliver: SliverList(
          delegate: SliverChildListDelegate([
            SafeArea(
              bottom: false,
              child: Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: CustomerHomeTheme.mint,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
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
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Hi, ${user.name.split(' ').first}',
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: CustomerHomeTheme.mutedText,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  CustomerAvatar(photoUrl: user.photoUrl, radius: 18),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Your Home,\nOur Care',
              style: TextStyle(
                color: CustomerHomeTheme.primaryDark,
                fontSize: 36,
                height: 1.08,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Book trusted professionals for every home need, all in one place.',
              style: TextStyle(
                color: CustomerHomeTheme.mutedText,
                fontSize: 15,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 22),
            CustomerSearchBar(
              onChanged: (text) => setState(() => _query = text),
            ),
            const SizedBox(height: 30),
            const _SectionHeading(title: 'Services for your home'),
            const SizedBox(height: 14),
            StreamBuilder<List<Professional>>(
              stream: _directory,
              builder: (context, snapshot) {
                final all = snapshot.data ?? const <Professional>[];
                final shown = _visible(all);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CategoryRow(
                      providers: all,
                      selected: _category,
                      onSelected: (c) => setState(() => _category = c),
                    ),
                    const SizedBox(height: 26),
                    Row(
                      children: [
                        const Expanded(
                          child: _SectionHeading(title: 'Verified providers'),
                        ),
                        if (snapshot.hasData)
                          Text(
                            '${shown.length} ${shown.length == 1 ? 'provider' : 'providers'}',
                            key: const ValueKey('provider-count'),
                            style: const TextStyle(
                              color: CustomerHomeTheme.mutedText,
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (snapshot.hasError)
                      Column(
                        children: [
                          const DirectoryMessage(
                            text: 'Providers could not be loaded right now.',
                            icon: Icons.cloud_off_outlined,
                          ),
                          TextButton(
                            onPressed: _reload,
                            child: const Text('Try again'),
                          ),
                        ],
                      )
                    else if (!snapshot.hasData)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (shown.isEmpty)
                      DirectoryMessage(
                        key: const ValueKey('no-providers'),
                        icon: Icons.search_off_rounded,
                        text: all.isEmpty
                            ? 'No verified providers yet. Providers show up here as soon as our team verifies them.'
                            : 'No providers match your search. Try another category or clear the search.',
                      )
                    else
                      for (final provider in shown)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ProviderListCard(provider: provider),
                        ),
                  ],
                );
              },
            ),
          ]),
        ),
      ),
    ],
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: const TextStyle(
      color: CustomerHomeTheme.text,
      fontSize: 20,
      fontWeight: FontWeight.w800,
    ),
  );
}
