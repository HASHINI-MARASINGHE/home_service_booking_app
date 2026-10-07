import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../models/app_user.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth/login_hero.dart';
import '../../widgets/auth/primary_button.dart';

/// First step of sign-up: the person picks whether they book services
/// (customer) or provide them (provider) before seeing a registration form.
class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({
    super.key,
    required this.onContinue,
    required this.onLogin,
    this.initialRole = AppUser.customerRole,
  });

  /// Called with [AppUser.customerRole] or [AppUser.providerRole].
  final ValueChanged<String> onContinue;

  /// Returns to the login screen (also used by the hero back arrow).
  final VoidCallback onLogin;
  final String initialRole;

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  late String _role = widget.initialRole;

  /// True while page content sits underneath the pinned bottom bar.
  bool _contentBelow = false;

  bool get _isProvider => _role == AppUser.providerRole;

  bool _onScrollMetrics(ScrollMetrics metrics) {
    final below = metrics.extentAfter > 0;
    if (below != _contentBelow) setState(() => _contentBelow = below);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final heroHeight = (MediaQuery.sizeOf(context).height * 0.30).clamp(
      210.0,
      280.0,
    );
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AuthColors.surface,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: NotificationListener<ScrollMetricsNotification>(
                onNotification: (n) => _onScrollMetrics(n.metrics),
                child: NotificationListener<ScrollNotification>(
                  onNotification: (n) => _onScrollMetrics(n.metrics),
                  child: SingleChildScrollView(
                    child: Stack(
                      children: [
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: LoginHero(
                            height: heroHeight,
                            illustrationHeight: 100,
                            onBack: widget.onLogin,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: heroHeight - 24),
                          child: _content(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _bottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _content() => Container(
    decoration: const BoxDecoration(
      color: AuthColors.surface,
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Pill('Trusted pros'),
            const SizedBox(height: 12),
            Semantics(
              header: true,
              child: const Text(
                'Your Home, Our Care',
                style: TextStyle(
                  color: AuthColors.primary,
                  fontSize: 28,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Book verified professionals, see the price upfront and '
              'track every job in one place.',
              style: TextStyle(
                color: AuthColors.secondary,
                fontSize: 15,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'How will you use HomeCare?',
              style: TextStyle(
                color: AuthColors.heading,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _RoleCard(
              key: const ValueKey('role-customer'),
              icon: LucideIcons.house,
              title: 'I need a service',
              subtitle: 'Find, book and track trusted home professionals',
              benefits: const [
                'Verified, rated professionals',
                'See the price before you book',
                'Track every job in real time',
              ],
              selected: !_isProvider,
              onTap: () => setState(() => _role = AppUser.customerRole),
            ),
            const SizedBox(height: 12),
            _RoleCard(
              key: const ValueKey('role-provider'),
              icon: LucideIcons.briefcase,
              title: 'I provide services',
              subtitle: 'Get job requests, manage bookings and get paid',
              benefits: const [
                'Get job requests near you',
                'Manage bookings and your schedule',
                'Secure payments after each job',
              ],
              selected: _isProvider,
              onTap: () => setState(() => _role = AppUser.providerRole),
            ),
            const SizedBox(height: 28),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _TrustItem(LucideIcons.badgeCheck, 'Verified pros'),
                ),
                Expanded(child: _TrustItem(LucideIcons.tag, 'Upfront prices')),
                Expanded(
                  child: _TrustItem(LucideIcons.shieldCheck, 'Secure payments'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  Widget _bottomBar() => AnimatedContainer(
    duration: const Duration(milliseconds: 150),
    decoration: BoxDecoration(
      color: AuthColors.surface,
      boxShadow: _contentBelow
          ? const [
              BoxShadow(
                color: AuthColors.cardShadow,
                blurRadius: 16,
                offset: Offset(0, -4),
              ),
            ]
          : null,
    ),
    child: SafeArea(
      top: false,
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PrimaryButton(
                  key: const ValueKey('role-continue'),
                  label: _isProvider
                      ? 'Continue as Provider'
                      : 'Continue as Customer',
                  onPressed: () => widget.onContinue(_role),
                ),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      'Already have an account?',
                      style: TextStyle(
                        color: AuthColors.secondary,
                        fontSize: 14.5,
                      ),
                    ),
                    TextButton(
                      key: const ValueKey('role-login'),
                      onPressed: widget.onLogin,
                      style: TextButton.styleFrom(
                        foregroundColor: AuthColors.primary,
                        minimumSize: const Size(48, 48),
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        textStyle: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: const Text('Log in'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _Pill extends StatelessWidget {
  const _Pill(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: AuthColors.focusedFill,
      border: Border.all(color: AuthColors.mintBorder),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: AuthColors.primary,
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _TrustItem extends StatelessWidget {
  const _TrustItem(this.icon, this.caption);
  final IconData icon;
  final String caption;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: AuthColors.focusedFill,
          shape: BoxShape.circle,
        ),
        child: ExcludeSemantics(
          child: Icon(icon, size: 20, color: AuthColors.primary),
        ),
      ),
      const SizedBox(height: 8),
      Text(
        caption,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AuthColors.secondary, fontSize: 12),
      ),
    ],
  );
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.benefits,
    required this.selected,
    required this.onTap,
  });

  static const _duration = Duration(milliseconds: 150);

  final IconData icon;
  final String title;
  final String subtitle;
  final List<String> benefits;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: title,
      hint: selected ? '$subtitle. ${benefits.join('. ')}.' : subtitle,
      onTap: onTap,
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: _duration,
        decoration: BoxDecoration(
          color: selected ? AuthColors.focusedFill : AuthColors.surface,
          borderRadius: radius,
          border: Border.all(
            color: selected ? AuthColors.primary : AuthColors.fieldBorder,
            width: selected ? 2 : 1,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                // Keep content still while the border grows from 1 to 2px.
                padding: EdgeInsets.all(selected ? 15 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _header(),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      alignment: Alignment.topCenter,
                      child: selected
                          ? Padding(
                              padding: const EdgeInsets.only(left: 62, top: 12),
                              child: Column(
                                children: [
                                  for (final benefit in benefits)
                                    _BenefitRow(benefit),
                                ],
                              ),
                            )
                          : const SizedBox(width: double.infinity),
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

  Widget _header() => Row(
    children: [
      AnimatedContainer(
        duration: _duration,
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: selected ? AuthColors.primary : AuthColors.focusedFill,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 22,
          color: selected ? AuthColors.onPrimary : AuthColors.primary,
        ),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AuthColors.heading,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: AuthColors.secondary,
                fontSize: 13.5,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(width: 12),
      AnimatedSwitcher(
        duration: _duration,
        child: selected
            ? const Icon(
                LucideIcons.circleCheck,
                key: ValueKey('checked'),
                size: 24,
                color: AuthColors.primary,
              )
            : Container(
                key: const ValueKey('unchecked'),
                width: 22,
                height: 22,
                margin: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AuthColors.placeholder, width: 1.5),
                ),
              ),
      ),
    ],
  );
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(LucideIcons.check, size: 16, color: AuthColors.primary),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.body,
              fontSize: 14,
              height: 1.35,
            ),
          ),
        ),
      ],
    ),
  );
}
