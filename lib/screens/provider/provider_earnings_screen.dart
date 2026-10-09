import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../models/booking.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/app_buttons.dart';
import '../../widgets/provider/provider_widgets.dart';

/// Which jobs the "Recent earnings" list shows.
enum EarningsRange {
  thisMonth('This Month'),
  thisYear('This Year'),
  allTime('All Time');

  const EarningsRange(this.label);
  final String label;

  bool contains(DateTime completedAt, DateTime now) {
    final date = completedAt.toLocal();
    return switch (this) {
      thisMonth => date.year == now.year && date.month == now.month,
      thisYear => date.year == now.year,
      allTime => true,
    };
  }
}

/// The provider's Earnings tab: this month's total, the all-time figures and
/// the list of paid jobs. Only completed and paid jobs count (see
/// [ProviderEarnings]).
class ProviderEarningsScreen extends StatefulWidget {
  const ProviderEarningsScreen({
    super.key,
    required this.bookings,
    required this.onOpen,
    this.onExploreLeads,
  });

  final List<Booking> bookings;
  final ValueChanged<Booking> onOpen;

  /// Takes the provider to the Leads tab from the empty state.
  final VoidCallback? onExploreLeads;

  @override
  State<ProviderEarningsScreen> createState() => _ProviderEarningsScreenState();
}

class _ProviderEarningsScreenState extends State<ProviderEarningsScreen> {
  final _scroll = ScrollController();
  final _recentKey = GlobalKey();
  EarningsRange _range = EarningsRange.thisYear;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _showRecent() {
    final target = _recentKey.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _showPayoutInfo() => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => const _PayoutInfoSheet(),
  );

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final earnings = ProviderEarnings(widget.bookings, now);
    final shown = [
      for (final b in earnings.entries)
        if (_range.contains(b.completedAt!, now)) b,
    ];
    final styles = context.textStyles;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: SingleChildScrollView(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.xs,
            AppSpacing.screen,
            AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HeroCard(
                amount: earnings.monthlyTotal,
                onPayoutCycle: _showPayoutInfo,
              ),
              const SizedBox(height: AppSpacing.md),
              _StatsCard(
                completedJobs: earnings.completedCount,
                totalEarnings: earnings.total,
                onViewBreakdown: _showRecent,
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                key: _recentKey,
                children: [
                  Expanded(child: Text('Recent earnings', style: styles.h3)),
                  _RangeMenu(
                    range: _range,
                    onChanged: (value) => setState(() => _range = value),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Earnings use your labor charge, or total less the platform '
                'service fee, and the job completion date. Unpaid jobs are '
                'excluded.',
                style: styles.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),
              if (earnings.entries.isEmpty)
                _EmptyEarnings(onExploreLeads: widget.onExploreLeads)
              else if (shown.isEmpty)
                _NoneInRange(range: _range)
              else
                for (final b in shown)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _EarningTile(
                      booking: b,
                      onOpen: () => widget.onOpen(b),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "12500" as "12,500".
String _grouped(int value) => value.toString().replaceAllMapped(
  RegExp(r'\B(?=(\d{3})+(?!\d))'),
  (_) => ',',
);

/// The blue card with this month's total.
class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.amount, required this.onPayoutCycle});

  final double amount;
  final VoidCallback onPayoutCycle;

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    final whole = amount.floor();
    final cents = ((amount - whole) * 100).round().clamp(0, 99);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.brand900, AppColors.brand700],
          ),
        ),
        child: Stack(
          children: [
            // Soft light spots, only decoration.
            Positioned(
              right: -40,
              top: -40,
              child: _Glow(color: AppColors.brand100.withValues(alpha: 0.22)),
            ),
            Positioned(
              left: -48,
              bottom: -48,
              child: _Glow(color: AppColors.accent500.withValues(alpha: 0.14)),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // The label and the button share one row. On a very narrow
                  // phone the button drops below the label instead.
                  LayoutBuilder(
                    builder: (context, box) {
                      final label = Text(
                        "THIS MONTH'S EARNINGS",
                        style: styles.caption.copyWith(
                          color: AppColors.brand100,
                          fontWeight: FontWeight.w700,
                        ),
                      );
                      final dot = Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.accent500,
                          shape: BoxShape.circle,
                        ),
                      );
                      final button = _PayoutCycleButton(
                        onPressed: onPayoutCycle,
                      );
                      if (box.maxWidth >= 300) {
                        return Row(
                          children: [
                            dot,
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(child: label),
                            const SizedBox(width: AppSpacing.xs),
                            button,
                          ],
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              dot,
                              const SizedBox(width: AppSpacing.xs),
                              Flexible(child: label),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          button,
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      key: const ValueKey('month-total'),
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          'LKR',
                          style: styles.h3.copyWith(color: AppColors.brand100),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          _grouped(whole),
                          style: styles.display.copyWith(color: Colors.white),
                        ),
                        Text(
                          '.${cents.toString().padLeft(2, '0')}',
                          style: styles.bodySmall.copyWith(
                            color: AppColors.brand100,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          LucideIcons.badgeCheck,
                          size: 18,
                          color: AppColors.accent100,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Flexible(
                          child: Text(
                            'Completed & paid jobs only',
                            style: styles.caption.copyWith(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      width: 170,
      height: 170,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    ),
  );
}

class _PayoutCycleButton extends StatelessWidget {
  const _PayoutCycleButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'How earnings are counted',
    child: InkWell(
      key: const ValueKey('payout-cycle'),
      onTap: onPressed,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        constraints: const BoxConstraints(minHeight: AppSizes.minTap),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.info, size: 18, color: Colors.white),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Payout cycle',
              style: context.textStyles.caption.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Shared look of the white cards.
BoxDecoration _cardDecoration() => BoxDecoration(
  color: AppColors.surface,
  borderRadius: AppRadius.card,
  border: Border.all(
    color: AppColors.borderSubtle,
    width: AppSizes.borderControl,
  ),
);

/// Completed jobs and total earnings, all time.
class _StatsCard extends StatelessWidget {
  const _StatsCard({
    required this.completedJobs,
    required this.totalEarnings,
    required this.onViewBreakdown,
  });

  final int completedJobs;
  final double totalEarnings;
  final VoidCallback onViewBreakdown;

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    return Container(
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: _StatRow(
              icon: LucideIcons.clipboardCheck,
              iconColor: AppColors.brand700,
              iconBackground: AppColors.brand100,
              label: 'Completed jobs · all time',
              value: '$completedJobs',
              valueKey: const ValueKey('completed-jobs'),
              styles: styles,
            ),
          ),
          const Divider(height: 0, color: AppColors.borderSubtle),
          InkWell(
            key: const ValueKey('total-earnings'),
            onTap: onViewBreakdown,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(AppRadius.cardRadius),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: _StatRow(
                      icon: LucideIcons.wallet,
                      iconColor: AppColors.accent700,
                      iconBackground: AppColors.accent100,
                      label: 'Total earnings · all time',
                      value: money(totalEarnings),
                      styles: styles,
                    ),
                  ),
                  const Icon(
                    LucideIcons.chevronRight,
                    color: AppColors.ink3,
                    semanticLabel: 'View recent earnings',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.label,
    required this.value,
    required this.styles,
    this.valueKey,
  });

  final IconData icon;
  final Color iconColor, iconBackground;
  final String label, value;
  final AppTextStyles styles;
  final Key? valueKey;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: iconBackground,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
      const SizedBox(width: AppSpacing.sm),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: styles.caption),
            Text(value, key: valueKey, style: styles.amount),
          ],
        ),
      ),
    ],
  );
}

/// "This Year" with a filter icon; opens the list of periods.
class _RangeMenu extends StatelessWidget {
  const _RangeMenu({required this.range, required this.onChanged});

  final EarningsRange range;
  final ValueChanged<EarningsRange> onChanged;

  @override
  Widget build(BuildContext context) => PopupMenuButton<EarningsRange>(
    key: const ValueKey('earnings-filter'),
    tooltip: 'Choose a period',
    initialValue: range,
    onSelected: onChanged,
    shape: RoundedRectangleBorder(borderRadius: AppRadius.card),
    itemBuilder: (_) => [
      for (final value in EarningsRange.values)
        PopupMenuItem(
          value: value,
          height: AppSizes.minTap,
          child: Text(
            value.label,
            style: context.textStyles.bodySmall.copyWith(
              fontWeight: value == range ? FontWeight.w700 : FontWeight.w400,
              color: AppColors.ink,
            ),
          ),
        ),
    ],
    child: Container(
      constraints: const BoxConstraints(minHeight: AppSizes.minTap),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            range.label,
            key: const ValueKey('earnings-range'),
            style: context.textStyles.label.copyWith(color: AppColors.brand700),
          ),
          const SizedBox(width: AppSpacing.xxs),
          const Icon(
            LucideIcons.slidersHorizontal,
            size: 18,
            color: AppColors.brand700,
          ),
        ],
      ),
    ),
  );
}

/// No paid job yet: a friendly card and a way back to the leads.
class _EmptyEarnings extends StatelessWidget {
  const _EmptyEarnings({required this.onExploreLeads});
  final VoidCallback? onExploreLeads;

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    return Semantics(
      container: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: _cardDecoration(),
        child: Column(
          children: [
            ExcludeSemantics(
              child: SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: AppColors.brand50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.banknote,
                        size: 32,
                        color: AppColors.brand700,
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.borderSubtle,
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          LucideIcons.sparkles,
                          size: 16,
                          color: AppColors.accent700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No earnings yet',
              textAlign: TextAlign.center,
              style: styles.h3,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Completed jobs with confirmed payment will appear right here.',
              textAlign: TextAlign.center,
              style: styles.bodySmall,
            ),
            if (onExploreLeads != null) ...[
              const SizedBox(height: AppSpacing.lg),
              AppPrimaryButton(
                key: const ValueKey('explore-leads'),
                label: 'Explore Available Job Leads',
                icon: LucideIcons.search,
                onPressed: onExploreLeads,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Earnings exist, but none in the chosen period.
class _NoneInRange extends StatelessWidget {
  const _NoneInRange({required this.range});
  final EarningsRange range;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('none-in-range'),
    width: double.infinity,
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: _cardDecoration(),
    child: Text(
      'No earnings in this period. Choose "All Time" to see every paid job.',
      textAlign: TextAlign.center,
      style: context.textStyles.bodySmall,
    ),
  );
}

class _EarningTile extends StatelessWidget {
  const _EarningTile({required this.booking, required this.onOpen});

  final Booking booking;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(booking.serviceName, style: styles.label)),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  money(booking.providerPayout),
                  textAlign: TextAlign.right,
                  style: styles.label.copyWith(color: AppColors.brand700),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(dateLabel(context, booking.completedAt), style: styles.caption),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onOpen,
              style: TextButton.styleFrom(
                minimumSize: const Size(AppSizes.minTap, AppSizes.minTap),
              ),
              child: const Text('View details'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Explains, from the app's own rules, which jobs count towards earnings.
class _PayoutInfoSheet extends StatelessWidget {
  const _PayoutInfoSheet();

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.accent100,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(
                    LucideIcons.circleHelp,
                    color: AppColors.accent700,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text('Earnings & Payouts', style: styles.h3)),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(LucideIcons.x),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Only jobs that are completed and paid are counted in your '
              'earnings.',
              style: styles.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: AppRadius.card,
              ),
              child: const Column(
                children: [
                  _InfoRow(label: 'Counted jobs', value: 'Completed and paid'),
                  SizedBox(height: AppSpacing.xs),
                  _InfoRow(
                    label: 'Amount per job',
                    value: 'Labor charge, or total less the service fee',
                  ),
                  SizedBox(height: AppSpacing.xs),
                  _InfoRow(
                    label: 'Month and year',
                    value: 'The job completion date',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppPrimaryButton(
              label: 'Got it',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label, value;

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label, style: styles.caption)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: styles.label.copyWith(color: AppColors.brand900),
          ),
        ),
      ],
    );
  }
}
