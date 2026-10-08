import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../models/booking.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/booking/booking_widgets.dart';
import '../../../widgets/common/app_widgets.dart';
import '../../../widgets/common/review_widgets.dart';
import '../customer_scope.dart';
import 'booking_details_screen.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  Stream<List<Booking>>? _bookings;
  bool _past = false;
  BookingStatus? _filter;

  static const _upcomingFilters = [
    BookingStatus.pending,
    BookingStatus.confirmed,
    BookingStatus.onTheWay,
    BookingStatus.inProgress,
  ];
  static const _pastFilters = [
    BookingStatus.completed,
    BookingStatus.cancelled,
    BookingStatus.declined,
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bookings ??= CustomerScope.of(context).bookings.watchBookings();
  }

  void _retry() => setState(
    () => _bookings = CustomerScope.of(context).bookings.watchBookings(),
  );

  void _open(Booking booking) => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => BookingDetailsScreen(bookingId: booking.id),
    ),
  );

  Future<void> _chooseFilter() async {
    final options = _past ? _pastFilters : _upcomingFilters;
    final picked = await showModalBottomSheet<(BookingStatus?,)>(
      context: context,
      useRootNavigator: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SheetHandle(),
              Text('Filter bookings', style: AppTypography.title),
              const SizedBox(height: AppSpacing.sm),
              RadioGroup<BookingStatus?>(
                groupValue: _filter,
                onChanged: (value) => Navigator.of(context).pop((value,)),
                child: Column(
                  children: [
                    const RadioListTile<BookingStatus?>(
                      value: null,
                      title: Text('All statuses'),
                      contentPadding: EdgeInsets.zero,
                    ),
                    for (final status in options)
                      RadioListTile<BookingStatus?>(
                        value: status,
                        title: Text(
                          status == BookingStatus.pending
                              ? 'Requested'
                              : status.label,
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    // Dismissing the sheet returns null; a selection is wrapped in a record.
    if (picked == null || !mounted) return;
    setState(() => _filter = picked.$1);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      bottom: false,
      child: StreamBuilder<List<Booking>>(
        stream: _bookings,
        builder: (context, snapshot) {
          final header = _Header(
            filtered: _filter != null,
            onFilter: snapshot.hasData ? _chooseFilter : null,
          );
          if (snapshot.hasError) {
            return Column(
              children: [
                header,
                Expanded(
                  child: ErrorState(error: snapshot.error!, onRetry: _retry),
                ),
              ],
            );
          }
          if (!snapshot.hasData) {
            return Column(
              children: [
                header,
                const Expanded(
                  child: LoadingState(message: 'Loading your bookings…'),
                ),
              ],
            );
          }
          final all = snapshot.data!;
          final upcoming = all.where((b) => b.status.isUpcoming).toList();
          final past = all.where((b) => b.status.isHistory).toList()
            ..sort(
              (a, b) => (b.scheduledAt ?? DateTime(1970)).compareTo(
                a.scheduledAt ?? DateTime(1970),
              ),
            );
          final tab = (_past ? past : upcoming)
              .where((b) => _filter == null || b.status == _filter)
              .toList();
          return ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
            children: [
              header,
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screen,
                ),
                child: _Tabs(
                  past: _past,
                  upcoming: upcoming.length,
                  completed: past.length,
                  onChanged: (past) => setState(() {
                    _past = past;
                    _filter = null;
                  }),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (all.isEmpty)
                const _NoBookings()
              else if (tab.isEmpty)
                _TabEmpty(past: _past, filtered: _filter != null)
              else
                for (final booking in tab)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screen,
                      0,
                      AppSpacing.screen,
                      AppSpacing.sm,
                    ),
                    child: BookingCard(
                      booking: booking,
                      onTap: () => _open(booking),
                      footer: booking.status == BookingStatus.completed
                          ? ReviewRatingLine(
                              prefix: 'Your rating',
                              stream: CustomerScope.of(context).bookings
                                  .watchReview(booking.id),
                            )
                          : null,
                    ),
                  ),
            ],
          );
        },
      ),
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.filtered, required this.onFilter});
  final bool filtered;
  final VoidCallback? onFilter;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.screen,
      AppSpacing.md,
      AppSpacing.screen,
      AppSpacing.md,
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Booking History', style: AppTypography.display),
              const SizedBox(height: 4),
              Text(
                'Manage bookings & download receipts',
                style: AppTypography.body.copyWith(color: AppColors.muted),
              ),
            ],
          ),
        ),
        Badge(
          isLabelVisible: filtered,
          backgroundColor: AppColors.primary,
          smallSize: 9,
          child: OutlinedButton.icon(
            onPressed: onFilter,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 38),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.navy,
              textStyle: AppTypography.label,
              shape: const StadiumBorder(),
            ),
            icon: const Icon(LucideIcons.slidersHorizontal, size: 16),
            label: const Text('Filter'),
          ),
        ),
      ],
    ),
  );
}

class _Tabs extends StatelessWidget {
  const _Tabs({
    required this.past,
    required this.upcoming,
    required this.completed,
    required this.onChanged,
  });

  final bool past;
  final int upcoming, completed;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(5),
    decoration: BoxDecoration(
      color: AppColors.surfaceLavenderDeep,
      borderRadius: AppRadius.chip,
    ),
    child: Row(
      children: [
        _tab('Upcoming ($upcoming)', !past, () => onChanged(false)),
        _tab('Past & Completed ($completed)', past, () => onChanged(true)),
      ],
    ),
  );

  Widget _tab(String label, bool selected, VoidCallback onTap) => Expanded(
    child: Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? AppColors.surface : Colors.transparent,
        shape: const StadiumBorder(),
        elevation: selected ? 1 : 0,
        shadowColor: AppColors.shadow,
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: AppTypography.subtitle.copyWith(
                  fontSize: 14.5,
                  color: selected ? AppColors.primary : AppColors.muted,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _TabEmpty extends StatelessWidget {
  const _TabEmpty({required this.past, required this.filtered});
  final bool past, filtered;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
    child: AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          IconTile(
            icon: past ? LucideIcons.history : LucideIcons.calendarClock,
            circle: true,
            size: 56,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            filtered
                ? 'No bookings match this filter'
                : past
                ? 'No past bookings yet'
                : 'Nothing scheduled',
            style: AppTypography.title,
          ),
          const SizedBox(height: 4),
          Text(
            filtered
                ? 'Try another status or clear the filter.'
                : past
                ? 'Completed and cancelled jobs will appear here.'
                : 'Book a service and it will show up here.',
            textAlign: TextAlign.center,
            style: AppTypography.caption,
          ),
          if (!past && !filtered) ...[
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              label: 'Find a Service',
              icon: LucideIcons.arrowRight,
              onPressed: () =>
                  CustomerScope.of(context)
                      .selectTab(CustomerTab.home, reset: true),
            ),
          ],
        ],
      ),
    ),
  );
}

class _NoBookings extends StatelessWidget {
  const _NoBookings();

  static const _popular = [
    'AC Repair',
    'Plumbing',
    'Deep Cleaning',
    'Electrician',
  ];

  @override
  Widget build(BuildContext context) {
    void findService() =>
        CustomerScope.of(context).selectTab(CustomerTab.home, reset: true);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
      child: Column(
        children: [
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                const EmptyIllustration(
                  icon: LucideIcons.calendarX,
                  topBadge: LucideIcons.chevronLeft,
                  bottomBadge: LucideIcons.wrench,
                ),
                const SizedBox(height: AppSpacing.md),
                Text('No Bookings Yet', style: AppTypography.headline),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  "You haven't booked any home services yet. From AC "
                  'servicing to plumbing and electrical repairs, our verified '
                  'pros are ready across Sri Lanka.',
                  textAlign: TextAlign.center,
                  style: AppTypography.body,
                ),
                const SizedBox(height: AppSpacing.lg),
                PrimaryButton(
                  label: 'Find a Service →',
                  onPressed: findService,
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLavender,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            LucideIcons.flame,
                            size: 14,
                            color: AppColors.muted,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'POPULAR ACROSS COLOMBO & SUBURBS',
                              style: AppTypography.overline.copyWith(
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          for (final name in _popular)
                            ActionChip(
                              label: Text(name),
                              onPressed: findService,
                              backgroundColor: AppColors.primarySoft,
                              side: BorderSide.none,
                              shape: const StadiumBorder(),
                              labelStyle: AppTypography.label.copyWith(
                                color: AppColors.body,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const AppCard(
            child: Row(
              children: [
                IconTile(
                  icon: LucideIcons.shieldCheck,
                  circle: true,
                  size: 48,
                  color: AppColors.navy,
                  background: AppColors.accentMint,
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('HomeCare Guarantee', style: AppTypography.subtitle),
                      Text(
                        'Vetted technicians, upfront LKR rates & job '
                        'protection.',
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton.icon(
            onPressed: () => launchContact(context, 'tel', homeCareHotline),
            icon: const Icon(LucideIcons.headphones, size: 16),
            label: const Text(
              'Need custom emergency service? Call $homeCareHotline',
            ),
            style: TextButton.styleFrom(foregroundColor: AppColors.body),
          ),
        ],
      ),
    );
  }
}
