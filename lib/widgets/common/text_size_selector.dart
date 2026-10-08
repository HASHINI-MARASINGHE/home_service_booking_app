import 'package:flutter/material.dart';

import '../../l10n/l10n_context.dart';
import '../../theme/text_size_controller.dart';
import 'segmented_choice.dart';

/// Normal / Large / Extra large. The choice is saved and every screen uses it
/// at once.
class TextSizeSelector extends StatelessWidget {
  const TextSizeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListenableBuilder(
      listenable: TextSizeController.instance,
      builder: (context, _) => KeyedSubtree(
        key: const ValueKey('text-size-selector'),
        child: AppSegmentedChoice<AppTextSize>(
          options: [
            ChoiceOption(
              value: AppTextSize.normal,
              label: l10n.textSizeNormal,
              key: const ValueKey('text-size-normal'),
            ),
            ChoiceOption(
              value: AppTextSize.large,
              label: l10n.textSizeLarge,
              key: const ValueKey('text-size-large'),
            ),
            ChoiceOption(
              value: AppTextSize.extraLarge,
              label: l10n.textSizeExtraLarge,
              key: const ValueKey('text-size-extra-large'),
            ),
          ],
          selected: TextSizeController.instance.size,
          onChanged: TextSizeController.instance.setSize,
          semanticsLabel: l10n.textSizeLabel,
        ),
      ),
    );
  }
}
