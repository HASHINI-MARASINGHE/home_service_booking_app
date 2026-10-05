import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../models/address.dart';
import '../../../models/booking.dart';
import '../../../services/app_error.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/address/address_widgets.dart';
import '../../../widgets/common/app_widgets.dart';
import '../customer_scope.dart';
import 'address_form_screen.dart';

class MyAddressesScreen extends StatefulWidget {
  const MyAddressesScreen({super.key});

  @override
  State<MyAddressesScreen> createState() => _MyAddressesScreenState();
}

class _MyAddressesScreenState extends State<MyAddressesScreen> {
  Stream<List<Address>>? _addresses;
  StreamSubscription<List<Booking>>? _bookingSub;
  Map<String, int> _activeJobs = const {};
  final _search = TextEditingController();
  String _category = 'All';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_addresses == null) _subscribe(rebuild: false);
  }

  void _subscribe({bool rebuild = true}) {
    final scope = CustomerScope.of(context);
    _addresses = scope.addresses.watchAddresses();
    if (rebuild) setState(() {});
    _bookingSub?.cancel();
    // Active job counts per address are a nice-to-have; failures are silent.
    _bookingSub = scope.bookings.watchBookings().listen((bookings) {
      final counts = <String, int>{};
      for (final b in bookings.where((b) => b.status.isUpcoming)) {
        final id = b.addressId;
        if (id != null) counts[id] = (counts[id] ?? 0) + 1;
      }
      if (mounted) setState(() => _activeJobs = counts);
    }, onError: (_) {});
  }

  @override
  void dispose() {
    _bookingSub?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _openForm({String? addressId, bool locate = false}) async {
    final saved = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) =>
            AddressFormScreen(addressId: addressId, autoLocate: locate),
      ),
    );
    if (saved != null && mounted) {
      showAppSnack(
        context,
        addressId == null ? 'Address saved.' : 'Address updated.',
      );
    }
  }

  Future<void> _setDefault(Address address) async {
    try {
      await CustomerScope.of(context).addresses.setDefault(address.id);
      if (mounted) showAppSnack(context, '${address.label} is now default.');
    } catch (error) {
      if (mounted) showAppSnack(context, AppError.message(error), error: true);
    }
  }

  Future<void> _delete(Address address) async {
    final service = CustomerScope.of(context).addresses;
    List<Booking> linked;
    try {
      linked = await service.linkedActiveBookings(address.id);
    } catch (error) {
      if (mounted) showAppSnack(context, AppError.message(error), error: true);
      return;
    }
    if (!mounted) return;
    final deleted = await ConfirmationBottomSheet.show(
      context,
      ConfirmationBottomSheet(
        icon: LucideIcons.trash2,
        title: "Delete '${address.label}' address?",
        message: TextSpan(
          children: [
            const TextSpan(text: 'Are you sure you want to remove '),
            TextSpan(
              text: address.line,
              style: const TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.w700,
              ),
            ),
            const TextSpan(text: ' from your saved addresses?'),
          ],
        ),
        highlight: linked.isEmpty ? null : _LinkedBookingWarning(linked),
        keepIsPrimary: false,
        keepLabel: 'Cancel & Keep Address',
        keepIcon: LucideIcons.x,
        confirmLabel: 'Yes, Delete Address',
        confirmIcon: LucideIcons.trash2,
        onConfirm: () => service.delete(address),
      ),
    );
    if (deleted && mounted) {
      showAppSnack(
        context,
        linked.isEmpty
            ? 'Address deleted.'
            : 'Address deleted. Update the service location on '
                  '${linked.length == 1 ? 'your booking' : 'your bookings'}.',
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      bottom: false,
      child: StreamBuilder<List<Address>>(
        stream: _addresses,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Column(
              children: [
                _Header(onAdd: () => _openForm()),
                Expanded(
                  child: ErrorState(
                    error: snapshot.error!,
                    onRetry: _subscribe,
                  ),
                ),
              ],
            );
          }
          if (!snapshot.hasData) {
            return Column(
              children: [
                _Header(onAdd: () => _openForm()),
                const Expanded(
                  child: LoadingState(message: 'Loading your addresses…'),
                ),
              ],
            );
          }
          final all = snapshot.data!;
          if (all.isEmpty) {
            return ListView(
              padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
              children: [
                _Header(onAdd: () => _openForm()),
                _EmptyAddresses(
                  onAdd: () => _openForm(),
                  onLocate: () => _openForm(locate: true),
                ),
              ],
            );
          }
          final visible = all
              .where((a) => _category == 'All' || a.type.category == _category)
              .where((a) => a.matches(_search.text))
              .toList();
          return ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
            children: [
              _Header(onAdd: () => _openForm()),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screen,
                ),
                child: TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search saved addresses, landmarks...',
                    prefixIcon: const Icon(
                      LucideIcons.search,
                      color: AppColors.muted,
                      size: 20,
                    ),
                    suffixIcon: _search.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            icon: const Icon(LucideIcons.x, size: 18),
                            onPressed: () => setState(_search.clear),
                          ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppRadius.field,
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screen,
                ),
                child: ChoiceChips<String>(
                  values: const ['All', ...AddressType.categories],
                  selected: _category,
                  labelOf: (c) => c == 'All' ? 'All (${all.length})' : c,
                  onSelected: (c) => setState(() => _category = c),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (visible.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Text(
                    'No saved addresses match your search.',
                    textAlign: TextAlign.center,
                    style: AppTypography.body,
                  ),
                ),
              for (final address in visible)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screen,
                    0,
                    AppSpacing.screen,
                    AppSpacing.md,
                  ),
                  child: AddressCard(
                    address: address,
                    activeJobs: _activeJobs[address.id] ?? 0,
                    onEdit: () => _openForm(addressId: address.id),
                    onDelete: () => _delete(address),
                    onSetDefault: () => _setDefault(address),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screen,
                ),
                child: PrimaryButton(
                  label: 'Add New Address',
                  icon: LucideIcons.mapPin,
                  onPressed: () => _openForm(),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.screen),
                child: InfoBanner(
                  title: 'Verified Locations Only',
                  message:
                      'All service partners are police-cleared and equipped '
                      'with live GPS route guidance to your doorstep.',
                  icon: LucideIcons.shieldCheck,
                  iconFilled: false,
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
  const _Header({required this.onAdd});
  final VoidCallback onAdd;

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
              Text('My Addresses', style: AppTypography.display),
              const SizedBox(height: 4),
              Text(
                'Manage your service locations',
                style: AppTypography.body.copyWith(color: AppColors.muted),
              ),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: onAdd,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 38),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.navy,
            textStyle: AppTypography.label,
            shape: const StadiumBorder(),
          ),
          icon: const Icon(LucideIcons.plus, size: 16),
          label: const Text('Add New'),
        ),
      ],
    ),
  );
}

class _LinkedBookingWarning extends StatelessWidget {
  const _LinkedBookingWarning(this.bookings);
  final List<Booking> bookings;

  @override
  Widget build(BuildContext context) {
    final first = bookings.first;
    final date = Formatters.parseIsoDate(first.slotDate) ?? first.scheduledAt;
    final when = date == null
        ? ''
        : ' on ${Formatters.longDate(date).split(',').first}, '
              '${date.day} ${Formatters.month(date)}';
    final underway =
        first.status == BookingStatus.onTheWay ||
        first.status == BookingStatus.inProgress;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warningSoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.warningBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            LucideIcons.alertTriangle,
            size: 18,
            color: AppColors.warning,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bookings.length == 1
                      ? 'ACTIVE BOOKING LINKED'
                      : '${bookings.length} ACTIVE BOOKINGS LINKED',
                  style: AppTypography.overline.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: 'This address is currently linked to booking ',
                      ),
                      TextSpan(
                        text: '#${first.displayReference}',
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(text: ' (${first.serviceName}$when). '),
                      TextSpan(
                        text: underway
                            ? 'The professional is already on the way, so '
                                  'this address cannot be deleted yet.'
                            : "Deleting this will require updating that "
                                  "booking's service location.",
                      ),
                    ],
                  ),
                  style: AppTypography.caption.copyWith(color: AppColors.body),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyAddresses extends StatelessWidget {
  const _EmptyAddresses({required this.onAdd, required this.onLocate});
  final VoidCallback onAdd, onLocate;

  static const _zones = [
    'Colombo 03 – 07',
    'Rajagiriya',
    'Mount Lavinia',
    'Battaramulla',
  ];

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
    child: Column(
      children: [
        const SizedBox(height: AppSpacing.xs),
        const EmptyIllustration(
          icon: LucideIcons.home,
          topBadge: LucideIcons.mapPin,
          bottomBadge: Icons.star_rounded,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'No Saved Addresses',
          style: AppTypography.headline,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          "Save your home, office, or parents' addresses for swift, 1-tap "
          'bookings and seamless technician dispatch across Colombo and '
          'suburbs.',
          textAlign: TextAlign.center,
          style: AppTypography.body.copyWith(color: AppColors.muted),
        ),
        const SizedBox(height: AppSpacing.xl),
        PrimaryButton(
          label: 'Add Your First Address',
          icon: LucideIcons.plus,
          color: AppColors.primaryDark,
          onPressed: onAdd,
        ),
        const SizedBox(height: AppSpacing.sm),
        SecondaryButton(
          label: 'Use Current GPS Location',
          icon: LucideIcons.locateFixed,
          onPressed: onLocate,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionLabel(
                'Popular service zones',
                trailing: StatusPill(label: 'Covered'),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final zone in _zones)
                    StatusPill(
                      label: zone,
                      dot: true,
                      color: AppColors.navy,
                      background: AppColors.surfaceLavender,
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const InfoBanner(
          title: 'Verified Sri Lankan Technicians',
          message: 'NIC-vetted, insured, & background checked',
          iconFilled: false,
        ),
      ],
    ),
  );
}
