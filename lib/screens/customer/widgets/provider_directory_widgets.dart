import 'package:flutter/material.dart';

import '../../../l10n/l10n_context.dart';
import '../../../models/professional.dart';
import '../../../models/service_category.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/common/empty_state.dart';
import '../../../widgets/common/motion_widgets.dart';
import '../../../widgets/common/provider_card.dart';
import '../../../widgets/common/service_category_card.dart';
import '../providers/provider_details_screen.dart';

/// How the service cards are ordered: as listed, by number of providers, or
/// by the average rating of the providers in each service.
enum _CardOrder { all, popular, topRated }

/// A row of filter chips (All, Popular, Top rated) above one photo card per
/// service; tapping a card filters the provider list.
class CategoryRow extends StatefulWidget {
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
  State<CategoryRow> createState() => _CategoryRowState();
}

class _CategoryRowState extends State<CategoryRow> {
  _CardOrder _order = _CardOrder.all;

  double _averageRating(ServiceCategory category) {
    final rated = [
      for (final p in widget.providers)
        if (category.matches(p) && p.rating != null) p.rating!,
    ];
    return rated.isEmpty ? -1 : rated.reduce((a, b) => a + b) / rated.length;
  }

  List<ServiceCategory> get _categories {
    final list = [...ServiceCategory.all];
    switch (_order) {
      case _CardOrder.all:
        break;
      case _CardOrder.popular:
        list.sort(
          (a, b) =>
              b.count(widget.providers).compareTo(a.count(widget.providers)),
        );
      case _CardOrder.topRated:
        list.sort((a, b) => _averageRating(b).compareTo(_averageRating(a)));
    }
    return list;
  }

  /// Chip text; the language is the app's (English, Sinhala or Tamil).
  String _chipLabel(BuildContext context, _CardOrder order) {
    final code = Localizations.localeOf(context).languageCode;
    return switch (order) {
      _CardOrder.all => context.l10n.categoryAll,
      _CardOrder.popular => switch (code) {
        'si' => 'ජනප්‍රිය',
        'ta' => 'பிரபலமானவை',
        _ => 'Popular',
      },
      _CardOrder.topRated => switch (code) {
        'si' => 'ඉහළම ශ්‍රේණිගත',
        'ta' => 'அதிக மதிப்பீடு',
        _ => 'Top rated',
      },
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final styles = context.textStyles;
    final primary = Theme.of(context).colorScheme.primary;

    Widget chip(_CardOrder order, {Key? key, String? trailing}) {
      final isSelected = _order == order;
      final color = isSelected ? Colors.white : AppColors.ink2;
      final textStyle = styles.label.copyWith(
        color: color,
        fontWeight: FontWeight.w700,
      );
      return Padding(
        padding: const EdgeInsets.only(right: AppSpacing.xs),
        child: Semantics(
          button: true,
          selected: isSelected,
          excludeSemantics: true,
          label: _chipLabel(context, order),
          onTap: () => _pick(order),
          child: Material(
            color: isSelected ? primary : AppColors.surface,
            shape: StadiumBorder(
              side: BorderSide(
                color: isSelected ? primary : AppColors.borderSubtle,
              ),
            ),
            child: InkWell(
              key: key,
              customBorder: const StadiumBorder(),
              onTap: () => _pick(order),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: AppSizes.minTap),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_chipLabel(context, order), style: textStyle),
                      if (trailing != null) Text(' $trailing', style: textStyle),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              chip(
                _CardOrder.all,
                key: const ValueKey('category-all'),
                trailing: '(${ServiceCategory.all.length})',
              ),
              chip(_CardOrder.popular, key: const ValueKey('order-popular')),
              chip(_CardOrder.topRated, key: const ValueKey('order-top-rated')),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: [
              for (final category in _categories)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: ServiceCategoryCard(
                    key: ValueKey('category-${category.id}'),
                    category: category,
                    label: category.localizedLabel(l10n),
                    detail: l10n.providerCount(category.count(widget.providers)),
                    selected: widget.selected?.id == category.id,
                    semanticsLabel: l10n.categoryTileSemantics(
                      category.localizedLabel(l10n),
                      category.count(widget.providers),
                    ),
                    onTap: () => widget.onSelected(category),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// "All" also clears the chosen service; the other two only reorder.
  void _pick(_CardOrder order) {
    setState(() => _order = order);
    if (order == _CardOrder.all) widget.onSelected(null);
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
