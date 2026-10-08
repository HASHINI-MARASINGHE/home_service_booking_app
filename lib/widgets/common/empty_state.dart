import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'app_buttons.dart';

/// Shown when there is nothing to list: a calm icon (or your own
/// illustration), a short title, one line of help, and an optional button
/// that says what to do next.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.illustration,
    this.actionLabel,
    this.onAction,
  }) : assert(
         (actionLabel == null) == (onAction == null),
         'Give both actionLabel and onAction, or neither.',
       );

  final String title;
  final String message;
  final IconData icon;

  /// Replaces the icon area when given.
  final Widget? illustration;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    return Semantics(
      container: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.card,
          border: Border.all(
            color: AppColors.borderSubtle,
            width: AppSizes.borderControl,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child:
                  illustration ??
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: AppColors.brand50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: AppSizes.iconNav + 8,
                      color: AppColors.brand700,
                    ),
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(title, textAlign: TextAlign.center, style: styles.h3),
            const SizedBox(height: AppSpacing.xs),
            Text(message, textAlign: TextAlign.center, style: styles.bodySmall),
            if (actionLabel != null) ...[
              const SizedBox(height: AppSpacing.md),
              AppSecondaryButton(label: actionLabel!, onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }
}
