import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/app_theme.dart';

/// A text field with its label always visible above it (never only a hint).
/// 56 px tall, with a thick grey border that turns thick blue when focused.
/// An error shows an icon and words under the field, in red.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.fieldKey,
    this.controller,
    this.hintText,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffix,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.enabled = true,
    this.maxLines = 1,
    this.onChanged,
    this.onSubmitted,
  });

  final String label;

  /// Key of the inner text field, for tests.
  final Key? fieldKey;
  final TextEditingController? controller;
  final String? hintText;
  final String? helperText;

  /// When set, the field turns red and says what to fix.
  final String? errorText;
  final IconData? prefixIcon;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool enabled;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(child: Text(label, style: styles.label)),
        const SizedBox(height: AppSpacing.xs),
        Semantics(
          label: label,
          textField: true,
          child: TextField(
            key: fieldKey,
            controller: controller,
            enabled: enabled,
            obscureText: obscureText,
            maxLines: obscureText ? 1 : maxLines,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            style: styles.bodyLarge,
            decoration: InputDecoration(
              hintText: hintText,
              helperText: helperText,
              helperMaxLines: 3,
              error: errorText == null
                  ? null
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          LucideIcons.octagonX,
                          size: 20,
                          color: AppColors.errorText,
                        ),
                        const SizedBox(width: AppSpacing.space1 + 2),
                        Expanded(
                          child: Text(
                            errorText!,
                            style: styles.caption.copyWith(
                              color: AppColors.errorText,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
              prefixIcon: prefixIcon == null
                  ? null
                  : Icon(prefixIcon, size: AppSizes.iconButton),
              suffixIcon: suffix,
            ),
          ),
        ),
      ],
    );
  }
}
