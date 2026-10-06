import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../models/provider_profile.dart';
import '../../models/provider_verification.dart';
import '../../models/rating_stats.dart';
import '../../services/auth_service.dart';
import '../../services/provider_notification_service.dart';
import '../../services/provider_profile_service.dart';
import '../../widgets/common/review_widgets.dart';
import '../../widgets/provider/provider_widgets.dart';
import '../auth/logout_button.dart';
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
        return Column(
          children: [
            Expanded(
              child: ProviderFailure(
                error: snapshot.error,
                onRetry: () =>
                    setState(() => _profile = widget.service.watchProfile()),
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
          profile: profile,
          service: widget.service,
          onClose: () => setState(() => _editing = false),
        );
      }
      return ProviderPage(
        children: [
          ProviderCard(
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 32,
                  backgroundColor: ProviderTheme.tealLight,
                  child: Icon(
                    Icons.person_outline,
                    size: 36,
                    color: ProviderTheme.teal,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.user.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  widget.user.email,
                  style: const TextStyle(color: ProviderTheme.muted),
                ),
                const SizedBox(height: 12),
                if (widget.verificationStatus == null)
                  Text(
                    'Verification: ${profile.verificationStatus}',
                    style: const TextStyle(color: ProviderTheme.teal),
                  )
                else
                  _VerificationBadge(
                    status: widget.verificationStatus!,
                    providerCode: widget.verification?.providerCode,
                  ),
                const SizedBox(height: 16),
                _OverallRating(
                  stream: _ratingStats,
                  fallback: profile.rating,
                ),
              ],
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
          ProviderCard(
            child: Column(
              children: [
                DetailRow(
                  icon: Icons.phone_outlined,
                  label: 'Phone',
                  value: _value(profile.phone),
                ),
                DetailRow(
                  icon: Icons.work_outline,
                  label: 'Profession',
                  value: _value(profile.profession),
                ),
                DetailRow(
                  icon: Icons.workspace_premium_outlined,
                  label: 'Experience',
                  value: '${profile.experience} years',
                ),
                DetailRow(
                  icon: Icons.notes_outlined,
                  label: 'About',
                  value: _value(profile.about),
                ),
                DetailRow(
                  icon: Icons.handyman_outlined,
                  label: 'Services',
                  value: profile.services.isEmpty
                      ? 'Not added yet'
                      : profile.services.join(', '),
                ),
                DetailRow(
                  icon: Icons.payments_outlined,
                  label: 'Starting price',
                  value: money(profile.pricing),
                ),
                DetailRow(
                  icon: Icons.event_available_outlined,
                  label: 'Availability',
                  value: profile.availability
                      ? 'Available for new jobs'
                      : 'Not currently available',
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: () => setState(() => _editing = true),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit Profile'),
          ),
          const SizedBox(height: 10),
          LogoutButton(authService: widget.authService),
        ],
      );
    },
  );
  String _value(String value) => value.isEmpty ? 'Not added yet' : value;
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
      final stats = snapshot.data;
      final average = stats?.average ?? fallback;
      return Container(
        key: const ValueKey('overall-rating'),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: ProviderTheme.tealLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: average == null
            ? const Text(
                'No ratings yet',
                textAlign: TextAlign.center,
                style: TextStyle(color: ProviderTheme.muted),
              )
            : Semantics(
                label:
                    'Overall rating ${average.toStringAsFixed(1)} out of 5',
                child: ExcludeSemantics(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            average.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 44,
                              height: 1,
                              fontWeight: FontWeight.w800,
                              color: ProviderTheme.navy,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(left: 4, bottom: 4),
                            child: Text(
                              '/ 5',
                              style: TextStyle(
                                fontSize: 16,
                                color: ProviderTheme.muted,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      StarRow(rating: average.round(), size: 22),
                      const SizedBox(height: 6),
                      Text(
                        stats == null
                            ? 'Overall rating'
                            : 'Overall rating · ${stats.count} '
                                  '${stats.count == 1 ? 'review' : 'reviews'}',
                        style: const TextStyle(color: ProviderTheme.muted),
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
    final (label, color, icon) = switch (status) {
      VerificationStatus.verified => (
        'Verified provider',
        ProviderTheme.green,
        Icons.verified_rounded,
      ),
      VerificationStatus.pending => (
        'Verification pending',
        ProviderTheme.orange,
        Icons.hourglass_top_rounded,
      ),
      VerificationStatus.rejected => (
        'Verification needs changes',
        ProviderTheme.red,
        Icons.error_outline_rounded,
      ),
      VerificationStatus.none => (
        'Not verified yet',
        ProviderTheme.muted,
        Icons.shield_outlined,
      ),
    };
    return Column(
      children: [
        Row(
          key: const ValueKey('verification-badge'),
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        if (status == VerificationStatus.verified && providerCode != null) ...[
          const SizedBox(height: 6),
          SelectableText(
            'Provider ID: $providerCode',
            key: const ValueKey('provider-id'),
            style: const TextStyle(
              color: ProviderTheme.navy,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ],
    );
  }
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
      return Semantics(
        button: true,
        label: unread == 0
            ? 'Notifications, none unread'
            : 'Notifications, $unread unread',
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: ProviderCard(
            child: ExcludeSemantics(
              child: Row(
                children: [
                  Badge(
                    isLabelVisible: unread > 0,
                    label: Text('$unread'),
                    backgroundColor: ProviderTheme.red,
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      color: ProviderTheme.teal,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notifications',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          unread == 0
                              ? 'No new notifications'
                              : '$unread new ${unread == 1 ? 'notification' : 'notifications'}',
                          style: const TextStyle(color: ProviderTheme.muted),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: ProviderTheme.muted,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _ProfileEditor extends StatefulWidget {
  const _ProfileEditor({
    required this.profile,
    required this.service,
    required this.onClose,
  });
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
          'Your account name and email stay with your account. Add your professional details here.',
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
