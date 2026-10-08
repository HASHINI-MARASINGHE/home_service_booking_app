import 'package:flutter/material.dart';

import '../../l10n/l10n_context.dart';
import '../../theme/app_theme.dart';
import 'motion_widgets.dart';

/// A big tile for choosing a kind of service: the icon on a soft blue tile
/// with its name under it. The chosen tile has a thick blue border, a check
/// and the word "Selected", so it is never marked by color alone.
class ServiceTile extends StatelessWidget {
  const ServiceTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.detail,
    this.semanticsLabel,
    this.width,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  /// A short line under the name, such as a count.
  final String? detail;

  /// What a screen reader says; defaults to [label].
  final String? semanticsLabel;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    return Semantics(
      button: true,
      selected: selected,
      label: semanticsLabel ?? label,
      onTap: onTap,
      excludeSemantics: true,
      child: SizedBox(
        width: width,
        child: AppPressable(
          child: Material(
            color: selected ? AppColors.brand50 : AppColors.surface,
            borderRadius: AppRadius.card,
            child: InkWell(
              onTap: onTap,
              borderRadius: AppRadius.card,
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: AppRadius.card,
                  border: Border.all(
                    color: selected
                        ? AppColors.brand700
                        : AppColors.borderSubtle,
                    width: selected
                        ? AppSizes.borderSelected
                        : AppSizes.borderControl,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: AppSpacing.sm,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: AppSizes.minTap,
                        height: AppSizes.minTap,
                        decoration: BoxDecoration(
                          color: AppColors.brand100,
                          borderRadius: AppRadius.button,
                        ),
                        child: Icon(
                          icon,
                          size: AppSizes.iconNav,
                          color: AppColors.brand700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        style: styles.label,
                      ),
                      if (detail != null)
                        Text(
                          detail!,
                          textAlign: TextAlign.center,
                          style: styles.caption,
                        ),
                      if (selected) ...[
                        const SizedBox(height: AppSpacing.space1),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check,
                              size: 20,
                              color: AppColors.brand900,
                            ),
                            const SizedBox(width: AppSpacing.space1),
                            Flexible(
                              child: Text(
                                context.l10n.selectedLabel,
                                style: styles.caption.copyWith(
                                  color: AppColors.brand900,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
