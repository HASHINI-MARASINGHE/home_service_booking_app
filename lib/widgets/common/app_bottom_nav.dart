import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../l10n/l10n_context.dart';
import '../../theme/app_theme.dart';

/// One tab of [AppBottomNav].
class AppNavItem {
  const AppNavItem({required this.icon, required this.label, this.badge = 0});
  final IconData icon;
  final String label;

  /// Unread count shown on the icon (hidden when 0).
  final int badge;
}

/// Bottom navigation (Nav/Customer, Nav/Provider): every tab is a round icon
/// button with its label always shown underneath (14 px bold, an icon alone is
/// not enough). The selected tab has a blue ring, a pale blue fill and a blue
/// label.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<AppNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  /// Customer tabs: Home, Bookings, Saved, Profile.
  static const customerItems = [
    AppNavItem(icon: LucideIcons.house, label: 'Home'),
    AppNavItem(icon: LucideIcons.clipboard, label: 'Bookings'),
    AppNavItem(icon: LucideIcons.bookmark, label: 'Saved'),
    AppNavItem(icon: LucideIcons.user, label: 'Profile'),
  ];

  /// Provider tabs: Leads, My Jobs, Earnings, Profile.
  static const providerItems = [
    AppNavItem(icon: LucideIcons.house, label: 'Leads'),
    AppNavItem(icon: LucideIcons.calendar, label: 'My Jobs'),
    AppNavItem(icon: LucideIcons.wallet, label: 'Earnings'),
    AppNavItem(icon: LucideIcons.user, label: 'Profile'),
  ];

  /// [customerItems] with the labels in the current language.
  static List<AppNavItem> localizedCustomerItems(BuildContext context) {
    final l10n = context.l10n;
    return [
      AppNavItem(icon: LucideIcons.house, label: l10n.navHome),
      AppNavItem(icon: LucideIcons.clipboard, label: l10n.navBookings),
      AppNavItem(icon: LucideIcons.bookmark, label: l10n.navSaved),
      AppNavItem(icon: LucideIcons.user, label: l10n.navProfile),
    ];
  }

  /// [providerItems] with the labels in the current language.
  static List<AppNavItem> localizedProviderItems(BuildContext context) {
    final l10n = context.l10n;
    return [
      AppNavItem(icon: LucideIcons.house, label: l10n.navLeads),
      AppNavItem(icon: LucideIcons.calendar, label: l10n.navMyJobs),
      AppNavItem(icon: LucideIcons.wallet, label: l10n.navEarnings),
      AppNavItem(icon: LucideIcons.user, label: l10n.navProfile),
    ];
  }

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: AppColors.surface,
      border: Border(
        top: BorderSide(
          color: AppColors.borderSubtle,
          width: AppSizes.borderControl,
        ),
      ),
      boxShadow: AppShadows.bar,
    ),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xs,
          AppSpacing.xs,
          AppSpacing.xs,
          AppSpacing.space1,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                child: _NavButton(
                  item: items[i],
                  selected: i == selectedIndex,
                  onTap: () => onSelected(i),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final AppNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: item.label,
    child: InkWell(
      onTap: onTap,
      borderRadius: AppRadius.button,
      child: ExcludeSemantics(
        child: ConstrainedBox(
          // The bar is 72 px tall in all: this plus its padding.
          constraints: const BoxConstraints(minHeight: AppSizes.nav - 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Badge(
                isLabelVisible: item.badge > 0,
                label: Text('${item.badge}'),
                backgroundColor: AppColors.danger,
                child: AnimatedContainer(
                  duration: AppMotion.duration(context),
                  curve: AppMotion.curve,
                  width: AppSizes.minTap,
                  height: AppSizes.minTap,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? AppColors.brand100 : AppColors.surfaceAlt,
                    border: Border.all(
                      color: selected
                          ? AppColors.brand700
                          : AppColors.borderSubtle,
                      width: selected ? AppSizes.borderControl : 1,
                    ),
                  ),
                  child: Icon(
                    item.icon,
                    size: AppSizes.iconNav - 2,
                    color: selected ? AppColors.primary : AppColors.muted,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.space1),
              // Labels are always shown, 14 px bold. A long label wraps.
              Text(
                item.label,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: context.textStyles.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: selected ? AppColors.primary : AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
