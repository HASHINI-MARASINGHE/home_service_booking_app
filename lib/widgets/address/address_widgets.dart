import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../models/address.dart';
import '../../theme/app_theme.dart';
import '../common/app_widgets.dart';

/// Icon and tile colors for each address type.
(IconData, Color, Color) addressTypeStyle(AddressType type) => switch (type) {
  AddressType.home => (
    LucideIcons.home,
    AppColors.primary,
    AppColors.primarySoft,
  ),
  AddressType.office => (
    LucideIcons.building2,
    AppColors.navy,
    AppColors.surfaceLavender,
  ),
  AddressType.parents => (
    LucideIcons.heart,
    AppColors.warning,
    AppColors.peach,
  ),
  AddressType.other => (
    LucideIcons.mapPin,
    AppColors.body,
    AppColors.surfaceLavender,
  ),
};

/// Horizontal pill chips (Home / Office / Parents / Other, or filters).
class ChoiceChips<T> extends StatelessWidget {
  const ChoiceChips({
    super.key,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
    this.iconOf,
  });

  final List<T> values;
  final T selected;
  final String Function(T) labelOf;
  final IconData? Function(T)? iconOf;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    clipBehavior: Clip.none,
    child: Row(
      children: [
        for (final value in values)
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: _Chip(
              label: labelOf(value),
              icon: iconOf?.call(value),
              selected: value == selected,
              onTap: () => onSelected(value),
            ),
          ),
      ],
    ),
  );
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : AppColors.body;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? AppColors.primary : AppColors.surface,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: fg),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: fg,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Saved-address card from the My Addresses design.
class AddressCard extends StatelessWidget {
  const AddressCard({
    super.key,
    required this.address,
    required this.activeJobs,
    required this.onEdit,
    required this.onDelete,
    required this.onSetDefault,
  });

  final Address address;
  final int activeJobs;
  final VoidCallback onEdit, onDelete, onSetDefault;

  @override
  Widget build(BuildContext context) {
    final a = address;
    final (icon, fg, bg) = addressTypeStyle(a.type);
    return ClipRRect(
      borderRadius: AppRadius.card,
      child: AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (a.isDefault) Container(height: 4, color: AppColors.primary),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.xxs,
                AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconTile(icon: icon, color: fg, background: bg),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(a.label, style: AppTypography.title),
                                if (a.isDefault)
                                  const StatusPill(label: 'Default'),
                                if (activeJobs > 0)
                                  StatusPill(
                                    label:
                                        '$activeJobs Active Job'
                                        '${activeJobs == 1 ? '' : 's'}',
                                    color: AppColors.warning,
                                    background: AppColors.warningSoft,
                                  ),
                              ],
                            ),
                            if (a.area.isNotEmpty)
                              Text(a.area, style: AppTypography.caption),
                          ],
                        ),
                      ),
                      _AddressMenu(
                        address: a,
                        onEdit: onEdit,
                        onDelete: onDelete,
                        onSetDefault: onSetDefault,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLavender,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _IconLine(
                            icon: LucideIcons.mapPin,
                            text: a.fullAddress,
                            style: AppTypography.bodyStrong.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (a.landmark.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            _IconLine(
                              icon: LucideIcons.navigation,
                              text: a.landmark,
                              style: AppTypography.caption,
                              indent: true,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: Row(
                      children: [
                        Expanded(
                          child: a.isDefault
                              ? Row(
                                  children: [
                                    const Icon(
                                      LucideIcons.checkCircle,
                                      size: 16,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        'Rapid dispatch ready',
                                        style: AppTypography.caption.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Align(
                                  alignment: Alignment.centerLeft,
                                  child: TextButton.icon(
                                    onPressed: onSetDefault,
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    icon: const Icon(
                                      LucideIcons.circle,
                                      size: 16,
                                    ),
                                    label: const Text('Set as Default'),
                                  ),
                                ),
                        ),
                        _SmallAction(
                          icon: LucideIcons.pencil,
                          label: 'Edit',
                          onTap: onEdit,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        _SmallAction(
                          icon: LucideIcons.trash2,
                          tooltip: 'Delete ${a.label}',
                          onTap: onDelete,
                          danger: true,
                        ),
                      ],
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
}

class _IconLine extends StatelessWidget {
  const _IconLine({
    required this.icon,
    required this.text,
    required this.style,
    this.indent = false,
  });

  final IconData icon;
  final String text;
  final TextStyle style;
  final bool indent;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(left: indent ? AppSpacing.md : 0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 15, color: AppColors.primary),
        ),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: style)),
      ],
    ),
  );
}

class _SmallAction extends StatelessWidget {
  const _SmallAction({
    required this.icon,
    required this.onTap,
    this.label,
    this.tooltip,
    this.danger = false,
  });

  final IconData icon;
  final String? label, tooltip;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.danger : AppColors.primary;
    final child = Material(
      color: danger ? AppColors.dangerSoft : AppColors.surfaceLavender,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: label == null ? 10 : 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: color),
                if (label != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    label!,
                    style: AppTypography.label.copyWith(color: color),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    return tooltip == null ? child : Tooltip(message: tooltip!, child: child);
  }
}

class _AddressMenu extends StatelessWidget {
  const _AddressMenu({
    required this.address,
    required this.onEdit,
    required this.onDelete,
    required this.onSetDefault,
  });

  final Address address;
  final VoidCallback onEdit, onDelete, onSetDefault;

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
    tooltip: 'More actions',
    icon: const Icon(LucideIcons.moreVertical, color: AppColors.body),
    shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
    onSelected: (value) => switch (value) {
      'edit' => onEdit(),
      'default' => onSetDefault(),
      _ => onDelete(),
    },
    itemBuilder: (_) => [
      const PopupMenuItem(value: 'edit', child: Text('Edit address')),
      if (!address.isDefault)
        const PopupMenuItem(value: 'default', child: Text('Set as default')),
      const PopupMenuItem(
        value: 'delete',
        child: Text('Delete', style: TextStyle(color: AppColors.danger)),
      ),
    ],
  );
}
