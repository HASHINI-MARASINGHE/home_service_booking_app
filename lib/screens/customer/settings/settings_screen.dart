import 'package:flutter/material.dart';

import '../../../l10n/locale_controller.dart';
import '../../../models/app_user.dart';
import '../../../services/auth_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/customer_home_theme.dart';
import '../../../theme/text_size_controller.dart';
import '../addresses/my_addresses_screen.dart';
import 'help_support_screen.dart';
import 'language_settings_screen.dart';
import 'notification_settings_screen.dart';
import 'payment_methods_screen.dart';
import 'privacy_security_screen.dart';
import 'text_size_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.user,
    required this.authService,
  });

  final AppUser user;
  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        LocaleController.instance,
        TextSizeController.instance,
      ]),
      builder: (context, _) {
        final currentLocale = LocaleController.instance.locale;
        final currentSize = TextSizeController.instance.size;
        final isSinhala = currentLocale.languageCode == 'si';
        final isTamil = currentLocale.languageCode == 'ta';

        final languageLabel = isTamil
            ? 'தமிழ்'
            : (isSinhala ? 'සිංහල' : 'English');
        final sizeLabel = switch (currentSize) {
          AppTextSize.normal => isTamil
              ? 'இயல்பானது'
              : (isSinhala ? 'සාමාන්‍ය' : 'Normal'),
          AppTextSize.large => isTamil
              ? 'பெரியது'
              : (isSinhala ? 'විශාල' : 'Large'),
          AppTextSize.extraLarge => isTamil
              ? 'மிகப் பெரியது'
              : (isSinhala ? 'ඉතා විශාල' : 'Extra Large'),
        };

        final screenTitle = isTamil
            ? 'அமைப்புகள்'
            : (isSinhala ? 'සැකසුම්' : 'Settings');

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            foregroundColor: CustomerHomeTheme.primaryDark,
            elevation: 0,
            title: Text(
              screenTitle,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screen,
                vertical: AppSpacing.md,
              ),
              children: [
                _SectionTitle(title: isSinhala ? 'මනාප' : 'PREFERENCES'),
                const SizedBox(height: 10),
                _SettingsCard(
                  children: [
                    _SettingsTile(
                      key: const ValueKey('settings-nav-language'),
                      icon: Icons.translate_rounded,
                      title: isSinhala ? 'භාෂාව' : 'Language',
                      subtitle: languageLabel,
                      trailingBadge: languageLabel,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const LanguageSettingsScreen(),
                        ),
                      ),
                    ),
                    const Divider(
                      height: 1,
                      indent: 72,
                      color: CustomerHomeTheme.border,
                    ),
                    _SettingsTile(
                      key: const ValueKey('settings-nav-text-size'),
                      icon: Icons.format_size_rounded,
                      title: isSinhala
                          ? 'පෙනුම / අකුරු ප්‍රමාණය'
                          : 'Appearance / Accessibility',
                      subtitle: '$sizeLabel text scale',
                      trailingBadge: sizeLabel,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const TextSizeSettingsScreen(),
                        ),
                      ),
                    ),
                    const Divider(
                      height: 1,
                      indent: 72,
                      color: CustomerHomeTheme.border,
                    ),
                    _SettingsTile(
                      key: const ValueKey('settings-nav-notifications'),
                      icon: Icons.notifications_none_rounded,
                      title: isSinhala ? 'දැනුම්දීම්' : 'Notifications',
                      subtitle: isSinhala
                          ? 'දැනුම්දීම් විකල්ප සකසන්න'
                          : 'Manage alerts & push preferences',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const NotificationSettingsScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                _SectionTitle(
                  title: isSinhala ? 'ගිණුම සහ ආරක්ෂාව' : 'ACCOUNT & SECURITY',
                ),
                const SizedBox(height: 10),
                _SettingsCard(
                  children: [
                    _SettingsTile(
                      icon: Icons.location_on_outlined,
                      title: isSinhala ? 'සුරැකි ලිපින' : 'Saved Addresses',
                      subtitle: isSinhala
                          ? 'සේවා ස්ථාන කළමනාකරණය'
                          : 'Manage delivery & home locations',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const MyAddressesScreen(),
                        ),
                      ),
                    ),
                    const Divider(
                      height: 1,
                      indent: 72,
                      color: CustomerHomeTheme.border,
                    ),
                    _SettingsTile(
                      icon: Icons.credit_card_outlined,
                      title: isSinhala ? 'ගෙවීම් ක්‍රම' : 'Payment Methods',
                      subtitle: isSinhala
                          ? 'කාඩ්පත් සහ ගෙවීම් විකල්ප'
                          : 'Cards, Cash on Service',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const PaymentMethodsScreen(),
                        ),
                      ),
                    ),
                    const Divider(
                      height: 1,
                      indent: 72,
                      color: CustomerHomeTheme.border,
                    ),
                    _SettingsTile(
                      icon: Icons.security_outlined,
                      title:
                          isSinhala ? 'පෞද්ගලිකත්වය සහ ආරක්ෂාව' : 'Privacy & Security',
                      subtitle: isSinhala
                          ? 'මුරපදය, ගිණුම් ආරක්ෂාව'
                          : 'Change password, security & account',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PrivacySecurityScreen(
                            authService: authService,
                            userEmail: user.email,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                _SectionTitle(
                  title: isSinhala ? 'සහාය සහ නීතිමය' : 'SUPPORT & LEGAL',
                ),
                const SizedBox(height: 10),
                _SettingsCard(
                  children: [
                    _SettingsTile(
                      icon: Icons.help_outline_rounded,
                      title: isSinhala ? 'උදව් සහ සහාය' : 'Help & Support',
                      subtitle: isSinhala
                          ? 'නිතර අසන ප්‍රශ්න සහ පාරිභෝගික සහාය'
                          : 'FAQs, contact support, report problem',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const HelpSupportScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: CustomerHomeTheme.mutedText,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
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
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: Column(children: children),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailingBadge,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? trailingBadge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        leading: Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            color: CustomerHomeTheme.mint,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: CustomerHomeTheme.primary, size: 21),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: CustomerHomeTheme.text,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            subtitle,
            style: const TextStyle(
              color: CustomerHomeTheme.mutedText,
              fontSize: 13,
            ),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailingBadge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.brand100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  trailingBadge!,
                  style: const TextStyle(
                    color: CustomerHomeTheme.primaryDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
            const Icon(
              Icons.chevron_right,
              color: CustomerHomeTheme.mutedText,
              size: 20,
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
