import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/app_theme.dart';
import 'motion_widgets.dart';

/// The one filled blue button of a screen. 56 px tall, full width by
/// default, darker blue while pressed, with a thick outline for keyboard
/// focus. When it is not ready, give [disabledReason] so the person knows
/// what to do next.
class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.semanticsLabel,
    this.disabledReason,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  /// What a screen reader says; defaults to [label].
  final String? semanticsLabel;

  /// Shown under the button while it is disabled, such as "Choose a time to
  /// continue".
  final String? disabledReason;
  final bool expand;

  @override
  Widget build(BuildContext context) => _ButtonFrame(
    label: label,
    semanticsLabel: semanticsLabel,
    onPressed: onPressed,
    expand: expand,
    disabledReason: onPressed == null ? disabledReason : null,
    button: icon == null
        ? FilledButton(onPressed: onPressed, child: _Label(label))
        : FilledButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: AppSizes.iconButton),
            label: _Label(label),
          ),
  );
}

/// Second choice: a white button with a thick blue outline.
class AppSecondaryButton extends StatelessWidget {
  const AppSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.semanticsLabel,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final String? semanticsLabel;
  final bool expand;

  @override
  Widget build(BuildContext context) => _ButtonFrame(
    label: label,
    semanticsLabel: semanticsLabel,
    onPressed: onPressed,
    expand: expand,
    button: icon == null
        ? OutlinedButton(onPressed: onPressed, child: _Label(label))
        : OutlinedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: AppSizes.iconButton),
            label: _Label(label),
          ),
  );
}

/// A risky action, such as cancelling. Red, always with an icon and a word,
/// and never the first choice.
class AppDangerButton extends StatelessWidget {
  const AppDangerButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = LucideIcons.octagonX,
    this.semanticsLabel,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData icon;
  final String? semanticsLabel;
  final bool expand;

  @override
  Widget build(BuildContext context) => _ButtonFrame(
    label: label,
    semanticsLabel: semanticsLabel,
    onPressed: onPressed,
    expand: expand,
    button: FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: AppSizes.iconButton),
      label: _Label(label),
      style:
          FilledButton.styleFrom(
            backgroundColor: AppColors.errorSolid,
            foregroundColor: AppColors.surface,
          ).copyWith(
            backgroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.disabled)
                  ? AppColors.surfaceAlt
                  : states.contains(WidgetState.pressed)
                  ? AppColors.errorText
                  : AppColors.errorSolid,
            ),
          ),
    ),
  );
}

/// Text that wraps onto more lines instead of shrinking.
class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, textAlign: TextAlign.center, softWrap: true);
}

/// Shared by all three buttons: one spoken label, the pressed-scale effect,
/// full width, and an optional reason under a disabled button.
class _ButtonFrame extends StatelessWidget {
  const _ButtonFrame({
    required this.label,
    required this.semanticsLabel,
    required this.onPressed,
    required this.expand,
    required this.button,
    this.disabledReason,
  });

  final String label;
  final String? semanticsLabel;
  final VoidCallback? onPressed;
  final bool expand;
  final Widget button;
  final String? disabledReason;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    Widget result = Semantics(
      button: true,
      enabled: enabled,
      label: semanticsLabel ?? label,
      onTap: onPressed,
      excludeSemantics: true,
      child: AppPressable(enabled: enabled, child: button),
    );
    if (expand) result = SizedBox(width: double.infinity, child: result);
    if (disabledReason == null) return result;
    return Column(
      crossAxisAlignment: expand
          ? CrossAxisAlignment.stretch
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        result,
        const SizedBox(height: AppSpacing.xs),
        Text(disabledReason!, style: context.textStyles.caption),
      ],
    );
  }
}
