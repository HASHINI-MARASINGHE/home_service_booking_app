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
import '../../l10n/l10n_context.dart';
import '../../theme/customer_home_theme.dart';
import '../../theme/locale_typography.dart';
import '../../widgets/common/language_switch.dart';
import 'addresses/my_addresses_screen.dart';
import 'bookings/booking_history_screen.dart';
import 'customer_profile_screen.dart';
import 'customer_scope.dart';
import 'widgets/customer_home_widgets.dart';
import 'providers/all_providers_screen.dart';
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
  Widget build(BuildContext context) {
    // Language font only for the home tab and the bottom navigation.
    final homeTheme = LocaleTypography.apply(context, AppTheme.light);
    return CustomerScope(
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
                    child: Theme(
                      data: homeTheme,
                      child: _CustomerHomeContent(user: _currentUser),
                    ),
                  ),
                ),
                _tab(CustomerTab.bookings, const BookingHistoryScreen()),
                _tab(CustomerTab.saved, const MyAddressesScreen()),
                _tab(
                  CustomerTab.profile,
                  CustomerProfileScreen(
                    uid: _currentUser.uid,
                    authService: widget.authService,
                    onUserUpdated: (user) =>
                        setState(() => _currentUser = user),
                  ),
                ),
              ],
            ),
            bottomNavigationBar: Theme(
              data: homeTheme,
              child: CustomerBottomNavigation(
                selectedIndex: _selectedIndex,
                onSelected: _selectTab,
              ),
            ),
          ),
        ),
      ),
    );
  }
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
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sinhala = LocaleTypography.isSinhala(Localizations.localeOf(context));
    return RefreshIndicator(
      onRefresh: () async {
        _reload();
        await Future<void>.delayed(const Duration(milliseconds: 600));
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                SafeArea(
                  bottom: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const LanguageSwitch(),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.customerHomeGreeting(
                                user.name.trim().split(' ').first,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: CustomerHomeTheme.text,
                                fontSize: 18,
                                height: sinhala ? 1.75 : null,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          CustomerAvatar(photoUrl: user.photoUrl, radius: 22),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  l10n.customerHomeTitle,
                  style: TextStyle(
                    color: CustomerHomeTheme.primaryDark,
                    fontSize: 36,
                    height: sinhala ? 1.6 : 1.08,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.customerHomeSubtitle,
                  style: TextStyle(
                    color: CustomerHomeTheme.mutedText,
                    fontSize: 16,
                    height: sinhala ? 1.75 : 1.45,
                  ),
                ),
                const SizedBox(height: 22),
                CustomerSearchBar(
                  onChanged: (text) => setState(() => _query = text),
                ),
                const SizedBox(height: 30),
                _SectionHeading(title: l10n.servicesForYourHome),
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
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 12,
                          runSpacing: 4,
                          children: [
                            _SectionHeading(title: l10n.verifiedProviders),
                            TextButton(
                              key: const ValueKey('see-all-providers'),
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const Material(
                                    child: AllProvidersScreen(),
                                  ),
                                ),
                              ),
                              child: Text(
                                l10n.seeAll,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (snapshot.hasData)
                              Text(
                                l10n.providerCount(shown.length),
                                key: const ValueKey('provider-count'),
                                style: const TextStyle(
                                  color: CustomerHomeTheme.mutedText,
                                  fontSize: 14,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (snapshot.hasError)
                          Column(
                            children: [
                              DirectoryMessage(
                                text: l10n.providersLoadError,
                                icon: Icons.cloud_off_outlined,
                              ),
                              TextButton(
                                onPressed: _reload,
                                child: Text(l10n.tryAgain),
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
                                ? l10n.noVerifiedProviders
                                : _query.trim().isNotEmpty
                                ? l10n.noProvidersMatch(_query.trim())
                                : l10n.noProvidersInCategory,
                          )
                        else
                          for (final provider in shown)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: DirectoryProviderCard(provider: provider),
                            ),
                      ],
                    );
                  },
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: TextStyle(
      color: CustomerHomeTheme.text,
      fontSize: 21,
      height: LocaleTypography.isSinhala(Localizations.localeOf(context))
          ? 1.6
          : null,
      fontWeight: FontWeight.w800,
    ),
  );
}
