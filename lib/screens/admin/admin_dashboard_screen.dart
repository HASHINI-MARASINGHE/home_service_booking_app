import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../models/app_user.dart';
import '../../models/booking.dart';
import '../../services/admin_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/common/app_widgets.dart';
import 'admin_monitor_screen.dart';

/// The admin Home tab: live platform numbers and recent activity.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key, required this.service});
  final AdminService service;

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late Stream<List<AppUser>> _customers = widget.service.watchCustomers();
  late Stream<List<Booking>> _bookings = widget.service.watchAllBookings();

  void _retry() => setState(() {
    _customers = widget.service.watchCustomers();
    _bookings = widget.service.watchAllBookings();
  });

  @override
  Widget build(BuildContext context) => StreamBuilder<List<Booking>>(
    stream: _bookings,
    builder: (context, bookingSnap) => StreamBuilder<List<AppUser>>(
      stream: _customers,
      builder: (context, customerSnap) {
        final error = bookingSnap.error ?? customerSnap.error;
        if (error != null) return ErrorState(error: error, onRetry: _retry);
        if (!bookingSnap.hasData || !customerSnap.hasData) {
          return const LoadingState();
        }
        return _Overview(
          service: widget.service,
          customers: customerSnap.data!,
          bookings: bookingSnap.data!,
        );
      },
    ),
  );
}

class _Overview extends StatelessWidget {
  const _Overview({
    required this.service,
    required this.customers,
    required this.bookings,
  });
  final AdminService service;
  final List<AppUser> customers;
  final List<Booking> bookings;

  @override
  Widget build(BuildContext context) {
    final active = bookings.where((b) => b.status.isUpcoming).length;
    final completed = bookings.where((b) => b.status == BookingStatus.completed);
    final cancelled = bookings.where(
      (b) =>
          b.status == BookingStatus.cancelled ||
          b.status == BookingStatus.declined,
    );
    final revenue = completed.fold<double>(0, (sum, b) => sum + b.chargeTotal);
    final recent = [...bookings]
      ..sort(
        (a, b) => (b.updatedAt ?? b.createdAt ?? DateTime(0)).compareTo(
          a.updatedAt ?? a.createdAt ?? DateTime(0),
        ),
      );
    final styles = context.textStyles;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screen),
      children: [
        Row(
          children: [
            const Icon(LucideIcons.radio, size: 14, color: AppColors.success),
            const SizedBox(width: 6),
            Text('Live · updates automatically', style: styles.caption),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: 1.7,
          children: [
            _StatCard(
              icon: LucideIcons.users,
              label: 'Customers',
              value: '${customers.length}',
            ),
            _StatCard(
              icon: LucideIcons.calendarCheck,
              label: 'Total bookings',
              value: '${bookings.length}',
            ),
            _StatCard(
              icon: LucideIcons.activity,
              label: 'Active now',
              value: '$active',
            ),
            _StatCard(
              icon: LucideIcons.circleCheck,
              label: 'Completed',
              value: '${completed.length}',
            ),
            _StatCard(
              icon: LucideIcons.circleX,
              label: 'Cancelled / declined',
              value: '${cancelled.length}',
            ),
            _StatCard(
              icon: LucideIcons.banknote,
              label: 'Completed value',
              value: Formatters.lkr(revenue),
            ),
            StreamBuilder<int>(
              stream: service.watchPendingDisputeCount(),
              builder: (context, snap) => _StatCard(
                icon: LucideIcons.triangleAlert,
                label: 'Open disputes',
                value: '${snap.data ?? 0}',
              ),
            ),
            StreamBuilder<int>(
              stream: service.watchPendingCount(),
              builder: (context, snap) => _StatCard(
                icon: LucideIcons.shieldCheck,
                label: 'Verifications waiting',
                value: '${snap.data ?? 0}',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('RECENT ACTIVITY', style: styles.caption),
        const SizedBox(height: AppSpacing.xs),
        if (recent.isEmpty)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              'No bookings yet.',
              textAlign: TextAlign.center,
              style: styles.bodySmall,
            ),
          ),
        for (final booking in recent.take(10)) ...[
          AdminBookingTile(booking: booking),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label, value;

  @override
  Widget build(BuildContext context) => AppCard(
    border: Border.all(color: AppColors.borderSubtle),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Icon(icon, size: 20, color: AppColors.brand700),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: context.textStyles.h2.copyWith(color: AppColors.brand900),
          ),
        ),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textStyles.caption,
        ),
      ],
    ),
  );
}
