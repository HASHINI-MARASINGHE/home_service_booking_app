import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../l10n/l10n_context.dart';
import '../../../models/professional.dart';
import '../../../models/service_category.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/common/empty_state.dart';
import '../../../widgets/common/motion_widgets.dart';
import '../../../widgets/common/provider_card.dart';
import '../../../widgets/common/service_tile.dart';
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

  static const _tileWidth = 112.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    Widget tile({
      required Key key,
      required String label,
      required IconData icon,
      required int count,
      required bool isSelected,
      required VoidCallback onTap,
    }) => Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: ServiceTile(
        key: key,
        icon: icon,
        label: label,
        detail: '$count',
        selected: isSelected,
        semanticsLabel: l10n.categoryTileSemantics(label, count),
        width: _tileWidth,
        onTap: onTap,
      ),
    );

    // Tiles share one height that grows with the longest label, so longer
    // Sinhala names or larger text never get cut off.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            tile(
              key: const ValueKey('category-all'),
              label: l10n.categoryAll,
              icon: LucideIcons.layoutGrid,
              count: providers.length,
              isSelected: selected == null,
              onTap: () => onSelected(null),
            ),
            for (final category in ServiceCategory.all)
              tile(
                key: ValueKey('category-${category.id}'),
                label: category.localizedLabel(l10n),
                icon: category.icon,
                count: category.count(providers),
                isSelected: selected?.id == category.id,
                onTap: () => onSelected(category),
              ),
          ],
        ),
      ),
    );
  }
}

/// One verified provider in the list. [index] staggers the fade-in.
class DirectoryProviderCard extends StatelessWidget {
  const DirectoryProviderCard({
    super.key,
    required this.provider,
    this.index = 0,
  });

  final Professional provider;
  final int index;

  @override
  Widget build(BuildContext context) => FadeSlideIn(
    index: index,
    child: ProviderCard(
      key: ValueKey('provider-card-${provider.id}'),
      provider: provider,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => Material(
            child: ProviderDetailsScreen(
              providerId: provider.id,
              initial: provider,
            ),
          ),
        ),
      ),
    ),
  );
}

/// The states of the provider list when there is nothing to show (nothing
/// found, or an error). An optional button says what to do next.
class DirectoryMessage extends StatelessWidget {
  const DirectoryMessage({
    super.key,
    required this.title,
    required this.text,
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String text;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => EmptyState(
    title: title,
    message: text,
    icon: icon ?? Icons.inbox_outlined,
    actionLabel: actionLabel,
    onAction: onAction,
  );
}
