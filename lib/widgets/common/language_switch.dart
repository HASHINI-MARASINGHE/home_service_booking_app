import 'package:flutter/material.dart';

import '../../l10n/l10n_context.dart';
import '../../l10n/locale_controller.dart';
import 'segmented_choice.dart';

/// English / සිංහල switch. Each language is written in its own script (no
/// flags). The chosen one shows a check, a thick border and a fill.
class LanguageSwitch extends StatelessWidget {
  const LanguageSwitch({super.key});

  static const _options = [
    ChoiceOption(
      value: Locale('en'),
      label: 'English',
      key: ValueKey('language-English'),
    ),
    ChoiceOption(
      value: Locale('si'),
      label: 'සිංහල',
      key: ValueKey('language-සිංහල'),
    ),
    ChoiceOption(
      value: Locale('ta'),
      label: 'தமிழ்',
      key: ValueKey('language-தமிழ்'),
    ),
  ];

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: LocaleController.instance,
    builder: (context, _) => KeyedSubtree(
      key: const ValueKey('language-switch'),
      child: AppSegmentedChoice<Locale>(
        options: _options,
        selected: LocaleController.instance.locale,
        onChanged: LocaleController.instance.setLocale,
        semanticsLabel: context.l10n.languageSwitchLabel,
      ),
    ),
  );
}
