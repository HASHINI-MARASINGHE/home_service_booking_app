import 'package:flutter/material.dart';

import '../../l10n/l10n_context.dart';
import '../../l10n/locale_controller.dart';

/// English / සිංහල switch. Each language is written in its own script (no
/// flags). The chosen one shows a check, a thick border and a fill, so it is
/// never marked by color alone.
class LanguageSwitch extends StatelessWidget {
  const LanguageSwitch({super.key});

  static const _ink = Color(0xFF101B2B);
  static const _selectedFill = Color(0xFFD8E6F7);
  static const _border = Color(0xFF5E6B7B);
  static const _selectedBorder = Color(0xFF134A96);

  static const _options = [
    (locale: Locale('en'), name: 'English'),
    (locale: Locale('si'), name: 'සිංහල'),
  ];

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: LocaleController.instance,
    builder: (context, _) {
      final current = LocaleController.instance.locale;
      return Semantics(
        container: true,
        label: context.l10n.languageSwitchLabel,
        child: Row(
          key: const ValueKey('language-switch'),
          children: [
            for (var i = 0; i < _options.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(
                child: _LanguageOption(
                  name: _options[i].name,
                  selected:
                      _options[i].locale.languageCode == current.languageCode,
                  onTap: () =>
                      LocaleController.instance.setLocale(_options[i].locale),
                ),
              ),
            ],
          ],
        ),
      );
    },
  );
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.name,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: name,
    excludeSemantics: true,
    onTap: onTap,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('language-$name'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            color: selected ? LanguageSwitch._selectedFill : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? LanguageSwitch._selectedBorder
                  : LanguageSwitch._border,
              width: 2,
            ),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (selected) ...[
                    const Icon(
                      Icons.check,
                      size: 22,
                      color: LanguageSwitch._ink,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(
                      name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: LanguageSwitch._ink,
                        fontSize: 16,
                        height: 1.5,
                        letterSpacing: 0,
                        fontWeight: FontWeight.w700,
                      ),
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
