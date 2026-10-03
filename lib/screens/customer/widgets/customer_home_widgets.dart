import 'package:flutter/material.dart';

import '../../../data/customer_home_data.dart';
import '../../../theme/customer_home_theme.dart';

class CustomerSearchBar extends StatelessWidget {
  const CustomerSearchBar({super.key});

  @override
  Widget build(BuildContext context) => TextField(
    decoration: InputDecoration(
      hintText: 'Search services, providers...',
      hintStyle: const TextStyle(
        color: CustomerHomeTheme.mutedText,
        fontSize: 14,
      ),
      prefixIcon: const Icon(Icons.search, color: CustomerHomeTheme.primary),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: CustomerHomeTheme.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: CustomerHomeTheme.primary),
      ),
    ),
  );
}

class ProviderAvatar extends StatelessWidget {
  const ProviderAvatar({super.key, required this.provider});

  final ProviderPreview provider;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 74,
    child: Column(
      children: [
        SizedBox(
          width: 60,
          height: 60,
          child: ClipOval(
            child: Image.network(
              provider.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: CustomerHomeTheme.mint,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.person,
                  color: CustomerHomeTheme.primary,
                  size: 28,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          provider.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: CustomerHomeTheme.text,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class ServiceCard extends StatelessWidget {
  const ServiceCard({super.key, required this.service});

  final ServicePreview service;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(22),
    elevation: 0,
    shadowColor: CustomerHomeTheme.shadow,
    child: InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () {
        // TODO: Navigate to the selected service details.
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            child: SizedBox(
              height: 148,
              width: double.infinity,
              child: Image.network(
                service.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: CustomerHomeTheme.mint,
                  alignment: Alignment.center,
                  child: Icon(
                    service.icon == 'carpentry'
                        ? Icons.handyman_outlined
                        : Icons.cleaning_services_outlined,
                    color: CustomerHomeTheme.primary,
                    size: 44,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: CustomerHomeTheme.mint,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    child: Text(
                      service.category,
                      style: const TextStyle(
                        color: CustomerHomeTheme.primaryDark,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  service.title,
                  style: const TextStyle(
                    color: CustomerHomeTheme.text,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  service.description,
                  style: const TextStyle(
                    color: CustomerHomeTheme.mutedText,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class CustomerBottomNavigation extends StatelessWidget {
  const CustomerBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => NavigationBar(
    selectedIndex: selectedIndex,
    onDestinationSelected: onSelected,
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.white,
    indicatorColor: CustomerHomeTheme.mint,
    labelTextStyle: const WidgetStatePropertyAll(
      TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
    ),
    destinations: const [
      NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
      NavigationDestination(icon: Icon(Icons.grid_view_outlined), selectedIcon: Icon(Icons.grid_view), label: 'Services'),
      NavigationDestination(icon: Icon(Icons.bookmark_border), selectedIcon: Icon(Icons.bookmark), label: 'Saved'),
      NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
    ],
  );
}
