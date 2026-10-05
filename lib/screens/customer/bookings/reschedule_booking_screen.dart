import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../models/booking.dart';
import '../../../models/booking_policy.dart';
import '../../../models/professional.dart';
import '../../../services/app_error.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/common/app_widgets.dart';
import '../customer_scope.dart';

class RescheduleBookingScreen extends StatefulWidget {
  const RescheduleBookingScreen({
    super.key,
    required this.booking,
    required this.professional,
  });

  final Booking booking;
  final Professional professional;

  @override
  State<RescheduleBookingScreen> createState() =>
      _RescheduleBookingScreenState();
}

class _RescheduleBookingScreenState extends State<RescheduleBookingScreen> {
  late List<DateTime> _days;
  late DateTime _date;
  Future<List<TimeSlot>>? _slots;
  TimeSlot? _selected;
  bool _saving = false;

  Booking get _b => widget.booking;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_slots != null) return;
    final now = CustomerScope.of(context).bookings.now();
    _days = BookingPolicy.calendarDays(now);
    final current = Formatters.parseIsoDate(_b.slotDate);
    _date = _days.firstWhere(
      (d) => current != null && d == current && _works(d),
      orElse: () => _days.firstWhere(_works, orElse: () => _days.first),
    );
    _slots = _load();
  }

  bool _works(DateTime d) =>
      widget.professional.workingDays.contains(d.weekday);

  Future<List<TimeSlot>> _load() => CustomerScope.of(context).bookings
      .availableSlots(
        booking: _b,
        professional: widget.professional,
        date: _date,
      );

  void _pickDate(DateTime date) => setState(() {
    _date = date;
    _selected = null;
    _slots = _load();
  });

  Future<void> _confirm() async {
    final slot = _selected;
    if (slot == null) return;
    setState(() => _saving = true);
    try {
      await CustomerScope.of(context).bookings.reschedule(_b, slot);
      if (!mounted) return;
      showAppSnack(
        context,
        'Booking moved to ${Formatters.compactDate(slot.date)}, '
        '${Formatters.time12(slot.start, padHour: false)}.',
      );
      Navigator.of(context).pop(true);
    } on SlotTakenException catch (error) {
      if (!mounted) return;
      showAppSnack(context, AppError.message(error), error: true);
      setState(() {
        _saving = false;
        _selected = null;
        _slots = _load();
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAppSnack(context, AppError.message(error), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = Formatters.parseIsoDate(_b.slotDate);
    final pro = widget.professional;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const ScreenHeader(title: 'Reschedule Booking'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screen,
                  AppSpacing.xs,
                  AppSpacing.screen,
                  AppSpacing.xxl,
                ),
                children: [
                  AppCard(
                    child: Row(
                      children: [
                        PersonAvatar(
                          name: pro.name,
                          photoUrl: pro.photoUrl,
                          size: 56,
                          square: true,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      _b.serviceName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.subtitle,
                                    ),
                                  ),
                                  if (pro.verified) ...[
                                    const SizedBox(width: 4),
                                    const Icon(
                                      LucideIcons.badgeCheck,
                                      size: 16,
                                      color: AppColors.primary,
                                    ),
                                  ],
                                ],
                              ),
                              Text(
                                'Professional: ${pro.name}',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.body,
                                ),
                              ),
                              Row(
                                children: [
                                  const Icon(
                                    LucideIcons.mapPin,
                                    size: 13,
                                    color: AppColors.muted,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      _b.address,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.caption,
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
                  AppCard(
                    color: AppColors.surfaceLavender,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              LucideIcons.clock,
                              size: 14,
                              color: AppColors.muted,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'CURRENT SLOT',
                                style: AppTypography.overline,
                              ),
                            ),
                            const StatusPill(
                              label: 'Active Lock',
                              icon: LucideIcons.lock,
                              color: AppColors.body,
                              background: AppColors.surfaceLavenderDeep,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            const IconTile(
                              icon: LucideIcons.calendar,
                              color: AppColors.body,
                              background: AppColors.surface,
                              size: 42,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    current == null
                                        ? 'Not scheduled'
                                        : Formatters.longDate(current),
                                    style: AppTypography.subtitle.copyWith(
                                      decoration: _selected == null
                                          ? null
                                          : TextDecoration.lineThrough,
                                    ),
                                  ),
                                  if (_b.startTime != null &&
                                      _b.endTime != null)
                                    Text(
                                      '${Formatters.timeRange(_b.startTime!, _b.endTime!)}'
                                      ' (Colombo Time)',
                                      style: AppTypography.caption,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SectionLabel(
                    'Select date',
                    trailing: Text(
                      Formatters.monthYear(_date),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    height: 84,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      itemCount: _days.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: AppSpacing.xs),
                      itemBuilder: (context, i) {
                        final day = _days[i];
                        return _DateCard(
                          date: day,
                          isToday: i == 0,
                          selected: day == _date,
                          available: _works(day),
                          onTap: _saving || !_works(day)
                              ? null
                              : () => _pickDate(day),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FutureBuilder<List<TimeSlot>>(
                    future: _slots,
                    builder: (context, snapshot) {
                      final slots = snapshot.data;
                      final open = slots?.where((s) => s.selectable).length;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionLabel(
                            'Available time slots',
                            trailing: open == null
                                ? null
                                : Text(
                                    '$open slot${open == 1 ? '' : 's'} open',
                                    style: AppTypography.caption,
                                  ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          if (snapshot.hasError)
                            ErrorState(
                              error: snapshot.error!,
                              onRetry: () => setState(() => _slots = _load()),
                            )
                          else if (slots == null)
                            const Padding(
                              padding: EdgeInsets.all(AppSpacing.xl),
                              child: LoadingState(
                                message: 'Checking availability…',
                              ),
                            )
                          else if (slots.isEmpty)
                            Text(
                              '${pro.firstName} has no slots on this day.',
                              style: AppTypography.body,
                            )
                          else
                            for (final slot in slots)
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.sm,
                                ),
                                child: _SlotTile(
                                  slot: slot,
                                  proName: pro.firstName,
                                  selected:
                                      _selected?.start == slot.start &&
                                      _selected?.date == slot.date,
                                  onTap: slot.selectable && !_saving
                                      ? () => setState(() => _selected = slot)
                                      : null,
                                ),
                              ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  InfoBanner(
                    title: 'Free Rescheduling Window',
                    message:
                        'Free modifications up to 2 hours prior. ${pro.name} '
                        'sees your new schedule instantly in the HomeCare app.',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.shieldCheck,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            'HomeCare Service Promise',
                            style: AppTypography.label,
                          ),
                        ),
                        Text('100% Guaranteed', style: AppTypography.caption),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  PrimaryButton(
                    label: _selected == null
                        ? 'Select a new time'
                        : 'Confirm New Time — '
                              '${Formatters.compactDate(_selected!.date)}, '
                              '${Formatters.time12(_selected!.start, padHour: false)}',
                    icon: LucideIcons.checkCheck,
                    busy: _saving,
                    onPressed: _selected == null ? null : _confirm,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SecondaryButton(
                    label: 'Keep Original Time',
                    foreground: AppColors.body,
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context).pop(false),
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

class _DateCard extends StatelessWidget {
  const _DateCard({
    required this.date,
    required this.isToday,
    required this.selected,
    required this.available,
    required this.onTap,
  });

  final DateTime date;
  final bool isToday, selected, available;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected
        ? Colors.white
        : available
        ? AppColors.navy
        : AppColors.subtle;
    return Semantics(
      selected: selected,
      enabled: onTap != null,
      label: Formatters.longDate(date),
      child: Material(
        color: selected ? AppColors.primary : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        elevation: selected ? 2 : 0,
        shadowColor: AppColors.shadow,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onTap,
          child: SizedBox(
            width: 64,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  Formatters.weekdayShort(date),
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.muted,
                    fontSize: 11.5,
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
                    decoration: available ? null : TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(height: 2),
                isToday
                    ? Text(
                        'TODAY',
                        style: TextStyle(
                          color: selected ? Colors.white : AppColors.muted,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: available
                              ? (selected ? Colors.white : AppColors.primary)
                              : Colors.transparent,
                          shape: BoxShape.circle,
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

class _SlotTile extends StatelessWidget {
  const _SlotTile({
    required this.slot,
    required this.proName,
    required this.selected,
    required this.onTap,
  });

  final TimeSlot slot;
  final String proName;
  final bool selected;
  final VoidCallback? onTap;

  IconData get _icon {
    final hour = int.parse(slot.start.split(':').first);
    if (hour < 10) return LucideIcons.sunrise;
    if (hour < 15) return LucideIcons.sun;
    if (hour < 17) return LucideIcons.sunset;
    return LucideIcons.moon;
  }

  String get _subtitle {
    if (selected) return '$proName confirmed available';
    final hour = int.parse(slot.start.split(':').first);
    return switch (slot.state) {
      SlotState.current => 'Your current booking',
      SlotState.booked => 'Fully reserved',
      SlotState.unavailable => 'Not available',
      SlotState.available =>
        hour < 10
            ? 'Morning calm • Earliest slot'
            : hour < 12
            ? 'Late morning'
            : hour < 17
            ? 'Afternoon shift'
            : 'Evening slot',
    };
  }

  @override
  Widget build(BuildContext context) {
    final faded = !slot.selectable && !selected;
    final titleStyle = AppTypography.subtitle.copyWith(
      color: selected
          ? AppColors.primaryDark
          : faded
          ? AppColors.subtle
          : AppColors.navy,
      decoration:
          slot.state == SlotState.booked || slot.state == SlotState.unavailable
          ? TextDecoration.lineThrough
          : null,
    );
    final Widget trailing = selected
        ? const IconTile(
            icon: LucideIcons.check,
            circle: true,
            size: 30,
            color: Colors.white,
            background: AppColors.primaryDark,
          )
        : StatusPill(
            label: switch (slot.state) {
              SlotState.available => 'Select',
              SlotState.booked => 'Booked',
              SlotState.current => 'Current',
              SlotState.unavailable => 'Closed',
            },
            color: faded ? AppColors.subtle : AppColors.body,
            background: AppColors.surfaceLavender,
          );
    return Semantics(
      button: onTap != null,
      selected: selected,
      label: '${Formatters.timeRange(slot.start, slot.end)}, $_subtitle',
      child: Opacity(
        opacity: faded ? 0.6 : 1,
        child: AppCard(
          color: selected ? AppColors.primarySoft : AppColors.surface,
          border: selected
              ? Border.all(color: AppColors.primary, width: 1.4)
              : null,
          onTap: onTap,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              IconTile(
                icon: _icon,
                circle: true,
                size: 38,
                color: selected ? Colors.white : AppColors.primary,
                background: selected
                    ? AppColors.primaryDark
                    : AppColors.surfaceLavender,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Formatters.timeRange(slot.start, slot.end),
                      style: titleStyle,
                    ),
                    Text(_subtitle, style: AppTypography.caption),
                  ],
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}
