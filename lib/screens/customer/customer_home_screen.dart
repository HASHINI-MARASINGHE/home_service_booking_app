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
                  const Spacer(),
                  Text(
                    'Hi, ${user.name.split(' ').first}',
                    style: const TextStyle(
                      color: CustomerHomeTheme.mutedText,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
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
            const CustomerSearchBar(),
            const SizedBox(height: 30),
            const _SectionHeading(title: 'Provider Profiles'),
            const SizedBox(height: 14),
            SizedBox(
              height: 92,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: customerProviders.length,
                separatorBuilder: (context, index) => const SizedBox(width: 14),
                itemBuilder: (context, index) => ProviderAvatar(
                  provider: customerProviders[index],
                ),
              ),
            ),
            const SizedBox(height: 30),
            const _SectionHeading(title: 'Services for your home'),
            const SizedBox(height: 14),
            ...customerServices.map(
              (service) => Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: ServiceCard(service: service),
              ),
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

