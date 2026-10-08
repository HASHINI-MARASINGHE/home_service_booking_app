import 'package:flutter/material.dart';

import '../../l10n/locale_controller.dart';
import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/customer_home_theme.dart';
import '../../theme/text_size_controller.dart';
import 'addresses/my_addresses_screen.dart';
import 'customer_scope.dart';
import 'edit_profile_screen.dart';
import 'settings/help_support_screen.dart';
import 'settings/language_settings_screen.dart';
import 'settings/notification_settings_screen.dart';
import 'settings/payment_methods_screen.dart';
import 'settings/privacy_security_screen.dart';
import 'settings/settings_screen.dart';
import 'settings/text_size_settings_screen.dart';
import 'widgets/customer_home_widgets.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({
    super.key,
    required this.uid,
    required this.authService,
    this.onUserUpdated,
  });

  final String uid;
  final AuthService authService;
  final ValueChanged<AppUser>? onUserUpdated;

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  late Future<AppUser?> _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    _profile = widget.authService.getUserProfile(widget.uid);
  }

  void _retry() {
    setState(_loadProfile);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<AppUser?>(
    future: _profile,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError || snapshot.data == null) {
        return _ProfileError(onRetry: _retry, hasError: snapshot.hasError);
      }
      return _ProfileContent(
        user: snapshot.data!,
        authService: widget.authService,
        onEdit: () => _openEditProfile(snapshot.data!),
      );
    },
  );

  Future<void> _openEditProfile(AppUser user) async {
    final updated = await Navigator.of(context).push<AppUser>(
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          user: user,
          authService: widget.authService,
          onUserUpdated: (u) {
            widget.onUserUpdated?.call(u);
            if (mounted) setState(_loadProfile);
          },
        ),
      ),
    );
    if (!mounted || updated == null) return;
    setState(_loadProfile);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated successfully.')),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({
    required this.user,
    required this.authService,
    required this.onEdit,
  });

  final AppUser user;
  final AuthService authService;
  final VoidCallback onEdit;

  void _showPersonalInfoDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Personal Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoRow(label: 'Full Name', value: _valueOrFallback(user.name)),
            const Divider(height: 18),
            _InfoRow(label: 'Email', value: _valueOrFallback(user.email)),
            const Divider(height: 18),
            _InfoRow(
              label: 'Phone',
              value: user.phone != null && user.phone!.trim().isNotEmpty
                  ? user.phone!
                  : 'Not provided',
            ),
            const Divider(height: 18),
            _InfoRow(
              label: 'Account Role',
              value: _accountLabel(user.role),
            ),
            const Divider(height: 18),
            _InfoRow(
              label: 'Customer ID',
              value: user.uid.length > 12
                  ? '${user.uid.substring(0, 10)}...'
                  : user.uid,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              onEdit();
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  void _showTermsDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Terms & Conditions'),
        content: const SingleChildScrollView(
          child: Text(
            '1. Services & Bookings\nHomeCare connects customers with independent service providers. By booking a service, you agree to provide safe access to the premises and accurate service descriptions.\n\n'
            '2. Pricing & Payments\nAll payments are calculated based on transparent standard rates and agreed line items. Cash on Service or in-app card payments are released upon customer confirmation of satisfactory job completion.\n\n'
            '3. Cancellation Policy\nFree cancellation is available up to 2 hours before the scheduled appointment time. Cancellations after provider dispatch may incur a nominal arrival fee.\n\n'
            '4. Dispute Resolution\nDisputes must be reported within 48 hours of service completion via the booking history receipt.',
            style: TextStyle(
              fontSize: 14,
              color: CustomerHomeTheme.text,
              height: 1.45,
            ),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('I Understand'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicyDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            '1. Information We Collect\nWe collect your name, email, phone number, and service addresses solely to coordinate bookings between you and trusted service providers.\n\n'
            '2. Location Data\nLocation coordinates are collected only when adding an address or requesting dispatch, and are never sold or shared with advertisers.\n\n'
            '3. Security & Payments\nPayment card credentials are encrypted with bank-grade 256-bit encryption through our certified PCI-DSS compliant processor. CVV numbers are never retained.\n\n'
            '4. Account Deletion\nYou have the right to permanently erase your profile and all service history at any time from the Privacy & Security settings.',
            style: TextStyle(
              fontSize: 14,
              color: CustomerHomeTheme.text,
              height: 1.45,
            ),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showContactSupportSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Contact Customer Support',
                style: TextStyle(
                  color: CustomerHomeTheme.primaryDark,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Our support team is available 8:00 AM – 8:00 PM daily.',
                style: TextStyle(
                  color: CustomerHomeTheme.mutedText,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: CustomerHomeTheme.mint,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.phone_in_talk_outlined,
                    color: CustomerHomeTheme.primary,
                  ),
                ),
                title: const Text(
                  'Call Hotline 1344',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text('Toll-free customer assistance'),
                onTap: () {
                  Navigator.pop(context);
                  launchContact(context, 'tel', homeCareHotline);
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: CustomerHomeTheme.mint,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mail_outline,
                    color: CustomerHomeTheme.primary,
                  ),
                ),
                title: const Text(
                  'Email Support',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text('support@homecare.app'),
                onTap: () {
                  Navigator.pop(context);
                  launchContact(context, 'mailto', 'support@homecare.app');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleDeleteAccount(BuildContext context) async {
    final passCtrl = TextEditingController();
    bool saving = false;
    String? error;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete Account?'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Are you sure you want to delete your account? This action cannot be undone. All your bookings, saved addresses, and profile details will be permanently removed.',
                style: TextStyle(
                  color: CustomerHomeTheme.text,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Enter your password to confirm:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: passCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 10),
                Text(
                  error!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: saving
                  ? null
                  : () async {
                      if (passCtrl.text.isEmpty) {
                        setDialogState(() => error = 'Password is required.');
                        return;
                      }
                      setDialogState(() {
                        saving = true;
                        error = null;
                      });
                      try {
                        await authService.deleteAccount(password: passCtrl.text);
                        if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                      } catch (err) {
                        setDialogState(() {
                          error = AuthService.errorMessage(err);
                          saving = false;
                        });
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Delete Permanently'),
            ),
          ],
        ),
      ),
    );
  }

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

        final profileHeading = isTamil
            ? 'சுயவிவரம்'
            : (isSinhala ? 'පැතිකඩ' : 'Profile');

        return SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Text(
                      profileHeading,
                      style: const TextStyle(
                        color: CustomerHomeTheme.primaryDark,
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isSinhala ? 'ඔබේ ගිණුම් විස්තර සහ සැකසුම්' : 'Your account details & settings',
                      style: const TextStyle(
                        color: CustomerHomeTheme.mutedText,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 1. PROFILE HEADER
                    _ProfileHeader(user: user, onEdit: onEdit),
                    const SizedBox(height: 16),

                    // 2. EDIT PROFILE BUTTON
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        key: const ValueKey('profile-edit-button'),
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined),
                        label: Text(isSinhala ? 'පැතිකඩ සංස්කරණය' : 'Edit Profile'),
                        style: FilledButton.styleFrom(
                          backgroundColor: CustomerHomeTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // 3. ACCOUNT SECTION
                    _SectionHeading(
                      title: isSinhala ? 'ගිණුම' : 'ACCOUNT',
                    ),
                    const SizedBox(height: 10),
                    _ProfileGroupCard(
                      children: [
                        _ActionTile(
                          icon: Icons.person_outline,
                          title: isSinhala ? 'පුද්ගලික තොරතුරු' : 'Personal Information',
                          subtitle: isSinhala ? 'නම, ඊමේල්, දුරකථන අංකය' : 'Name, email, phone number',
                          onTap: () => _showPersonalInfoDialog(context),
                        ),
                        const Divider(height: 1, indent: 72, color: CustomerHomeTheme.border),
                        _ActionTile(
                          icon: Icons.location_on_outlined,
                          title: isSinhala ? 'සුරැකි ලිපින' : 'Saved Addresses',
                          subtitle: isSinhala ? 'නිවස, කාර්යාලය සහ සේවා ලිපින' : 'Home, Work, and service locations',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const MyAddressesScreen(),
                            ),
                          ),
                        ),
                        const Divider(height: 1, indent: 72, color: CustomerHomeTheme.border),
                        _ActionTile(
                          icon: Icons.credit_card_outlined,
                          title: isSinhala ? 'ගෙවීම් ක්‍රම' : 'Payment Methods',
                          subtitle: isSinhala ? 'කාඩ්පත් සහ සේවා ගෙවීම්' : 'Cards, Cash on Service',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const PaymentMethodsScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // 4. PREFERENCES / SETTINGS SECTION
                    _SectionHeading(
                      title: isSinhala ? 'මනාප සහ සැකසුම්' : 'PREFERENCES / SETTINGS',
                    ),
                    const SizedBox(height: 10),
                    _ProfileGroupCard(
                      children: [
                        _ActionTile(
                          icon: Icons.settings_outlined,
                          title: isSinhala ? 'සියලු සැකසුම්' : 'Settings',
                          subtitle: isSinhala ? 'ප්‍රධාන සැකසුම් මධ්‍යස්ථානය' : 'Main settings overview',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SettingsScreen(
                                user: user,
                                authService: authService,
                              ),
                            ),
                          ),
                        ),
                        const Divider(height: 1, indent: 72, color: CustomerHomeTheme.border),
                        _ActionTile(
                          key: const ValueKey('profile-nav-language'),
                          icon: Icons.translate_rounded,
                          title: isSinhala ? 'භාෂාව' : 'Language',
                          subtitle: languageLabel,
                          badge: languageLabel,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const LanguageSettingsScreen(),
                            ),
                          ),
                        ),
                        const Divider(height: 1, indent: 72, color: CustomerHomeTheme.border),
                        _ActionTile(
                          key: const ValueKey('profile-nav-text-size'),
                          icon: Icons.format_size_rounded,
                          title: isSinhala ? 'අකුරු ප්‍රමාණය' : 'Text Size / Accessibility',
                          subtitle: '$sizeLabel text scale',
                          badge: sizeLabel,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const TextSizeSettingsScreen(),
                            ),
                          ),
                        ),
                        const Divider(height: 1, indent: 72, color: CustomerHomeTheme.border),
                        _ActionTile(
                          icon: Icons.notifications_none_rounded,
                          title: isSinhala ? 'දැනුම්දීම්' : 'Notifications',
                          subtitle: isSinhala ? 'වෙන්කිරීම් සහ සේවා යාවත්කාලීන' : 'Booking updates, reminders, offers',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const NotificationSettingsScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // 5. SECURITY & PRIVACY SECTION
                    _SectionHeading(
                      title: isSinhala ? 'ආරක්ෂාව සහ පෞද්ගලිකත්වය' : 'SECURITY & PRIVACY',
                    ),
                    const SizedBox(height: 10),
                    _ProfileGroupCard(
                      children: [
                        _ActionTile(
                          icon: Icons.security_outlined,
                          title: isSinhala ? 'පෞද්ගලිකත්වය සහ ආරක්ෂාව' : 'Privacy & Security',
                          subtitle: isSinhala ? 'මුරපදය වෙනස් කිරීම සහ ආරක්ෂක සැකසුම්' : 'Change password, login security',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PrivacySecurityScreen(
                                authService: authService,
                                userEmail: user.email,
                              ),
                            ),
                          ),
                        ),
                        const Divider(height: 1, indent: 72, color: CustomerHomeTheme.border),
                        _ActionTile(
                          icon: Icons.delete_outline,
                          iconColor: Colors.red,
                          title: isSinhala ? 'ගිණුම මකා දමන්න' : 'Delete Account',
                          subtitle: isSinhala ? 'ඔබේ ගිණුම ස්ථිරවම ඉවත් කරන්න' : 'Permanently remove your account and data',
                          onTap: () => _handleDeleteAccount(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // 6. SUPPORT SECTION
                    _SectionHeading(
                      title: isSinhala ? 'සහාය' : 'SUPPORT',
                    ),
                    const SizedBox(height: 10),
                    _ProfileGroupCard(
                      children: [
                        _ActionTile(
                          icon: Icons.help_outline_rounded,
                          title: isSinhala ? 'උදව් සහ සහාය' : 'Help & Support',
                          subtitle: isSinhala ? 'නිතර අසන ප්‍රශ්න සහ මාර්ගෝපදේශ' : 'FAQs, booking & payment help',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const HelpSupportScreen(),
                            ),
                          ),
                        ),
                        const Divider(height: 1, indent: 72, color: CustomerHomeTheme.border),
                        _ActionTile(
                          icon: Icons.quiz_outlined,
                          title: isSinhala ? 'නිතර අසන ප්‍රශ්න' : 'FAQs',
                          subtitle: isSinhala ? 'පොදු ගැටළු සඳහා ඉක්මන් පිළිතුරු' : 'Frequently asked questions',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const HelpSupportScreen(initialTab: 0),
                            ),
                          ),
                        ),
                        const Divider(height: 1, indent: 72, color: CustomerHomeTheme.border),
                        _ActionTile(
                          icon: Icons.headset_mic_outlined,
                          title: isSinhala ? 'සහාය අමතන්න' : 'Contact Support',
                          subtitle: isSinhala ? 'ක්ෂණික ඇමතුම් 1344 හෝ ඊමේල්' : 'Direct hotline 1344 or email',
                          onTap: () => _showContactSupportSheet(context),
                        ),
                        const Divider(height: 1, indent: 72, color: CustomerHomeTheme.border),
                        _ActionTile(
                          icon: Icons.report_problem_outlined,
                          title: isSinhala ? 'ගැටළුවක් වාර්තා කරන්න' : 'Report a Problem',
                          subtitle: isSinhala ? 'සේවාව හෝ ගෙවීම් ගැටළු දැනුම් දෙන්න' : 'Report service or billing concerns',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const HelpSupportScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // 7. LEGAL SECTION
                    _SectionHeading(
                      title: isSinhala ? 'නීතිමය' : 'LEGAL',
                    ),
                    const SizedBox(height: 10),
                    _ProfileGroupCard(
                      children: [
                        _ActionTile(
                          icon: Icons.description_outlined,
                          title: isSinhala ? 'නියමයන් සහ කොන්දේසි' : 'Terms & Conditions',
                          subtitle: isSinhala ? 'සේවා නියමයන් කියවන්න' : 'Customer service agreements',
                          onTap: () => _showTermsDialog(context),
                        ),
                        const Divider(height: 1, indent: 72, color: CustomerHomeTheme.border),
                        _ActionTile(
                          icon: Icons.privacy_tip_outlined,
                          title: isSinhala ? 'පෞද්ගලිකත්ව ප්‍රතිපත්තිය' : 'Privacy Policy',
                          subtitle: isSinhala ? 'දත්ත ආරක්ෂණ ප්‍රතිපත්තිය' : 'How we safeguard customer data',
                          onTap: () => _showPrivacyPolicyDialog(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // 8. LOG OUT
                    _ProfileLogoutButton(authService: authService),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user, required this.onEdit});

  final AppUser user;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [CustomerHomeTheme.mint, CustomerHomeTheme.background],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: CustomerHomeTheme.border),
    ),
    child: Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                    color: CustomerHomeTheme.shadow,
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: CustomerAvatar(photoUrl: user.photoUrl, radius: 48),
            ),
            Positioned(
              right: -2,
              bottom: 0,
              child: Material(
                color: CustomerHomeTheme.primary,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: onEdit,
                  customBorder: const CircleBorder(),
                  child: const Padding(
                    padding: EdgeInsets.all(9),
                    child: Icon(
                      Icons.camera_alt_outlined,
                      color: Colors.white,
                      size: 17,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          _valueOrFallback(user.name),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: CustomerHomeTheme.text,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _valueOrFallback(user.email),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: CustomerHomeTheme.mutedText,
            fontSize: 14,
          ),
        ),
        if (user.phone != null && user.phone!.trim().isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            user.phone!.trim(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: CustomerHomeTheme.mutedText,
              fontSize: 13,
            ),
          ),
        ],
        const SizedBox(height: 14),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.verified_user_outlined,
                  color: CustomerHomeTheme.primary,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  _accountLabel(user.role),
                  style: const TextStyle(
                    color: CustomerHomeTheme.primaryDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title});

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

class _ProfileGroupCard extends StatelessWidget {
  const _ProfileGroupCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(children: children),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    super.key,
    required this.icon,
    this.iconColor,
    required this.title,
    required this.subtitle,
    this.badge,
    required this.onTap,
  });

  final IconData icon;
  final Color? iconColor;
  final String title;
  final String subtitle;
  final String? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? CustomerHomeTheme.primary;
    final isDanger = iconColor == Colors.red;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDanger
              ? Colors.red.withValues(alpha: 0.1)
              : CustomerHomeTheme.mint,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: effectiveIconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDanger ? Colors.red : CustomerHomeTheme.text,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          subtitle,
          style: const TextStyle(
            color: CustomerHomeTheme.mutedText,
            fontSize: 12,
          ),
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.brand100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badge!,
                style: const TextStyle(
                  color: CustomerHomeTheme.primaryDark,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 4),
          ],
          const Icon(
            Icons.chevron_right,
            color: CustomerHomeTheme.mutedText,
            size: 18,
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 95,
          child: Text(
            label,
            style: const TextStyle(
              color: CustomerHomeTheme.mutedText,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: CustomerHomeTheme.text,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileLogoutButton extends StatefulWidget {
  const _ProfileLogoutButton({required this.authService});

  final AuthService authService;

  @override
  State<_ProfileLogoutButton> createState() => _ProfileLogoutButtonState();
}

class _ProfileLogoutButtonState extends State<_ProfileLogoutButton> {
  bool _busy = false;

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('Are you sure you want to log out of HomeCare?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await widget.authService.logout();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AuthService.errorMessage(error))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: OutlinedButton.icon(
      key: const ValueKey('profile-logout-button'),
      onPressed: _busy ? null : _confirmLogout,
      icon: const Icon(Icons.logout_outlined),
      label: Text(_busy ? 'Logging out...' : 'Log out'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.error,
        side: BorderSide(color: Theme.of(context).colorScheme.error),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
  );
}

class _ProfileError extends StatelessWidget {
  const _ProfileError({required this.onRetry, required this.hasError});

  final VoidCallback onRetry;
  final bool hasError;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            hasError
                ? 'Your profile could not be loaded.'
                : 'No profile was found for this account.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: CustomerHomeTheme.text,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    ),
  );
}

String _valueOrFallback(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? 'Not provided' : trimmed;
}

String _accountLabel(String role) => switch (role) {
  AppUser.customerRole => 'Customer',
  AppUser.providerRole => 'Provider',
  _ => _valueOrFallback(role),
};
