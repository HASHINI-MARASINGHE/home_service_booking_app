import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/l10n_context.dart';
import '../../models/app_user.dart';
import '../../models/professional.dart';
import '../../models/service_category.dart';
import '../../services/address_service.dart';
import '../../services/auth_service.dart';
import '../../services/customer_booking_service.dart';
import '../../services/location_service.dart';
import '../../services/provider_notification_service.dart';
import '../../services/receipt_pdf_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/locale_typography.dart';
import 'addresses/my_addresses_screen.dart';
import 'bookings/booking_history_screen.dart';
import 'customer_notifications_screen.dart';
import 'customer_profile_screen.dart';
import 'customer_scope.dart';
import 'providers/all_providers_screen.dart';
import 'widgets/customer_home_widgets.dart';
import 'widgets/provider_directory_widgets.dart';
import '../../widgets/common/homecare_logo.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({
    super.key,
    required this.user,
    required this.authService,
    this.addressService,
    this.bookingService,
    this.locationService,
    this.receiptPdfService,
    this.notificationService,
    this.initialTab = CustomerTab.home,
  });

  final AppUser user;
  final AuthService authService;
  final AddressService? addressService;
  final CustomerBookingService? bookingService;
  final LocationService? locationService;
  final ReceiptPdfService? receiptPdfService;
  final ProviderNotificationService? notificationService;
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
  // The same per-user notification feed the provider app reads. It needs
  // Firebase, so it is simply absent (no bell) where Firebase is not set up,
  // such as widget tests.
  late final _notifications = widget.notificationService ?? _tryNotifications();

  static ProviderNotificationService? _tryNotifications() {
    try {
      return ProviderNotificationService();
    } catch (_) {
      return null;
    }
  }

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
    // The style guide theme with the font and line heights of the language.
    final theme = LocaleTypography.apply(context, AppTheme.light);
    return CustomerScope(
      user: _currentUser,
      addresses: _addresses,
      bookings: _bookings,
      location: _location,
      receipts: _receipts,
      selectTab: _selectTab,
      child: Theme(
        data: theme,
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _handleBack();
          },
          child: BrandShell(
            child: Scaffold(
              backgroundColor: AppColors.bg,
              body: IndexedStack(
                index: _selectedIndex,
                children: [
                  _tab(
                    CustomerTab.home,
                    ColoredBox(
                      color: AppColors.bg,
                      child: _CustomerHomeContent(
                        user: _currentUser,
                        notifications: _notifications,
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
              bottomNavigationBar: CustomerBottomNavigation(
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
      builder: (_) => Material(color: AppColors.bg, child: root),
    ),
  );
}

class _CustomerHomeContent extends StatefulWidget {
  const _CustomerHomeContent({required this.user, this.notifications});

  final AppUser user;
  final ProviderNotificationService? notifications;

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
    final styles = context.textStyles;
    return RefreshIndicator(
      onRefresh: () async {
        _reload();
        await Future<void>.delayed(const Duration(milliseconds: 600));
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.screen,
              AppSpacing.screen,
              AppSpacing.xxl,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                SafeArea(
                  bottom: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.customerHomeGreeting(
                            user.name.trim().split(' ').first,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: styles.h3,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      if (widget.notifications != null) ...[
                        NotificationBell(service: widget.notifications!),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      CustomerAvatar(photoUrl: user.photoUrl, radius: 24),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                _HomeBanner(
                  title: l10n.customerHomeTitle,
                  subtitle: l10n.customerHomeSubtitle,
                ),
                const SizedBox(height: AppSpacing.xl),
                CustomerSearchBar(
                  onChanged: (text) => setState(() => _query = text),
                ),
                const SizedBox(height: AppSpacing.xxl),
                Row(
                  children: [
                    Expanded(
                      child: _SectionHeading(title: l10n.servicesForYourHome),
                    ),
                    TextButton(
                      key: const ValueKey('see-all-services'),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              const Material(child: AllProvidersScreen()),
                        ),
                      ),
                      child: Text(l10n.seeAll),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
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
                        const SizedBox(height: AppSpacing.xl),
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.space1,
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
                              child: Text(l10n.seeAll),
                            ),
                            if (snapshot.hasData)
                              Text(
                                l10n.providerCount(shown.length),
                                key: const ValueKey('provider-count'),
                                style: styles.caption,
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        if (snapshot.hasError)
                          DirectoryMessage(
                            title: l10n.loadErrorTitle,
                            text: l10n.providersLoadError,
                            icon: Icons.cloud_off_outlined,
                            actionLabel: l10n.tryAgain,
                            onAction: _reload,
                          )
                        else if (!snapshot.hasData)
                          const Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: AppSpacing.xl,
                            ),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (shown.isEmpty)
                          DirectoryMessage(
                            key: const ValueKey('no-providers'),
                            title: l10n.emptyProvidersTitle,
                            icon: Icons.search_off_rounded,
                            text: all.isEmpty
                                ? l10n.noVerifiedProviders
                                : _query.trim().isNotEmpty
                                ? l10n.noProvidersMatch(_query.trim())
                                : l10n.noProvidersInCategory,
                          )
                        else
                          for (var i = 0; i < shown.length; i++)
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.sm,
                              ),
                              child: DirectoryProviderCard(
                                provider: shown[i],
                                index: i,
                              ),
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

/// Welcome card: a photo of a provider at work under a deep blue fade, so
/// the white text keeps its contrast however the photo is cropped.
class _HomeBanner extends StatelessWidget {
  const _HomeBanner({required this.title, required this.subtitle});

  static const photo = 'assets/images/onboarding_home.jpg';

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    return ClipRRect(
      borderRadius: AppRadius.card,
      child: Stack(
        children: [
          Positioned.fill(
            child: ExcludeSemantics(
              child: Image.asset(
                photo,
                fit: BoxFit.cover,
                alignment: const Alignment(0.6, -0.4),
              ),
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xF20B2A5B), // brand 900 at 95%
                    Color(0xD90B2A5B), // brand 900 at 85%
                    Color(0x400B2A5B), // brand 900 at 25%
                  ],
                  stops: [0, 0.55, 1],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.space6,
              AppSpacing.space6,
              AppSpacing.space12,
              AppSpacing.space6,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: styles.h1.copyWith(color: AppColors.surface),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: styles.bodySmall.copyWith(color: AppColors.surface),
                ),
              ],
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
  Widget build(BuildContext context) =>
      Text(title, style: context.textStyles.h2);
}
