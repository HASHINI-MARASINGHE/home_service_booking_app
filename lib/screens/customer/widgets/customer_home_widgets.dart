import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../data/customer_home_data.dart';
import '../../../models/professional.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/customer_home_theme.dart';

class CustomerAvatar extends StatelessWidget {
  const CustomerAvatar({super.key, required this.photoUrl, this.radius = 28});

  final String? photoUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final url = photoUrl?.trim() ?? '';
    return CircleAvatar(
      radius: radius,
      backgroundColor: CustomerHomeTheme.mint,
      child: url.isEmpty
          ? Icon(
              Icons.person,
              color: CustomerHomeTheme.primary,
              size: radius * 1.05,
            )
          : ClipOval(
              child: Image.network(
                url,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.person,
                  color: CustomerHomeTheme.primary,
                  size: radius * 1.05,
                ),
              ),
            ),
    );
  }
}

class CustomerSearchBar extends StatelessWidget {
  const CustomerSearchBar({super.key});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      boxShadow: const [
        BoxShadow(
          color: CustomerHomeTheme.shadow,
          blurRadius: 16,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: TextField(
      decoration: InputDecoration(
        hintText: 'Search services, providers...',
        hintStyle: const TextStyle(
          color: CustomerHomeTheme.mutedText,
          fontSize: 14,
        ),
        prefixIcon: const Icon(Icons.search, color: CustomerHomeTheme.primary),
        suffixIcon: IconButton(
          tooltip: 'Filter services',
          onPressed: () {
            // TODO: Add service filters.
          },
          icon: const Icon(
            Icons.tune_rounded,
            color: CustomerHomeTheme.primary,
            size: 20,
          ),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: CustomerHomeTheme.primary),
        ),
      ),
    ),
  );
}

class ProviderAvatar extends StatelessWidget {
  const ProviderAvatar({super.key, required this.provider, this.onTap});

  final Professional provider;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 78,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: CustomerHomeTheme.primary,
              shape: BoxShape.circle,
            ),
            child: SizedBox(
              width: 64,
              height: 64,
              child: ClipOval(
                child: provider.photoUrl == null
                    ? _initials()
                    : Image.network(
                        provider.photoUrl!,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) =>
                            progress == null
                            ? child
                            : const ProviderAvatarPlaceholder(),
                        errorBuilder: (context, error, stackTrace) =>
                            _initials(),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            provider.firstName,
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
    ),
  );

  Widget _initials() {
    final parts = provider.name.trim().split(RegExp(r'\s+'));
    final letters = parts
        .take(2)
        .where((p) => p.isNotEmpty)
        .map((p) => p[0].toUpperCase())
        .join();
    return Container(
      color: CustomerHomeTheme.mint,
      alignment: Alignment.center,
      child: letters.isEmpty
          ? const Icon(Icons.person, color: CustomerHomeTheme.primary, size: 28)
          : Text(
              letters,
              style: const TextStyle(
                color: CustomerHomeTheme.primaryDark,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }
}

/// Mint circle shown while a provider photo or the directory is loading.
class ProviderAvatarPlaceholder extends StatelessWidget {
  const ProviderAvatarPlaceholder({super.key});

  @override
  Widget build(BuildContext context) => Container(
    color: CustomerHomeTheme.mint,
    alignment: Alignment.center,
    child: const SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: CustomerHomeTheme.primary,
      ),
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
            borderRadius: const BorderRadius.all(Radius.circular(22)),
            child: Stack(
              children: [
                SizedBox(
                  height: 152,
                  width: double.infinity,
                  child: Image.network(
                    service.imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) =>
                        progress == null
                        ? child
                        : Container(
                            color: CustomerHomeTheme.mint,
                            alignment: Alignment.center,
                            child: const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: CustomerHomeTheme.primary,
                              ),
                            ),
                          ),
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
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: CustomerHomeTheme.mint,
                      borderRadius: BorderRadius.circular(18),
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
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.title,
                        style: const TextStyle(
                          color: CustomerHomeTheme.text,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        service.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: CustomerHomeTheme.mutedText,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: CustomerHomeTheme.mint,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: CustomerHomeTheme.primary,
                      size: 18,
                    ),
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
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(boxShadow: AppShadows.card),
    child: NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onSelected,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      height: 72,
      indicatorColor: CustomerHomeTheme.mint,
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      labelTextStyle: const WidgetStatePropertyAll(
        TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
      destinations: const [
        NavigationDestination(
          icon: Icon(LucideIcons.home),
          selectedIcon: Icon(LucideIcons.house),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(LucideIcons.calendarDays),
          label: 'Bookings',
        ),
        NavigationDestination(icon: Icon(LucideIcons.bookmark), label: 'Saved'),
        NavigationDestination(icon: Icon(LucideIcons.user), label: 'Profile'),
      ],
    ),
  );
}
