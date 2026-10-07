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

/// Bottom navigation from the design (Nav/Customer, Nav/Provider): every tab
/// is a round icon button with its label underneath. The selected tab turns
/// mint green with a green ring, a bold green label and a green icon.
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
      border: Border(top: BorderSide(color: AppColors.border)),
      boxShadow: AppShadows.card,
    ),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
        child: Row(
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

  static const _selectedFill = Color(0xFFE6F8EF);
  static const _selectedRing = Color(0xFFA9E9C9);
  static const _idleFill = Color(0xFFF4F6FA);
  static const _idleRing = Color(0xFFE3E7EF);

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: item.label,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: ExcludeSemantics(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Badge(
                isLabelVisible: item.badge > 0,
                label: Text('${item.badge}'),
                backgroundColor: AppColors.danger,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? _selectedFill : _idleFill,
                    border: Border.all(
                      color: selected ? _selectedRing : _idleRing,
                    ),
                  ),
                  child: Icon(
                    item.icon,
                    size: 21,
                    color: selected ? AppColors.primary : AppColors.muted,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.label,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style:
                    (Theme.of(context).textTheme.bodyMedium ??
                            const TextStyle())
                        .copyWith(
                          fontSize: 14,
                          height: 1.2,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
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
