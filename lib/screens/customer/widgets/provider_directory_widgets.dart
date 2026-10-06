import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../models/professional.dart';
import '../../../models/service_category.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/customer_home_theme.dart';
import '../../../widgets/common/app_widgets.dart';
import '../providers/provider_details_screen.dart';

/// "All" plus one tile per category; tapping filters the provider list.
class CategoryRow extends StatelessWidget {
  const CategoryRow({
    super.key,
    required this.providers,
    required this.selected,
    required this.onSelected,
  });

  final List<Professional> providers;
  final ServiceCategory? selected;
  final ValueChanged<ServiceCategory?> onSelected;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 104,
    child: ListView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      children: [
        _CategoryTile(
          key: const ValueKey('category-all'),
          label: 'All',
          icon: LucideIcons.layoutGrid,
          count: providers.length,
          selected: selected == null,
          onTap: () => onSelected(null),
        ),
        for (final category in ServiceCategory.all)
          _CategoryTile(
            key: ValueKey('category-${category.id}'),
            label: category.label,
            icon: category.icon,
            count: category.count(providers),
            selected: selected?.id == category.id,
            onTap: () => onSelected(category),
          ),
      ],
    ),
  );
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    super.key,
    required this.label,
    required this.icon,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 12),
    child: Semantics(
      button: true,
      selected: selected,
      label: '$label, $count ${count == 1 ? 'provider' : 'providers'}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: ExcludeSemantics(
          child: Container(
            width: 88,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
            decoration: BoxDecoration(
              color: selected ? CustomerHomeTheme.mint : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected
                    ? CustomerHomeTheme.primary
                    : CustomerHomeTheme.border,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 24, color: CustomerHomeTheme.primary),
                const SizedBox(height: 8),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: CustomerHomeTheme.text,
                    fontSize: 12.5,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$count',
                  style: const TextStyle(
                    color: CustomerHomeTheme.mutedText,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// One verified provider in the list.
class DirectoryProviderCard extends StatelessWidget {
  const DirectoryProviderCard({super.key, required this.provider});
  final Professional provider;

  @override
  Widget build(BuildContext context) {
    final p = provider;
    return AppCard(
      key: ValueKey('provider-card-${p.id}'),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => Material(
            child: ProviderDetailsScreen(providerId: p.id, initial: p),
          ),
        ),
      ),
      child: Row(
        children: [
          PersonAvatar(
            name: p.name,
            photoUrl: p.photoUrl,
            size: 56,
            verified: p.verified,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.title,
                ),
                if (p.specialty.isNotEmpty)
                  Text(
                    p.specialty,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body,
                  ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (p.rating != null)
                      StatusPill(
                        label: p.rating!.toStringAsFixed(1),
                        icon: Icons.star_rounded,
                        color: AppColors.navy,
                        background: AppColors.surfaceSage,
                      ),
                    if (p.reviewCount > 0)
                      Text(
                        '${p.reviewCount} ${p.reviewCount == 1 ? 'review' : 'reviews'}',
                        style: AppTypography.caption,
                      ),
                    if (p.providerCode != null)
                      Text(
                        'ID ${p.providerCode}',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(
            LucideIcons.chevronRight,
            size: 18,
            color: AppColors.muted,
          ),
        ],
      ),
    );
  }
}

/// The three states of the provider list (loading, nothing found, error).
class DirectoryMessage extends StatelessWidget {
  const DirectoryMessage({super.key, required this.text, this.icon});
  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: CustomerHomeTheme.border),
    ),
    child: Column(
      children: [
        if (icon != null) ...[
          Icon(icon, color: CustomerHomeTheme.primary, size: 28),
          const SizedBox(height: AppSpacing.xs),
        ],
        Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: CustomerHomeTheme.mutedText,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ],
    ),
  );
}
