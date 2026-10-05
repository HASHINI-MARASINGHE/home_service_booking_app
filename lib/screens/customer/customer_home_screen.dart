import 'package:flutter/material.dart';

import '../../data/customer_home_data.dart';
import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../../theme/customer_home_theme.dart';
import '../auth/logout_button.dart';
import 'customer_profile_screen.dart';
import 'widgets/customer_home_widgets.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({
    super.key,
    required this.user,
    required this.authService,
  });

  final AppUser user;
  final AuthService authService;

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  int _selectedIndex = 0;
  late AppUser _currentUser = widget.user;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: CustomerHomeTheme.background,
    body: IndexedStack(
      index: _selectedIndex,
      children: [
        _CustomerHomeContent(user: _currentUser),
        const _PlaceholderTab(title: 'Services'),
        const _PlaceholderTab(title: 'Saved'),
        CustomerProfileScreen(
          uid: _currentUser.uid,
          authService: widget.authService,
          onUserUpdated: (user) => setState(() => _currentUser = user),
        ),
      ],
    ),
    bottomNavigationBar: CustomerBottomNavigation(
      selectedIndex: _selectedIndex,
      onSelected: (index) => setState(() => _selectedIndex = index),
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

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      title,
      style: const TextStyle(
        color: CustomerHomeTheme.primaryDark,
        fontSize: 24,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

