import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/professional.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/customer_home_theme.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/common/app_widgets.dart';
import '../customer_scope.dart';
import 'book_provider.dart';
import 'provider_service_icon.dart';

/// Public profile of one provider, opened from the customer home page or
/// the "See all" list. Shows [initial] at once, then live data.
class ProviderDetailsScreen extends StatefulWidget {
  const ProviderDetailsScreen({
    super.key,
    required this.providerId,
    this.initial,
  });

  final String providerId;
  final Professional? initial;

  @override
  State<ProviderDetailsScreen> createState() => _ProviderDetailsScreenState();
}

class _ProviderDetailsScreenState extends State<ProviderDetailsScreen> {
  Stream<Professional?>? _provider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _provider ??= _load();
  }

  Stream<Professional?> _load() {
    try {
      return CustomerScope.of(context).bookings
          .watchProfessional(widget.providerId);
    } catch (error) {
      return Stream.error(error);
    }
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: CustomerHomeTheme.background,
    child: SafeArea(
      bottom: false,
      child: Column(
        children: [
          const ScreenHeader(title: 'Provider Profile'),
          Expanded(
            child: StreamBuilder<Professional?>(
              stream: _provider,
              initialData: widget.initial,
              builder: (context, snapshot) {
                final provider = snapshot.data;
                if (snapshot.hasError && provider == null) {
                  return ErrorState(
                    error: snapshot.error!,
                    onRetry: () => setState(() => _provider = _load()),
                  );
                }
                if (provider == null) {
                  return snapshot.connectionState == ConnectionState.waiting
                      ? const LoadingState()
                      : const Center(
                          child: Text(
                            'This provider is no longer available.',
                            style: AppTypography.caption,
                          ),
                        );
                }
                return _ProviderDetails(provider: provider);
              },
            ),
          ),
        ],
      ),
    ),
  );
}

class _ProviderDetails extends StatelessWidget {
  const _ProviderDetails({required this.provider});

  final Professional provider;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            _HeaderCard(provider: provider),
            const SizedBox(height: 16),
            _QuickInfo(provider: provider),
            if (provider.about.trim().isNotEmpty) ...[
              const SizedBox(height: 24),
              const _Heading('About'),
              const SizedBox(height: 8),
              Text(
                provider.about,
                style: const TextStyle(
                  color: CustomerHomeTheme.mutedText,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ],
            if (provider.services.isNotEmpty) ...[
              const SizedBox(height: 28),
              const _Heading('Services'),
              const SizedBox(height: 12),
              SizedBox(
                height: 132,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: provider.services.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 12),
                  itemBuilder: (context, index) => _ServiceTile(
                    name: provider.services[index],
                    pricing: provider.pricing,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 28),
            const _Heading('Reviews & Ratings'),
            const SizedBox(height: 12),
            _RatingSummary(provider: provider),
            // Reviews list: the reviews team plugs their widget in here, e.g.
            // `ProviderReviewsList(providerId: provider.id)`.
          ],
        ),
      ),
      // Pinned so the main action is always on screen.
      Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: CustomerHomeTheme.border)),
        ),
        child: SizedBox(
          height: 56,
          width: double.infinity,
          child: FilledButton(
            onPressed: () => openBookingFlow(context, provider),
            style: FilledButton.styleFrom(
              backgroundColor: CustomerHomeTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Book Now',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    ],
  );
}

/// Price, working days and a call button: what a customer wants to know
/// before booking.
class _QuickInfo extends StatelessWidget {
  const _QuickInfo({required this.provider});

  final Professional provider;

  static const _names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  Future<void> _call(BuildContext context) async {
    final uri = Uri(scheme: 'tel', path: provider.phone.trim());
    try {
      if (await launchUrl(uri)) return;
    } catch (_) {}
    if (context.mounted) {
      showAppSnack(context, 'Could not open the phone app.', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = ([...provider.workingDays]..sort())
        .where((d) => d >= 1 && d <= 7)
        .map((d) => _names[d - 1])
        .join(', ');
    final hasPhone = provider.phone.trim().isNotEmpty;
    return _Panel(
      child: Column(
        children: [
          _InfoRow(
            icon: LucideIcons.banknote,
            label: 'Price',
            value: provider.pricing == null
                ? 'Price on request'
                : 'From ${Formatters.lkr(provider.pricing)} '
                      '(estimate, final price quoted per job)',
          ),
          if (days.isNotEmpty)
            _InfoRow(
              icon: LucideIcons.calendarDays,
              label: 'Available',
              value: days,
            ),
          if (hasPhone) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _call(context),
                icon: const Icon(LucideIcons.phone, size: 18),
                label: const Text('Call provider'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: CustomerHomeTheme.primary,
                  side: const BorderSide(color: CustomerHomeTheme.primary),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label, value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: CustomerHomeTheme.primary),
        const SizedBox(width: 10),
        SizedBox(
          width: 76,
          child: Text(
            label,
            style: const TextStyle(
              color: CustomerHomeTheme.mutedText,
              fontSize: 14.5,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: CustomerHomeTheme.text,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.provider});

  final Professional provider;

  @override
  Widget build(BuildContext context) {
    final specialty = provider.specialty.trim();
    return _Panel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PersonAvatar(
            name: provider.name,
            photoUrl: provider.photoUrl,
            size: 76,
            verified: provider.verified,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        provider.name,
                        style: const TextStyle(
                          color: CustomerHomeTheme.text,
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (provider.rating != null) ...[
                      const SizedBox(width: 6),
                      _RatingBadge(rating: provider.rating!),
                    ],
                  ],
                ),
                if (specialty.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    provider.verified ? 'Licensed $specialty' : specialty,
                    style: const TextStyle(
                      color: CustomerHomeTheme.primary,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (provider.area.trim().isNotEmpty)
                  _Meta(icon: LucideIcons.mapPin, text: provider.area),
                if (provider.experience > 0)
                  _Meta(
                    icon: LucideIcons.briefcase,
                    text:
                        '${provider.experience}+ '
                        '${provider.experience == 1 ? 'Year' : 'Years'} Experience',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingBadge extends StatelessWidget {
  const _RatingBadge({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.warningSoft,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(
            color: AppColors.star,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 3),
        const Icon(Icons.star_rounded, size: 14, color: AppColors.accent500),
      ],
    ),
  );
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Row(
      children: [
        Icon(icon, size: 14, color: CustomerHomeTheme.mutedText),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: CustomerHomeTheme.mutedText,
              fontSize: 14,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({required this.name, required this.pricing});

  final String name;
  final double? pricing;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 124,
    child: _Panel(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: CustomerHomeTheme.mint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              serviceIcon(name),
              size: 20,
              color: CustomerHomeTheme.primary,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: CustomerHomeTheme.text,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (pricing != null)
            Text(
              'From ${Formatters.lkr(pricing)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: CustomerHomeTheme.primary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    ),
  );
}

class _RatingSummary extends StatelessWidget {
  const _RatingSummary({required this.provider});

  final Professional provider;

  @override
  Widget build(BuildContext context) {
    final rating = provider.rating;
    final jobs = provider.completedJobs;
    return _Panel(
      color: CustomerHomeTheme.mint,
      child: rating == null
          ? const Text(
              'No ratings yet',
              style: TextStyle(color: CustomerHomeTheme.mutedText),
            )
          : Row(
              children: [
                Column(
                  children: [
                    Text(
                      rating.toStringAsFixed(1),
                      style: const TextStyle(
                        color: CustomerHomeTheme.primaryDark,
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Text(
                      'out of 5',
                      style: TextStyle(
                        color: CustomerHomeTheme.mutedText,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Stars(rating: rating),
                      const SizedBox(height: 6),
                      Text(
                        '$jobs ${jobs == 1 ? 'job' : 'jobs'} completed',
                        style: const TextStyle(
                          color: CustomerHomeTheme.text,
                          fontSize: 14,
                        ),
                      ),
                      if (provider.verified) ...[
                        const SizedBox(height: 4),
                        const Row(
                          children: [
                            Icon(
                              LucideIcons.badgeCheck,
                              size: 14,
                              color: CustomerHomeTheme.primary,
                            ),
                            SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Verified professional',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: CustomerHomeTheme.primary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (var i = 1; i <= 5; i++)
        Icon(
          rating >= i
              ? Icons.star_rounded
              : rating >= i - 0.5
              ? Icons.star_half_rounded
              : Icons.star_outline_rounded,
          size: 20,
          color: AppColors.accent500,
        ),
    ],
  );
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: CustomerHomeTheme.text,
      fontSize: 18,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.child,
    this.color = Colors.white,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final Color color;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: CustomerHomeTheme.border),
      boxShadow: const [
        BoxShadow(
          color: CustomerHomeTheme.shadow,
          blurRadius: 16,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: child,
  );
}
