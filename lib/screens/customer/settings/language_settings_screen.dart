import 'package:flutter/material.dart';

import '../../../l10n/locale_controller.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/customer_home_theme.dart';

class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleController.instance,
      builder: (context, _) {
        final currentLocale = LocaleController.instance.locale;
        final isSinhala = currentLocale.languageCode == 'si';
        final isTamil = currentLocale.languageCode == 'ta';

        String title() {
          if (isTamil) return 'மொழி';
          if (isSinhala) return 'භාෂාව';
          return 'Language';
        }

        String heading() {
          if (isTamil) return 'உங்கள் மொழியைத் தேர்ந்தெடுக்கவும்';
          if (isSinhala) return 'යෙදුමේ භාෂාව තෝරන්න';
          return 'Choose your preferred language';
        }

        String subtitle() {
          if (isTamil) {
            return 'தேர்ந்தெடுக்கப்பட்ட மொழி பயன்பாடு முழுவதும் பயன்படுத்தப்படும்.';
          }
          if (isSinhala) {
            return 'තෝරාගත් භාෂාව මුළු යෙදුම පුරාම ක්‍රියාත්මක වේ.';
          }
          return 'The selected language will be applied across the entire app.';
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            foregroundColor: CustomerHomeTheme.primaryDark,
            elevation: 0,
            title: Text(
              title(),
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
                  heading(),
                  style: const TextStyle(
                    color: CustomerHomeTheme.primaryDark,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle(),
                  style: const TextStyle(
                    color: CustomerHomeTheme.mutedText,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                _LanguageTile(
                  key: const ValueKey('settings-language-english'),
                  title: 'English',
                  nativeTitle: 'English (US / UK)',
                  selected: currentLocale.languageCode == 'en',
                  onTap: () async {
                    await LocaleController.instance.setLocale(
                      const Locale('en'),
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Language set to English.'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                _LanguageTile(
                  key: const ValueKey('settings-language-sinhala'),
                  title: 'සිංහල',
                  nativeTitle: 'Sinhala (Sri Lanka)',
                  selected: currentLocale.languageCode == 'si',
                  onTap: () async {
                    await LocaleController.instance.setLocale(
                      const Locale('si'),
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('භාෂාව සිංහල ලෙස වෙනස් කරන ලදී.'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                _LanguageTile(
                  key: const ValueKey('settings-language-tamil'),
                  title: 'தமிழ்',
                  nativeTitle: 'Tamil (Sri Lanka)',
                  selected: currentLocale.languageCode == 'ta',
                  onTap: () async {
                    await LocaleController.instance.setLocale(
                      const Locale('ta'),
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('மொழி தமிழாக மாற்றப்பட்டது.'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    super.key,
    required this.title,
    required this.nativeTitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String nativeTitle;
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
            color: selected ? AppColors.brand50 : Colors.white,
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
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.brand700.withValues(alpha: 0.12)
                      : AppColors.brand50,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.translate_rounded,
                    color: selected
                        ? AppColors.brand700
                        : AppColors.brand600,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
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
                      nativeTitle,
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
