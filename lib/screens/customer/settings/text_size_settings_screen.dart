import 'package:flutter/material.dart';

import '../../../l10n/locale_controller.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/customer_home_theme.dart';
import '../../../theme/text_size_controller.dart';

class TextSizeSettingsScreen extends StatelessWidget {
  const TextSizeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: TextSizeController.instance,
      builder: (context, _) {
        final currentSize = TextSizeController.instance.size;
        final isSinhala =
            LocaleController.instance.locale.languageCode == 'si';

        return Scaffold(
          backgroundColor: CustomerHomeTheme.background,
          appBar: AppBar(
            backgroundColor: CustomerHomeTheme.background,
            foregroundColor: CustomerHomeTheme.primaryDark,
            elevation: 0,
            title: Text(
              isSinhala ? 'අකුරු ප්‍රමාණය' : 'Text Size',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screen,
                vertical: AppSpacing.lg,
              ),
              children: [
                Text(
                  isSinhala
                      ? 'අකුරු ප්‍රමාණය සකසන්න'
                      : 'Choose your text size',
                  style: const TextStyle(
                    color: CustomerHomeTheme.primaryDark,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isSinhala
                      ? 'ඔබ තෝරන ප්‍රමාණය යෙදුමේ සියලු තිර සඳහා වහාම ක්‍රියාත්මක වේ.'
                      : 'Adjust text size for comfortable reading throughout the entire app.',
                  style: const TextStyle(
                    color: CustomerHomeTheme.mutedText,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                // Live preview container
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: CustomerHomeTheme.border),
                    boxShadow: const [
                      BoxShadow(
                        color: CustomerHomeTheme.shadow,
                        blurRadius: 16,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.format_size_rounded,
                            size: 20,
                            color: AppColors.brand700,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isSinhala ? 'පෙරදසුන' : 'Preview',
                            style: const TextStyle(
                              color: CustomerHomeTheme.mutedText,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isSinhala
                            ? 'විශ්වාසවන්ත වෘත්තිකයන් ඔබේ නිවසටම.'
                            : 'Reliable home services at your doorstep.',
                        style: const TextStyle(
                          color: CustomerHomeTheme.text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isSinhala
                            ? 'ජල නළ, විදුලි වැඩ සහ සියලු නිවාස අවශ්‍යතා සඳහා පළපුරුදු ශිල්පීන් පහසුවෙන්ම වෙන්කරවා ගන්න.'
                            : 'Book trusted electricians, plumbers, and technicians easily in just a few taps.',
                        style: const TextStyle(
                          color: CustomerHomeTheme.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                _TextSizeTile(
                  key: const ValueKey('settings-text-size-normal'),
                  label: isSinhala ? 'සාමාන්‍ය' : 'Normal',
                  description: isSinhala
                      ? 'පෙරනිමි සම්මත අකුරු ප්‍රමාණය'
                      : 'Default standard text size (100%)',
                  selected: currentSize == AppTextSize.normal,
                  onTap: () =>
                      TextSizeController.instance.setSize(AppTextSize.normal),
                ),
                const SizedBox(height: AppSpacing.md),
                _TextSizeTile(
                  key: const ValueKey('settings-text-size-large'),
                  label: isSinhala ? 'විශාල' : 'Large',
                  description: isSinhala
                      ? 'වඩාත් පැහැදිලි විශාල අකුරු'
                      : 'Larger text for easier reading (122%)',
                  selected: currentSize == AppTextSize.large,
                  onTap: () =>
                      TextSizeController.instance.setSize(AppTextSize.large),
                ),
                const SizedBox(height: AppSpacing.md),
                _TextSizeTile(
                  key: const ValueKey('settings-text-size-extralarge'),
                  label: isSinhala ? 'ඉතා විශාල' : 'Extra Large',
                  description: isSinhala
                      ? 'උපරිම ප්‍රමාණයේ අකුරු'
                      : 'Maximum accessibility text scale (150%)',
                  selected: currentSize == AppTextSize.extraLarge,
                  onTap: () => TextSizeController.instance.setSize(
                    AppTextSize.extraLarge,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TextSizeTile extends StatelessWidget {
  const _TextSizeTile({
    super.key,
    required this.label,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: selected ? AppColors.brand100 : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.brand700 : CustomerHomeTheme.border,
              width: selected ? 2.0 : 1.0,
            ),
            boxShadow: const [
              BoxShadow(
                color: CustomerHomeTheme.shadow,
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: selected
                            ? AppColors.brand900
                            : CustomerHomeTheme.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: const TextStyle(
                        color: CustomerHomeTheme.mutedText,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? AppColors.brand700 : Colors.transparent,
                  border: Border.all(
                    color: selected
                        ? AppColors.brand700
                        : CustomerHomeTheme.mutedText.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 16,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
