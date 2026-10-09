import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/locale_controller.dart';
import '../../models/app_user.dart';
import '../../models/provider_profile.dart';
import '../../models/provider_verification.dart';
import '../../models/rating_stats.dart';
import '../../services/auth_service.dart';
import '../../services/provider_notification_service.dart';
import '../../services/provider_profile_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/text_size_controller.dart';
import '../../widgets/common/app_buttons.dart';
import '../../widgets/common/homecare_logo.dart';
import '../../widgets/common/review_widgets.dart';
import '../../widgets/provider/provider_widgets.dart';
import '../auth/logout_button.dart';
import '../customer/settings/language_settings_screen.dart';
import '../customer/settings/text_size_settings_screen.dart';
import 'provider_theme.dart';

class ProviderProfileScreen extends StatefulWidget {
  const ProviderProfileScreen({
    super.key,
    required this.user,
    required this.authService,
    required this.service,
    this.notifications,
    this.onOpenNotifications,
    this.verificationStatus,
    this.verification,
    this.onOpenVerification,
  });
  final AppUser user;
  final AuthService authService;
  final ProviderProfileService service;

  /// When set, the profile shows a Notifications entry with an unread badge.
  final ProviderNotificationService? notifications;
  final VoidCallback? onOpenNotifications;

  /// Admin verification. When [verificationStatus] is null the profile shows
  /// no verification UI at all.
  final VerificationStatus? verificationStatus;
  final ProviderVerification? verification;
  final VoidCallback? onOpenVerification;
  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen> {
  late Stream<ProviderProfile> _profile = widget.service.watchProfile();
  late final Stream<RatingStats?> _ratingStats = widget.service
      .watchRatingStats();
  bool _editing = false;

  @override
  Widget build(BuildContext context) => StreamBuilder<ProviderProfile>(
    stream: _profile,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        final error = snapshot.error!;
        final denied =
            error is FirebaseException && error.code == 'permission-denied';
        return Column(
          children: [
            Expanded(
              child: ProviderFailure(
                error: error,
                onRetry: () =>
                    setState(() => _profile = widget.service.watchProfile()),
              ),
            ),
            if (denied)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Access denied: the Firestore security rules do not allow '
                  'reading providerProfiles yet. Publish the latest '
                  'firestore.rules (Firebase Console > Firestore > Rules > '
                  'Publish), then tap Try again.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            LogoutButton(authService: widget.authService),
            const SizedBox(height: 20),
          ],
        );
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final profile = snapshot.data!;
      if (_editing) {
        return _ProfileEditor(
          user: widget.user,
          profile: profile,
          service: widget.service,
          onClose: () => setState(() => _editing = false),
        );
      }
      return ProviderPage(
        children: [
          _IdentityCard(
            name: widget.user.name,
            email: widget.user.email,
            badge: widget.verificationStatus == null
                ? Text(
                    'Verification: ${profile.verificationStatus}',
                    style: context.textStyles.caption.copyWith(
                      color: AppColors.brand700,
                    ),
                  )
                : _VerificationBadge(
                    status: widget.verificationStatus!,
                    providerCode: widget.verification?.providerCode,
                  ),
            rating: _OverallRating(
              stream: _ratingStats,
              fallback: profile.rating,
            ),
          ),
          if (widget.verificationStatus != null &&
              widget.verificationStatus != VerificationStatus.verified)
            _VerificationCard(
              status: widget.verificationStatus!,
              verification: widget.verification,
              onOpen: widget.onOpenVerification,
            ),
          if (widget.notifications != null)
            _NotificationsEntry(
              service: widget.notifications!,
              onTap: widget.onOpenNotifications,
            ),
          _CredentialsCard(
            phone: _value(profile.phone),
            profession: _value(profile.profession),
            experience: '${profile.experience} years',
            about: profile.about.trim(),
            services: profile.services.join(', '),
            price: money(profile.pricing),
            available: profile.availability,
            onAdd: () => setState(() => _editing = true),
          ),
          const _PreferencesCard(),
          AppPrimaryButton(
            label: 'Edit Profile',
            icon: LucideIcons.pencil,
            onPressed: () => setState(() => _editing = true),
          ),
          const SizedBox(height: AppSpacing.xs),
          LogoutButton(
            authService: widget.authService,
            icon: LucideIcons.logOut,
          ),
        ],
      );
    },
  );
  String _value(String value) => value.isEmpty ? 'Not added yet' : value;
}

/// Shared look of the white cards on the profile.
BoxDecoration _profileCard() => BoxDecoration(
  color: AppColors.surface,
  borderRadius: AppRadius.card,
  border: Border.all(
    color: AppColors.borderSubtle,
    width: AppSizes.borderControl,
  ),
);

/// Who the provider is: avatar, name, email, verification and the rating.
class _IdentityCard extends StatelessWidget {
  const _IdentityCard({
    required this.name,
    required this.email,
    required this.badge,
    required this.rating,
  });
  final String name, email;
  final Widget badge, rating;

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _profileCard(),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: AppColors.brand100,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.user,
              size: 40,
              color: AppColors.brand700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(name, textAlign: TextAlign.center, style: styles.h2),
          const SizedBox(height: 2),
          Text(email, textAlign: TextAlign.center, style: styles.caption),
          const SizedBox(height: AppSpacing.sm),
          badge,
          const SizedBox(height: AppSpacing.md),
          rating,
        ],
      ),
    );
  }
}

/// The provider's main rating: the live average of every customer review.
/// It moves up or down with each new review. Before the first review the
/// stored profile rating (if any) is shown without a review count.
class _OverallRating extends StatelessWidget {
  const _OverallRating({required this.stream, required this.fallback});
  final Stream<RatingStats?> stream;
  final double? fallback;

  @override
  Widget build(BuildContext context) => StreamBuilder<RatingStats?>(
    stream: stream,
    builder: (context, snapshot) {
      final styles = context.textStyles;
      final stats = snapshot.data;
      final average = stats?.average ?? fallback;
      return Container(
        key: const ValueKey('overall-rating'),
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.brand50,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: average == null
            ? Text(
                'No ratings yet',
                textAlign: TextAlign.center,
                style: styles.bodySmall,
              )
            : Semantics(
                label: 'Overall rating ${average.toStringAsFixed(1)} out of 5',
                child: ExcludeSemantics(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            average.toStringAsFixed(1),
                            style: styles.display.copyWith(
                              color: AppColors.brand900,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text('/ 5', style: styles.label),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      StarRow(rating: average.round(), size: 22),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        stats == null
                            ? 'Overall rating'
                            : 'Overall rating · ${stats.count} '
                                  '${stats.count == 1 ? 'review' : 'reviews'}',
                        textAlign: TextAlign.center,
                        style: styles.caption,
                      ),
                    ],
                  ),
                ),
              ),
      );
    },
  );
}

/// Verified (with the Provider ID) / pending / needs-changes badge.
class _VerificationBadge extends StatelessWidget {
  const _VerificationBadge({required this.status, this.providerCode});
  final VerificationStatus status;
  final String? providerCode;

  @override
  Widget build(BuildContext context) {
    final (label, background, color, icon) = switch (status) {
      VerificationStatus.verified => (
        'Verified provider',
        AppColors.successSoft,
        AppColors.successText,
        LucideIcons.badgeCheck,
      ),
      VerificationStatus.pending => (
        'Verification pending',
        AppColors.warningSoft,
        AppColors.warningText,
        LucideIcons.hourglass,
      ),
      VerificationStatus.rejected => (
        'Verification needs changes',
        AppColors.errorSoft,
        AppColors.errorText,
        LucideIcons.circleAlert,
      ),
      VerificationStatus.none => (
        'Not verified yet',
        AppColors.neutralSoft,
        AppColors.neutralText,
        LucideIcons.shield,
      ),
    };
    return Wrap(
      key: const ValueKey('verification-badge'),
      alignment: WrapAlignment.center,
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        _BadgePill(
          icon: icon,
          label: label,
          background: background,
          color: color,
        ),
        if (status == VerificationStatus.verified && providerCode != null)
          _BadgePill(
            icon: LucideIcons.idCard,
            label: providerCode!,
            background: AppColors.brand100,
            color: AppColors.brand900,
            labelKey: const ValueKey('provider-id'),
          ),
      ],
    );
  }
}

class _BadgePill extends StatelessWidget {
  const _BadgePill({
    required this.icon,
    required this.label,
    required this.background,
    required this.color,
    this.labelKey,
  });
  final IconData icon;
  final String label;
  final Color background, color;
  final Key? labelKey;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.xxs,
    ),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(AppRadius.pill),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: AppSpacing.xxs),
        Flexible(
          child: Text(
            label,
            key: labelKey,
            style: context.textStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

/// What the provider has to do (or wait for) before they can take jobs.
class _VerificationCard extends StatelessWidget {
  const _VerificationCard({
    required this.status,
    required this.verification,
    required this.onOpen,
  });
  final VerificationStatus status;
  final ProviderVerification? verification;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final (title, message, action) = switch (status) {
      VerificationStatus.pending => (
        'Your verification is being reviewed',
        'Our team is checking your documents. You will get a notification as '
            'soon as you are verified. Until then you can use your profile '
            'and notifications only.',
        null,
      ),
      VerificationStatus.rejected => (
        'Your verification needs changes',
        verification?.rejectionReason ?? 'Please update your documents.',
        'Update and resubmit',
      ),
      _ => (
        'Verify your account to start getting jobs',
        'Add your ID, a live selfie, your CV and a course certificate. An '
            'admin reviews them and gives you a Provider ID.',
        'Start verification',
      ),
    };
    return ProviderCard(
      key: const ValueKey('verification-card'),
      color: ProviderTheme.warningBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(message),
          if (action != null && onOpen != null) ...[
            const SizedBox(height: 12),
            FilledButton(
              key: const ValueKey('open-verification'),
              onPressed: onOpen,
              child: Text(action),
            ),
          ],
        ],
      ),
    );
  }
}

class _NotificationsEntry extends StatefulWidget {
  const _NotificationsEntry({required this.service, required this.onTap});
  final ProviderNotificationService service;
  final VoidCallback? onTap;

  @override
  State<_NotificationsEntry> createState() => _NotificationsEntryState();
}

class _NotificationsEntryState extends State<_NotificationsEntry> {
  late final Stream<int> _unreadCount = widget.service.watchUnreadCount();

  @override
  Widget build(BuildContext context) => StreamBuilder<int>(
    stream: _unreadCount,
    builder: (context, snapshot) {
      final unread = snapshot.data ?? 0;
      final styles = context.textStyles;
      return Semantics(
        button: true,
        label: unread == 0
            ? 'Notifications, none unread'
            : 'Notifications, $unread unread',
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: _profileCard(),
            child: ExcludeSemantics(
              child: Row(
                children: [
                  Badge(
                    isLabelVisible: unread > 0,
                    label: Text('$unread'),
                    backgroundColor: AppColors.errorSolid,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.brand50,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: const Icon(
                        LucideIcons.bell,
                        color: AppColors.brand700,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Notifications', style: styles.label),
                        Text(
                          unread == 0
                              ? 'No new notifications'
                              : '$unread new ${unread == 1 ? 'notification' : 'notifications'}',
                          style: styles.caption,
                        ),
                      ],
                    ),
                  ),
                  const Icon(LucideIcons.chevronRight, color: AppColors.ink3),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// The provider's details as a list of rows, like "Phone 0721515123".
class _CredentialsCard extends StatelessWidget {
  const _CredentialsCard({
    required this.phone,
    required this.profession,
    required this.experience,
    required this.about,
    required this.services,
    required this.price,
    required this.available,
    required this.onAdd,
  });
  final String phone, profession, experience, about, services, price;
  final bool available;

  /// Opens the profile editor ("Add" on an empty row).
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    final hasPhone = phone != 'Not added yet';
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _profileCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Text(
              'SERVICE CREDENTIALS',
              style: styles.caption.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          _CredRow(
            icon: LucideIcons.phone,
            label: 'Phone',
            value: phone,
            trailing: hasPhone
                ? IconButton(
                    key: const ValueKey('call-profile-phone'),
                    tooltip: 'Call this number',
                    onPressed: () => launchUrl(Uri(scheme: 'tel', path: phone)),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surface,
                      foregroundColor: AppColors.brand700,
                      minimumSize: const Size(AppSizes.minTap, AppSizes.minTap),
                    ),
                    icon: const Icon(LucideIcons.phoneCall, size: 18),
                  )
                : null,
          ),
          _CredRow(
            icon: LucideIcons.briefcase,
            label: 'Profession',
            value: profession,
          ),
          _CredRow(
            icon: LucideIcons.award,
            label: 'Experience',
            value: experience,
          ),
          _CredRow(
            icon: LucideIcons.fileText,
            label: 'About',
            value: about.isEmpty ? 'Not added yet' : about,
            muted: about.isEmpty,
            trailing: about.isEmpty ? _AddButton(onTap: onAdd) : null,
          ),
          _CredRow(
            icon: LucideIcons.wrench,
            label: 'Services',
            value: services.isEmpty ? 'Not added yet' : services,
            muted: services.isEmpty,
            trailing: services.isEmpty ? _AddButton(onTap: onAdd) : null,
          ),
          _CredRow(
            icon: LucideIcons.banknote,
            label: 'Starting price',
            value: price,
          ),
          _CredRow(
            icon: LucideIcons.calendarCheck,
            label: 'Availability',
            value: available
                ? 'Available for new jobs'
                : 'Not currently available',
            dot: available ? AppColors.accent500 : AppColors.ink3,
            last: true,
          ),
        ],
      ),
    );
  }
}

class _CredRow extends StatelessWidget {
  const _CredRow({
    required this.icon,
    required this.label,
    required this.value,
    this.muted = false,
    this.trailing,
    this.dot,
    this.last = false,
  });
  final IconData icon;
  final String label, value;
  final bool muted, last;
  final Widget? trailing;
  final Color? dot;

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    return Container(
      margin: EdgeInsets.only(bottom: last ? 0 : AppSpacing.xs),
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.brand50,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.brand100,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, size: 20, color: AppColors.brand700),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: styles.caption),
                Row(
                  children: [
                    if (dot != null) ...[
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: dot,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                    ],
                    Expanded(
                      child: Text(
                        value,
                        style: muted
                            ? styles.bodySmall.copyWith(
                                fontStyle: FontStyle.italic,
                              )
                            : styles.label,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.xs),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// "+ Add" on a row that has nothing yet; opens the profile editor.
class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    key: const ValueKey('profile-add'),
    onTap: onTap,
    borderRadius: BorderRadius.circular(AppRadius.sm),
    child: Container(
      constraints: const BoxConstraints(minHeight: AppSizes.minTap),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.accent100,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.plus, size: 16, color: AppColors.accent700),
          const SizedBox(width: 4),
          Text(
            'Add',
            style: context.textStyles.caption.copyWith(
              color: AppColors.accent700,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}

class _ProfileEditor extends StatefulWidget {
  const _ProfileEditor({
    required this.user,
    required this.profile,
    required this.service,
    required this.onClose,
  });
  final AppUser user;
  final ProviderProfile profile;
  final ProviderProfileService service;
  final VoidCallback onClose;
  @override
  State<_ProfileEditor> createState() => _ProfileEditorState();
}

class _ProfileEditorState extends State<_ProfileEditor> {
  final _form = GlobalKey<FormState>();
  late final _phone = TextEditingController(text: widget.profile.phone);
  late final _profession = TextEditingController(
    text: widget.profile.profession,
  );
  late final _experience = TextEditingController(
    text: '${widget.profile.experience}',
  );
  late final _about = TextEditingController(text: widget.profile.about);
  late final _services = TextEditingController(
    text: widget.profile.services.join(', '),
  );
  late final _pricing = TextEditingController(
    text: widget.profile.pricing?.toString() ?? '',
  );
  late bool _available = widget.profile.availability;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final controller in [
      _phone,
      _profession,
      _experience,
      _about,
      _services,
      _pricing,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.service.save(
        ProviderProfile(
          providerId: widget.profile.providerId,
          phone: _phone.text.trim(),
          profession: _profession.text.trim(),
          experience: int.parse(_experience.text.trim()),
          about: _about.text.trim(),
          services: _services.text
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toSet()
              .toList(),
          pricing: _pricing.text.trim().isEmpty
              ? null
              : double.parse(_pricing.text.trim()),
          availability: _available,
        ),
        user: widget.user,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Profile saved.')));
      widget.onClose();
    } catch (error) {
      if (mounted) setState(() => _error = providerError(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _form,
    child: ProviderPage(
      children: [
        Text(
          'Edit provider profile',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        const Text(
          'Your account name and email stay with your account. Your name, profession and phone appear on the customer home page.',
          style: TextStyle(color: ProviderTheme.muted),
        ),
        const SizedBox(height: 20),
        _field(
          _phone,
          'Phone (optional)',
          maxLength: 40,
          keyboard: TextInputType.phone,
        ),
        _field(
          _profession,
          'Profession',
          maxLength: 100,
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Enter your profession.'
              : null,
        ),
        _field(
          _experience,
          'Years of experience',
          keyboard: TextInputType.number,
          validator: (value) {
            final years = int.tryParse(value?.trim() ?? '');
            return years == null || years < 0 || years > 80
                ? 'Enter a whole number from 0 to 80.'
                : null;
          },
        ),
        _field(_about, 'About', maxLength: 2000, lines: 4),
        _field(
          _services,
          'Services (separate with commas)',
          lines: 2,
          validator: (value) {
            final services = (value ?? '')
                .split(',')
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty);
            return services.length > 20 || services.any((s) => s.length > 100)
                ? 'Use up to 20 services, each at most 100 characters.'
                : null;
          },
        ),
        _field(
          _pricing,
          'Starting price in LKR (optional)',
          keyboard: const TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            if (value == null || value.trim().isEmpty) return null;
            final price = double.tryParse(value.trim());
            return price == null ||
                    !price.isFinite ||
                    price < 0 ||
                    price > 10000000
                ? 'Enter an amount from 0 to 10,000,000.'
                : null;
          },
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('Available for new jobs'),
          value: _available,
          onChanged: _saving
              ? null
              : (value) => setState(() => _available = value),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              _error!,
              style: const TextStyle(color: ProviderTheme.red),
            ),
          ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saving…' : 'Save profile'),
        ),
        TextButton(
          onPressed: _saving ? null : widget.onClose,
          child: const Text('Cancel'),
        ),
      ],
    ),
  );

  Widget _field(
    TextEditingController controller,
    String label, {
    int? maxLength,
    int lines = 1,
    TextInputType? keyboard,
    String? Function(String?)? validator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: controller,
      enabled: !_saving,
      decoration: InputDecoration(labelText: label),
      maxLength: maxLength,
      maxLines: lines,
      keyboardType: keyboard,
      validator: validator,
    ),
  );
}

/// Language and text size, with the same layout as the customer's profile.
/// The two screens they open are shared with the customer app, and both
/// settings apply to the whole app straight away.
class _PreferencesCard extends StatelessWidget {
  const _PreferencesCard();

  void _open(BuildContext context, Widget screen) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      // Keep the HomeCare bar on top, like every other page.
      builder: (_) => Theme(
        data: ProviderTheme.data,
        child: BrandShell(child: screen),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([
      LocaleController.instance,
      TextSizeController.instance,
    ]),
    builder: (context, _) {
      final code = LocaleController.instance.locale.languageCode;
      final si = code == 'si';
      final ta = code == 'ta';
      final language = ta ? 'தமிழ்' : (si ? 'සිංහල' : 'English');
      final size = switch (TextSizeController.instance.size) {
        AppTextSize.normal => ta ? 'இயல்பானது' : (si ? 'සාමාන්‍ය' : 'Normal'),
        AppTextSize.large => ta ? 'பெரியது' : (si ? 'විශාල' : 'Large'),
        AppTextSize.extraLarge =>
          ta ? 'மிகப் பெரியது' : (si ? 'ඉතා විශාල' : 'Extra large'),
      };
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              ta
                  ? 'விருப்பங்கள் / அமைப்புகள்'
                  : (si ? 'මනාප සහ සැකසුම්' : 'PREFERENCES / SETTINGS'),
              style: const TextStyle(
                color: ProviderTheme.muted,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ProviderCard(
            // The rows paint their ink on the nearest Material; the card
            // around them has a background, so give them a clear one.
            child: Material(
              type: MaterialType.transparency,
              child: Column(
                children: [
                  _PreferenceRow(
                    key: const ValueKey('profile-nav-language'),
                    icon: Icons.translate_rounded,
                    title: ta ? 'மொழி' : (si ? 'භාෂාව' : 'Language'),
                    value: language,
                    onTap: () => _open(context, const LanguageSettingsScreen()),
                  ),
                  const Divider(height: 1),
                  _PreferenceRow(
                    key: const ValueKey('profile-nav-text-size'),
                    icon: Icons.format_size_rounded,
                    title: ta
                        ? 'எழுத்து அளவு'
                        : (si ? 'අකුරු ප්‍රමාණය' : 'Text size'),
                    value: size,
                    onTap: () => _open(context, const TextSizeSettingsScreen()),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    },
  );
}

class _PreferenceRow extends StatelessWidget {
  const _PreferenceRow({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String title, value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    onTap: onTap,
    leading: CircleAvatar(
      radius: 20,
      backgroundColor: ProviderTheme.tealLight,
      child: Icon(icon, color: ProviderTheme.teal, size: 22),
    ),
    title: Text(title, style: Theme.of(context).textTheme.titleMedium),
    subtitle: Text(value, style: const TextStyle(color: ProviderTheme.muted)),
    trailing: const Icon(
      Icons.chevron_right_rounded,
      color: ProviderTheme.muted,
    ),
  );
}
