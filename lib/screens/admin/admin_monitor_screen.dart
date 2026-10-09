import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../models/app_user.dart';
import '../../models/booking.dart';
import '../../services/admin_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/common/app_bottom_nav.dart';
import '../../widgets/common/app_search_bar.dart';
import '../../widgets/common/app_widgets.dart';

/// Live view of the whole platform for admins: an overview with key numbers
/// and recent activity, every customer, and every booking. Everything is
/// driven by Firestore streams, so it updates as things happen.
class AdminMonitorScreen extends StatefulWidget {
  const AdminMonitorScreen({super.key, required this.service});
  final AdminService service;

  @override
  State<AdminMonitorScreen> createState() => _AdminMonitorScreenState();
}

class _AdminMonitorScreenState extends State<AdminMonitorScreen> {
  late Stream<List<AppUser>> _customers = widget.service.watchCustomers();
  late Stream<List<Booking>> _bookings = widget.service.watchAllBookings();

  void _retry() => setState(() {
    _customers = widget.service.watchCustomers();
    _bookings = widget.service.watchAllBookings();
  });

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Platform monitor'),
        bottom: const TabBar(
          tabs: [
            Tab(text: 'Customers'),
            Tab(text: 'Bookings'),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        items: AppBottomNav.localizedAdminItems(context),
        selectedIndex: 4,
        onSelected: (index) => Navigator.of(context).pop(index),
      ),
      body: StreamBuilder<List<Booking>>(
        stream: _bookings,
        builder: (context, bookingSnap) => StreamBuilder<List<AppUser>>(
          stream: _customers,
          builder: (context, customerSnap) {
            final error = bookingSnap.error ?? customerSnap.error;
            if (error != null) return ErrorState(error: error, onRetry: _retry);
            if (!bookingSnap.hasData || !customerSnap.hasData) {
              return const LoadingState();
            }
            final bookings = bookingSnap.data!;
            final customers = customerSnap.data!;
            return TabBarView(
              children: [
                _CustomersTab(customers: customers, bookings: bookings),
                _BookingsTab(bookings: bookings),
              ],
            );
          },
        ),
      ),
    ),
  );
}

// ------------------------------------------------------------------ helpers
(Color, Color) _statusColors(BookingStatus status) => switch (status) {
  BookingStatus.completed => (AppColors.successSoft, AppColors.successText),
  BookingStatus.cancelled ||
  BookingStatus.declined => (AppColors.errorSoft, AppColors.errorText),
  BookingStatus.pending => (AppColors.accent100, AppColors.accent700),
  _ => (AppColors.brand100, AppColors.brand700),
};

class _StatusChip extends StatelessWidget {
  const _StatusChip(this.status);
  final BookingStatus status;

  @override
  Widget build(BuildContext context) {
    final (background, color) = _statusColors(status);
    return StatusPill(label: status.label, background: background, color: color);
  }
}

String _when(DateTime? date) =>
    date == null ? '—' : '${Formatters.shortDate(date)} · ${Formatters.clock(date)}';

// ---------------------------------------------------------------- customers
class _CustomersTab extends StatefulWidget {
  const _CustomersTab({required this.customers, required this.bookings});
  final List<AppUser> customers;
  final List<Booking> bookings;

  @override
  State<_CustomersTab> createState() => _CustomersTabState();
}

class _CustomersTabState extends State<_CustomersTab> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final shown = widget.customers.where((c) {
      if (query.isEmpty) return true;
      return c.name.toLowerCase().contains(query) ||
          c.email.toLowerCase().contains(query) ||
          (c.phone ?? '').contains(query);
    }).toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.screen),
          child: AppSearchBar(
            controller: _search,
            hintText: 'Search name, email or phone…',
            onChanged: (_) => setState(() {}),
            onClear: () => setState(() {}),
          ),
        ),
        Expanded(
          child: shown.isEmpty
              ? Center(
                  child: Text(
                    widget.customers.isEmpty
                        ? 'No customers yet.'
                        : 'No customers match your search.',
                    style: context.textStyles.bodySmall,
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screen,
                    0,
                    AppSpacing.screen,
                    AppSpacing.xl,
                  ),
                  itemCount: shown.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, i) {
                    final customer = shown[i];
                    final mine = widget.bookings
                        .where((b) => b.customerId == customer.uid)
                        .toList();
                    return AppCard(
                      key: ValueKey('customer-${customer.uid}'),
                      border: Border.all(color: AppColors.borderSubtle),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => _CustomerDetailScreen(
                            customer: customer,
                            bookings: mine,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          PersonAvatar(
                            name: customer.name,
                            photoUrl: customer.photoUrl,
                            size: 44,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  customer.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.textStyles.label,
                                ),
                                Text(
                                  customer.email,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.textStyles.caption,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${mine.length} booking${mine.length == 1 ? '' : 's'}',
                            style: context.textStyles.caption,
                          ),
                          const Icon(
                            LucideIcons.chevronRight,
                            size: 18,
                            color: AppColors.ink3,
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _CustomerDetailScreen extends StatelessWidget {
  const _CustomerDetailScreen({required this.customer, required this.bookings});
  final AppUser customer;
  final List<Booking> bookings;

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    final spent = bookings
        .where((b) => b.status == BookingStatus.completed)
        .fold<double>(0, (sum, b) => sum + b.chargeTotal);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Customer'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screen),
        children: [
          AppCard(
            border: Border.all(color: AppColors.borderSubtle),
            child: Column(
              children: [
                PersonAvatar(
                  name: customer.name,
                  photoUrl: customer.photoUrl,
                  size: 72,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(customer.name, style: styles.h2),
                const SizedBox(height: AppSpacing.sm),
                _DetailRow(LucideIcons.mail, 'Email', customer.email),
                _DetailRow(
                  LucideIcons.phone,
                  'Phone',
                  (customer.phone ?? '').isEmpty ? 'Not provided' : customer.phone!,
                ),
                _DetailRow(LucideIcons.idCard, 'Customer ID', customer.uid),
                _DetailRow(
                  LucideIcons.banknote,
                  'Completed spend',
                  Formatters.lkr(spent),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('BOOKINGS (${bookings.length})', style: styles.caption),
          const SizedBox(height: AppSpacing.xs),
          if (bookings.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                'This customer has no bookings yet.',
                textAlign: TextAlign.center,
                style: styles.bodySmall,
              ),
            ),
          for (final booking in bookings) ...[
            AdminBookingTile(booking: booking, showCustomer: false),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.icon, this.label, this.value);
  final IconData icon;
  final String label, value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.brand700),
        const SizedBox(width: AppSpacing.xs),
        SizedBox(
          width: 110,
          child: Text(label, style: context.textStyles.caption),
        ),
        Expanded(
          child: SelectableText(value, style: context.textStyles.label),
        ),
      ],
    ),
  );
}

// ----------------------------------------------------------------- bookings
class _BookingsTab extends StatefulWidget {
  const _BookingsTab({required this.bookings});
  final List<Booking> bookings;

  @override
  State<_BookingsTab> createState() => _BookingsTabState();
}

class _BookingsTabState extends State<_BookingsTab> {
  final _search = TextEditingController();
  BookingStatus? _status;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final shown = widget.bookings.where((b) {
      if (_status != null && b.status != _status) return false;
      if (query.isEmpty) return true;
      return b.serviceName.toLowerCase().contains(query) ||
          b.customerName.toLowerCase().contains(query) ||
          (b.providerName ?? '').toLowerCase().contains(query) ||
          (b.reference ?? '').toLowerCase().contains(query) ||
          b.id.toLowerCase().contains(query);
    }).toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.screen,
            AppSpacing.screen,
            AppSpacing.xs,
          ),
          child: AppSearchBar(
            controller: _search,
            hintText: 'Search service, customer, provider or ref…',
            onChanged: (_) => setState(() {}),
            onClear: () => setState(() {}),
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            children: [
              for (final status in [null, ...BookingStatus.values])
                if (status != BookingStatus.unknown)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: ChoiceChip(
                      label: Text(
                        status == null
                            ? 'All (${widget.bookings.length})'
                            : '${status.label} (${widget.bookings.where((b) => b.status == status).length})',
                      ),
                      selected: _status == status,
                      onSelected: (_) => setState(() => _status = status),
                    ),
                  ),
            ],
          ),
        ),
        Expanded(
          child: shown.isEmpty
              ? Center(
                  child: Text(
                    'No bookings found.',
                    style: context.textStyles.bodySmall,
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.screen),
                  itemCount: shown.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, i) => AdminBookingTile(booking: shown[i]),
                ),
        ),
      ],
    );
  }
}

class AdminBookingTile extends StatelessWidget {
  const AdminBookingTile({super.key, required this.booking, this.showCustomer = true});
  final Booking booking;
  final bool showCustomer;

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    final people = [
      if (showCustomer) booking.customerName,
      if ((booking.providerName ?? '').isNotEmpty) booking.providerName!,
    ].join(' → ');
    return AppCard(
      key: ValueKey('booking-${booking.id}'),
      border: Border.all(color: AppColors.borderSubtle),
      onTap: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.surface,
        builder: (_) => _BookingSheet(booking: booking),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.serviceName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: styles.label,
                ),
                if (people.isNotEmpty)
                  Text(
                    people,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: styles.bodySmall,
                  ),
                Text(
                  _when(booking.scheduledAt ?? booking.createdAt),
                  style: styles.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _StatusChip(booking.status),
              const SizedBox(height: 4),
              Text(Formatters.lkr(booking.chargeTotal), style: styles.caption),
            ],
          ),
        ],
      ),
    );
  }
}

class _BookingSheet extends StatelessWidget {
  const _BookingSheet({required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final b = booking;
    String orDash(String? v) => v == null || v.isEmpty ? '—' : v;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screen),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    b.serviceName,
                    style: context.textStyles.h2,
                  ),
                ),
                _StatusChip(b.status),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _DetailRow(LucideIcons.hash, 'Reference', orDash(b.reference ?? b.id)),
            _DetailRow(LucideIcons.user, 'Customer', orDash(b.customerName)),
            _DetailRow(LucideIcons.phone, 'Contact phone', orDash(b.contactPhone)),
            _DetailRow(LucideIcons.wrench, 'Provider', orDash(b.providerName)),
            _DetailRow(LucideIcons.mapPin, 'Address', orDash(b.address)),
            _DetailRow(
              LucideIcons.calendar,
              'Scheduled',
              _when(b.scheduledAt),
            ),
            _DetailRow(LucideIcons.clock, 'Booked on', _when(b.createdAt)),
            _DetailRow(
              LucideIcons.refreshCw,
              'Last update',
              _when(b.updatedAt),
            ),
            _DetailRow(
              LucideIcons.creditCard,
              'Payment',
              '${orDash(b.paymentMethod)} · ${orDash(b.paymentStatus)}',
            ),
            _DetailRow(
              LucideIcons.banknote,
              'Total',
              Formatters.lkr(b.chargeTotal),
            ),
            if ((b.cancellationReason ?? '').isNotEmpty)
              _DetailRow(
                LucideIcons.circleX,
                'Cancel reason',
                b.cancellationReason!,
              ),
            if (b.jobNotes.isNotEmpty)
              _DetailRow(LucideIcons.fileText, 'Job notes', b.jobNotes),
          ],
        ),
      ),
    );
  }
}
