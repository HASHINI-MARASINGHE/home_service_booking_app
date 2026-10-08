import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// One choice of an [AppSegmentedChoice].
class ChoiceOption<T> {
  const ChoiceOption({required this.value, required this.label, this.key});

  final T value;
  final String label;

  /// Set on the tappable area, for tests.
  final Key? key;
}

/// A row of 2 or 3 choices. The chosen one has a check, a thick blue border
/// and a pale fill, so it is never marked by color alone. Every choice is at
/// least 48 px tall and grows with the text.
class AppSegmentedChoice<T> extends StatelessWidget {
  const AppSegmentedChoice({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    required this.semanticsLabel,
  });

  final List<ChoiceOption<T>> options;
  final T selected;
  final ValueChanged<T> onChanged;

  /// Spoken name of the whole group, such as "Language".
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: semanticsLabel,
    child: IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _Choice(
                key: options[i].key,
                label: options[i].label,
                selected: options[i].value == selected,
                onTap: () => onChanged(options[i].value),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

class _Choice extends StatelessWidget {
  const _Choice({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = context.textStyles.label;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.button,
          child: Ink(
            decoration: BoxDecoration(
              color: selected ? AppColors.brand100 : AppColors.surface,
              borderRadius: AppRadius.button,
              border: Border.all(
                color: selected ? AppColors.brand700 : AppColors.borderControl,
                width: selected
                    ? AppSizes.borderSelected
                    : AppSizes.borderControl,
              ),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AppSizes.minTap,
                minWidth: AppSizes.minTap,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: AppSpacing.xs,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (selected) ...[
                      const Icon(
                        Icons.check,
                        size: AppSizes.iconButton,
                        color: AppColors.ink,
                      ),
                      const SizedBox(width: AppSpacing.space1),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: style.copyWith(color: AppColors.ink),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
