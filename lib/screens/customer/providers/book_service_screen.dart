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

  /// Shows a summary first; the booking is only sent after "Send request".
  Future<void> _review() async {
    final missing = _missing;
    if (missing != null) {
      showAppSnack(context, missing, error: true);
      return;
    }
    final ok = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheet) => _SummarySheet(
        rows: [
          ('Service', _service!),
          ('Provider', _pro.name),
          ('Date', Formatters.longDate(_date!)),
          ('Time', Formatters.time12(_slot!.start, padHour: false)),
          ('Location', _address!.line),
          ('Price', 'Quote pending'),
          ('Payment', 'Pay after the service'),
        ],
      ),
    );
    if (ok == true && mounted) await _confirm();
  }

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
      if (!mounted) return;
      // Stop the button spinner before the success dialog opens.
      setState(() => _saving = false);
      await onBookingCreated(context, id);
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
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              children: [
                _ServiceCard(
                  name: _service ?? 'No services listed',
                  subtitle: _pro.specialty,
                  onTap: _services.length > 1 ? _chooseService : null,
                ),
                const SizedBox(height: 12),
                _ProviderCard(professional: _pro),
                const SizedBox(height: 20),
                _LabelRow(
                  'Select Date',
                  trailing: Text(
                    Formatters.monthYear(_date!),
                    style: const TextStyle(
                      color: CustomerHomeTheme.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 104,
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
                        isToday: index == 0,
                        selected: day == _date,
                        enabled: works,
                        onTap: works && !_saving
                            ? () => _selectDate(day)
                            : null,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 6),
                const _Hint('Crossed-out days: the provider is not working.'),
                const SizedBox(height: 18),
                FutureBuilder<List<TimeSlot>>(
                  future: _slots,
                  builder: (context, snapshot) {
                    final slots = snapshot.data;
                    final open = slots?.where((s) => s.selectable).length;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _LabelRow(
                          'Available Time Slots',
                          trailing: open == null
                              ? null
                              : Text(
                                  '$open slot${open == 1 ? '' : 's'} open',
                                  style: const TextStyle(
                                    color: CustomerHomeTheme.mutedText,
                                    fontSize: 14,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 10),
                        if (snapshot.hasError)
                          _Hint(
                            'Could not load times.',
                            action: TextButton(
                              onPressed: () => _selectDate(_date!),
                              child: const Text('Retry'),
                            ),
                          )
                        else if (slots == null)
                          const Padding(
                            padding: EdgeInsets.all(12),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (open == 0)
                          const _Hint(
                            'No free times on this day. Try another date.',
                          )
                        else
                          for (final slot in slots)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _SlotRow(
                                slot: slot,
                                proName: _pro.name.split(' ').first,
                                selected: slot.start == _slot?.start,
                                onTap: slot.selectable && !_saving
                                    ? () => setState(() => _slot = slot)
                                    : null,
                              ),
                            ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 8),
                const _Label('Service Location'),
                const SizedBox(height: 10),
                _LocationCard(
                  address: _address,
                  loading: !_addressesLoaded,
                  onTap: _saving ? null : _chooseAddress,
                ),
                const SizedBox(height: 16),
                _TotalCard(pricing: _pro.pricing),
                const SizedBox(height: 12),
                const _PaymentCard(),
                const SizedBox(height: 12),
                const InfoBanner(
                  title: 'Free Rescheduling Window',
                  message:
                      'You can change or cancel for free up to 2 hours '
                      'before your slot starts.',
                ),
                const SizedBox(height: 12),
                const _PromiseCard(),
              ],
            ),
          ),
          _ConfirmBar(
            saving: _saving,
            onPressed: _review,
            label: _slot == null
                ? 'Confirm Booking'
                : 'Confirm Booking — '
                      '${Formatters.compactDate(_slot!.date)}, '
                      '${Formatters.time12(_slot!.start, padHour: false)}',
          ),
        ],
      ),
    ),
  );
}

/// Always-visible bottom bar so the main action never scrolls away.
class _ConfirmBar extends StatelessWidget {
  const _ConfirmBar({
    required this.saving,
    required this.onPressed,
    required this.label,
  });

  final bool saving;
  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(top: BorderSide(color: CustomerHomeTheme.border)),
    ),
    child: SizedBox(
      height: 56,
      width: double.infinity,
      child: FilledButton(
        onPressed: saving ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: CustomerHomeTheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: saving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.checkCheck, size: 20),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    ),
  );
}

/// "Check your booking" sheet: pops `true` when the customer sends it.
class _SummarySheet extends StatelessWidget {
  const _SummarySheet({required this.rows});

  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SheetHandle(),
          const SizedBox(height: 4),
          const Text('Check your booking', style: AppTypography.title),
          const SizedBox(height: 12),
          for (final (label, value) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 112,
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
            ),
          const SizedBox(height: 14),
          SizedBox(
            height: 54,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: CustomerHomeTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Send booking request',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Go back and edit'),
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
      fontSize: 16,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _LabelRow extends StatelessWidget {
  const _LabelRow(this.text, {this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: _Label(text)),
      ?trailing,
    ],
  );
}

class _PromiseCard extends StatelessWidget {
  const _PromiseCard();

  @override
  Widget build(BuildContext context) => const _Box(
    child: Row(
      children: [
        Icon(
          LucideIcons.shieldCheck,
          size: 20,
          color: CustomerHomeTheme.primary,
        ),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'HomeCare Service Promise',
            style: TextStyle(
              color: CustomerHomeTheme.text,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          '100% Guaranteed',
          style: TextStyle(color: CustomerHomeTheme.mutedText, fontSize: 14),
        ),
      ],
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
            fontSize: 14,
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
                    fontSize: 14,
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
              fontSize: 14,
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
                    fontSize: 15.5,
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
                    fontSize: 14,
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
                    fontSize: 14,
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
    required this.isToday,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final DateTime date;
  final bool isToday, selected, enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected
        ? Colors.white
        : enabled
        ? CustomerHomeTheme.text
        : AppColors.subtle;
    return Semantics(
      selected: selected,
      enabled: onTap != null,
      label: Formatters.longDate(date),
      child: Material(
        color: selected ? CustomerHomeTheme.primary : Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: selected ? 2 : 0,
        shadowColor: CustomerHomeTheme.shadow,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 66,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected
                    ? CustomerHomeTheme.primary
                    : CustomerHomeTheme.border,
              ),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    Formatters.weekdayShort(date),
                    style: TextStyle(
                      color: selected
                          ? Colors.white
                          : CustomerHomeTheme.mutedText,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      color: fg,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      decoration: enabled ? null : TextDecoration.lineThrough,
                    ),
                  ),
                  const SizedBox(height: 2),
                  isToday
                      ? Text(
                          'Today',
                          style: TextStyle(
                            color: selected
                                ? Colors.white
                                : CustomerHomeTheme.mutedText,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: enabled
                                ? (selected
                                      ? Colors.white
                                      : CustomerHomeTheme.primary)
                                : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One time slot as a row: time range, a short note and a status pill.
class _SlotRow extends StatelessWidget {
  const _SlotRow({
    required this.slot,
    required this.proName,
    required this.selected,
    required this.onTap,
  });

  final TimeSlot slot;
  final String proName;
  final bool selected;
  final VoidCallback? onTap;

  int get _hour => int.tryParse(slot.start.split(':').first) ?? 12;

  IconData get _icon {
    if (_hour < 10) return LucideIcons.sunrise;
    if (_hour < 15) return LucideIcons.sun;
    if (_hour < 17) return LucideIcons.sunset;
    return LucideIcons.moon;
  }

  String get _subtitle {
    if (selected) return '$proName is available';
    return switch (slot.state) {
      SlotState.current => 'Your current booking',
      SlotState.booked => 'Fully reserved',
      SlotState.unavailable => 'Not available',
      SlotState.available =>
        _hour < 10
            ? 'Morning • Earliest slot'
            : _hour < 12
            ? 'Late morning'
            : _hour < 17
            ? 'Afternoon'
            : 'Evening',
    };
  }

  @override
  Widget build(BuildContext context) {
    final faded = !slot.selectable && !selected;
    final struck =
        slot.state == SlotState.booked || slot.state == SlotState.unavailable;
    return Semantics(
      button: onTap != null,
      selected: selected,
      label: '${Formatters.timeRange(slot.start, slot.end)}, $_subtitle',
      child: Opacity(
        opacity: faded ? 0.6 : 1,
        child: Material(
          color: selected ? AppColors.primarySoft : Colors.white,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              constraints: const BoxConstraints(minHeight: 64),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected
                      ? CustomerHomeTheme.primary
                      : CustomerHomeTheme.border,
                  width: selected ? 1.4 : 1,
                ),
              ),
              child: Row(
                children: [
                  IconTile(
                    icon: _icon,
                    circle: true,
                    size: 40,
                    color: selected ? Colors.white : CustomerHomeTheme.primary,
                    background: selected
                        ? CustomerHomeTheme.primaryDark
                        : CustomerHomeTheme.mint,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Formatters.timeRange(slot.start, slot.end),
                          style: TextStyle(
                            color: selected
                                ? CustomerHomeTheme.primaryDark
                                : faded
                                ? AppColors.subtle
                                : CustomerHomeTheme.text,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            decoration: struck
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _subtitle,
                          style: const TextStyle(
                            color: CustomerHomeTheme.mutedText,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (selected)
                    const IconTile(
                      icon: LucideIcons.check,
                      circle: true,
                      size: 32,
                      color: Colors.white,
                      background: CustomerHomeTheme.primaryDark,
                    )
                  else
                    StatusPill(
                      label: switch (slot.state) {
                        SlotState.available => 'Select',
                        SlotState.booked => 'Booked',
                        SlotState.current => 'Current',
                        SlotState.unavailable => 'Closed',
                      },
                      color: faded ? AppColors.subtle : CustomerHomeTheme.text,
                      background: CustomerHomeTheme.mint,
                    ),
                ],
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
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      address!.line,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: CustomerHomeTheme.text,
                        fontSize: 15,
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
                'Price',
                style: TextStyle(
                  color: CustomerHomeTheme.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Text(
              'Quote pending',
              key: ValueKey('price-quote-pending'),
              style: TextStyle(
                color: CustomerHomeTheme.primary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Your provider will send a price after reviewing your request. '
          'You choose whether to accept it.',
          style: TextStyle(color: CustomerHomeTheme.mutedText, fontSize: 14),
        ),
        if (pricing != null) ...[
          const SizedBox(height: 4),
          Text(
            'Provider estimate: from ${Formatters.lkr(pricing)} '
            '(final price quoted per job).',
            style: const TextStyle(
              color: CustomerHomeTheme.mutedText,
              fontSize: 14,
            ),
          ),
        ],
      ],
    ),
  );
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard();

  @override
  Widget build(BuildContext context) => const _Box(
    child: Row(
      children: [
        Icon(LucideIcons.banknote, color: CustomerHomeTheme.primary),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Payment',
                style: TextStyle(
                  color: CustomerHomeTheme.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Pay the provider after the service is done. '
                'No payment is taken now.',
                style: TextStyle(
                  color: CustomerHomeTheme.mutedText,
                  fontSize: 14,
                ),
              ),
            ],
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
