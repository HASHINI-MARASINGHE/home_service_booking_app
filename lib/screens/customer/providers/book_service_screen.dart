import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../models/address.dart';
import '../../../models/booking_policy.dart';
import '../../../models/professional.dart';
import '../../../services/app_error.dart';
import '../../../services/customer_booking_service.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/customer_home_theme.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/common/app_widgets.dart';
import '../addresses/address_form_screen.dart';
import '../customer_scope.dart';
import 'book_provider.dart';
import 'provider_service_icon.dart';

/// Book Service: pick a service, date, time and location, then confirm.
class BookServiceScreen extends StatefulWidget {
  const BookServiceScreen({
    super.key,
    required this.professional,
    this.serviceName,
  });

  final Professional professional;

  /// Preselected service; defaults to the provider's first service.
  final String? serviceName;

  @override
  State<BookServiceScreen> createState() => _BookServiceScreenState();
}

class _BookServiceScreenState extends State<BookServiceScreen> {
  Professional get _pro => widget.professional;

  /// The provider's services, or their profession when none are listed.
  late final List<String> _services = _pro.services.isNotEmpty
      ? _pro.services
      : [if (_pro.specialty.trim().isNotEmpty) _pro.specialty.trim()];
  late String? _service =
      widget.serviceName != null && _services.contains(widget.serviceName)
      ? widget.serviceName
      : _services.firstOrNull;

  late List<DateTime> _days;
  DateTime? _date;
  Future<List<TimeSlot>>? _slots;
  TimeSlot? _slot;

  Address? _address;
  bool _addressesLoaded = false;
  bool _saving = false;

  CustomerBookingService get _bookings => CustomerScope.of(context).bookings;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_date != null) return;
    _days = BookingPolicy.calendarDays(_bookings.now());
    _selectDate(
      _days.firstWhere(
        (d) => _pro.workingDays.contains(d.weekday),
        orElse: () => _days.first,
      ),
      notify: false,
    );
    _loadDefaultAddress();
  }

  void _selectDate(DateTime date, {bool notify = true}) {
    void apply() {
      _date = date;
      _slot = null;
      _slots = _loadSlots(date);
    }

    notify ? setState(apply) : apply();
  }

  Future<List<TimeSlot>> _loadSlots(DateTime date) async {
    try {
      return await _bookings.openSlots(professional: _pro, date: date);
    } catch (error) {
      return Future.error(error);
    }
  }

  Future<void> _loadDefaultAddress() async {
    final scope = CustomerScope.of(context);
    try {
      final all = await scope.addresses.getAddresses();
      if (!mounted) return;
      setState(() {
        _address = all.where((a) => a.isDefault).firstOrNull ?? all.firstOrNull;
        _addressesLoaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _addressesLoaded = true);
    }
  }

  Future<void> _chooseService() async {
    if (_services.length < 2) return;
    final picked = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      builder: (sheet) => _ChoiceSheet(
        title: 'Choose a service',
        children: [
          for (final s in _services)
            ListTile(
              leading: Icon(serviceIcon(s), color: CustomerHomeTheme.primary),
              title: Text(s),
              trailing: s == _service
                  ? const Icon(Icons.check, color: CustomerHomeTheme.primary)
                  : null,
              onTap: () => Navigator.of(sheet).pop(s),
            ),
        ],
      ),
    );
    if (picked != null && mounted) setState(() => _service = picked);
  }

  Future<void> _chooseAddress() async {
    final scope = CustomerScope.of(context);
    List<Address> all;
    try {
      all = await scope.addresses.getAddresses();
    } catch (error) {
      if (mounted) showAppSnack(context, AppError.message(error), error: true);
      return;
    }
    if (!mounted) return;
    if (all.isEmpty) return _addAddress();
    final picked = await showModalBottomSheet<Object>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheet) => _ChoiceSheet(
        title: 'Service location',
        children: [
          for (final a in all)
            ListTile(
              leading: const Icon(
                LucideIcons.mapPin,
                color: CustomerHomeTheme.primary,
              ),
              title: Text(a.label),
              subtitle: Text(a.line),
              trailing: a.id == _address?.id
                  ? const Icon(Icons.check, color: CustomerHomeTheme.primary)
                  : null,
              onTap: () => Navigator.of(sheet).pop(a),
            ),
          ListTile(
            leading: const Icon(Icons.add, color: CustomerHomeTheme.primary),
            title: const Text('Add new address'),
            onTap: () => Navigator.of(sheet).pop(#add),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (picked is Address) setState(() => _address = picked);
    if (picked == #add) await _addAddress();
  }

  Future<void> _addAddress() async {
    final scope = CustomerScope.of(context);
    final id = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const AddressFormScreen()),
    );
    if (id == null || !mounted) return;
    try {
      final address = await scope.addresses.getAddress(id);
      if (address != null && mounted) setState(() => _address = address);
    } catch (error) {
      if (mounted) showAppSnack(context, AppError.message(error), error: true);
    }
  }

  String? get _missing => _service == null
      ? 'This provider has not listed any services yet.'
      : _slot == null
      ? 'Select a time.'
      : _address == null
      ? 'Add a service location.'
      : null;

  Future<void> _confirm() async {
    final missing = _missing;
    if (missing != null) {
      showAppSnack(context, missing, error: true);
      return;
    }
    setState(() => _saving = true);
    final scope = CustomerScope.of(context);
    try {
      final id = await scope.bookings.createBooking(
        BookingRequest(
          professional: _pro,
          serviceName: _service!,
          slot: _slot!,
          address: _address!,
          customerName: scope.user.name,
        ),
      );
      if (mounted) await onBookingCreated(context, id);
    } catch (error) {
      if (!mounted) return;
      showAppSnack(context, AppError.message(error), error: true);
      // A taken slot or expired time: refresh the times for this day.
      if (error is SlotTakenException || error is BookingChangedException) {
        _selectDate(_date!);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: CustomerHomeTheme.background,
    child: SafeArea(
      bottom: false,
      child: Column(
        children: [
          const ScreenHeader(title: 'Book Service'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
              children: [
                _ServiceCard(
                  name: _service ?? 'No services listed',
                  subtitle: _pro.specialty,
                  onTap: _services.length > 1 ? _chooseService : null,
                ),
                const SizedBox(height: 12),
                _ProviderCard(professional: _pro),
                const SizedBox(height: 20),
                const _Label('Select Date'),
                const SizedBox(height: 10),
                SizedBox(
                  height: 74,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _days.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final day = _days[index];
                      final works = _pro.workingDays.contains(day.weekday);
                      return _DayChip(
                        date: day,
                        selected: day == _date,
                        enabled: works,
                        onTap: works && !_saving
                            ? () => _selectDate(day)
                            : null,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                const _Label('Select Time'),
                const SizedBox(height: 10),
                FutureBuilder<List<TimeSlot>>(
                  future: _slots,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return _Hint(
                        'Could not load times.',
                        action: TextButton(
                          onPressed: () => _selectDate(_date!),
                          child: const Text('Retry'),
                        ),
                      );
                    }
                    final slots = snapshot.data;
                    if (slots == null) {
                      return const Padding(
                        padding: EdgeInsets.all(12),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (!slots.any((s) => s.selectable)) {
                      return const _Hint(
                        'No free times on this day. Try another date.',
                      );
                    }
                    return Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final slot in slots)
                          _TimeChip(
                            label: Formatters.time12(
                              slot.start,
                              padHour: false,
                            ),
                            selected: slot.start == _slot?.start,
                            onTap: slot.selectable && !_saving
                                ? () => setState(() => _slot = slot)
                                : null,
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
                const _Label('Service Location'),
                const SizedBox(height: 10),
                _LocationCard(
                  address: _address,
                  loading: !_addressesLoaded,
                  onTap: _saving ? null : _chooseAddress,
                ),
                const SizedBox(height: 16),
                _TotalCard(pricing: _pro.pricing),
                const SizedBox(height: 20),
                SizedBox(
                  height: 54,
                  child: FilledButton(
                    onPressed: _saving ? null : _confirm,
                    style: FilledButton.styleFrom(
                      backgroundColor: CustomerHomeTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Confirm Booking',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
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

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: CustomerHomeTheme.text,
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
  );
}

class _Hint extends StatelessWidget {
  const _Hint(this.text, {this.action});

  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          text,
          style: const TextStyle(
            color: CustomerHomeTheme.mutedText,
            fontSize: 13,
          ),
        ),
      ),
      ?action,
    ],
  );
}

/// White rounded card used by every block on this screen.
class _Box extends StatelessWidget {
  const _Box({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: CustomerHomeTheme.border),
        ),
        child: child,
      ),
    ),
  );
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.name, required this.subtitle, this.onTap});

  final String name, subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => _Box(
    onTap: onTap,
    child: Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: CustomerHomeTheme.mint,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            serviceIcon(name),
            color: CustomerHomeTheme.primary,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: CustomerHomeTheme.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle.trim().isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: CustomerHomeTheme.mutedText,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (onTap != null)
          const Text(
            'Change',
            style: TextStyle(
              color: CustomerHomeTheme.primary,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    ),
  );
}

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({required this.professional});

  final Professional professional;

  @override
  Widget build(BuildContext context) {
    final p = professional;
    final role = p.specialty.trim().isEmpty
        ? 'Service professional'
        : p.specialty.trim();
    return _Box(
      child: Row(
        children: [
          PersonAvatar(
            name: p.name,
            photoUrl: p.photoUrl,
            size: 44,
            verified: p.verified,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: CustomerHomeTheme.text,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  p.verified ? 'Verified $role' : role,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: CustomerHomeTheme.mutedText,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  p.rating == null
                      ? 'New provider'
                      : '${p.rating!.toStringAsFixed(1)} ★ • '
                            '${p.completedJobs} jobs',
                  style: const TextStyle(
                    color: CustomerHomeTheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.date,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final DateTime date;
  final bool selected, enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected
        ? Colors.white
        : enabled
        ? CustomerHomeTheme.text
        : AppColors.subtle;
    final weekday = Formatters.weekdayShort(date);
    return Semantics(
      selected: selected,
      button: onTap != null,
      label: Formatters.longDate(date),
      child: Material(
        color: selected ? CustomerHomeTheme.primary : Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? CustomerHomeTheme.primary
                    : CustomerHomeTheme.border,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${weekday[0]}${weekday.substring(1).toLowerCase()}',
                  style: TextStyle(
                    color: selected
                        ? Colors.white
                        : CustomerHomeTheme.mutedText,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${date.day}',
                  style: TextStyle(
                    color: fg,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    decoration: enabled ? null : TextDecoration.lineThrough,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null || selected;
    return Semantics(
      selected: selected,
      button: onTap != null,
      child: Material(
        color: selected ? CustomerHomeTheme.primary : Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 96,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? CustomerHomeTheme.primary
                    : CustomerHomeTheme.border,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected
                    ? Colors.white
                    : enabled
                    ? CustomerHomeTheme.text
                    : AppColors.subtle,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                decoration: enabled ? null : TextDecoration.lineThrough,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({
    required this.address,
    required this.loading,
    required this.onTap,
  });

  final Address? address;
  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => _Box(
    onTap: loading ? null : onTap,
    child: Row(
      children: [
        const Icon(LucideIcons.mapPin, color: CustomerHomeTheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: loading
              ? const Text(
                  'Loading your addresses…',
                  style: TextStyle(color: CustomerHomeTheme.mutedText),
                )
              : address == null
              ? const Text(
                  'Add a service address',
                  style: TextStyle(
                    color: CustomerHomeTheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      address!.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: CustomerHomeTheme.mutedText,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      address!.line,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: CustomerHomeTheme.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
        const Icon(
          LucideIcons.chevronRight,
          size: 18,
          color: CustomerHomeTheme.mutedText,
        ),
      ],
    ),
  );
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.pricing});

  final double? pricing;

  @override
  Widget build(BuildContext context) => _Box(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Estimated Total',
                style: TextStyle(
                  color: CustomerHomeTheme.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              pricing == null
                  ? 'On inspection'
                  : 'Rs. ${Formatters.lkr(pricing).substring(4)}',
              style: const TextStyle(
                color: CustomerHomeTheme.primary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          pricing == null
              ? 'Price confirmed after inspection.'
              : "Provider's starting price. Final amount is confirmed "
                    'after inspection.',
          style: const TextStyle(
            color: CustomerHomeTheme.mutedText,
            fontSize: 11.5,
          ),
        ),
      ],
    ),
  );
}

class _ChoiceSheet extends StatelessWidget {
  const _ChoiceSheet({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SheetHandle(),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: Text(title, style: AppTypography.title),
        ),
        Flexible(child: ListView(shrinkWrap: true, children: children)),
        const SizedBox(height: 8),
      ],
    ),
  );
}
