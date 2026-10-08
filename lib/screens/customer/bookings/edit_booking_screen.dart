import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../models/address.dart';
import '../../../models/booking.dart';
import '../../../models/booking_policy.dart';
import '../../../services/app_error.dart';
import '../../../services/customer_booking_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/common/app_widgets.dart';
import '../addresses/address_form_screen.dart';
import '../customer_scope.dart';

/// `+94771234567` ↔ `077 123 4567` for the Sri Lanka phone field.
abstract final class SriLankaPhone {
  static String toLocal(String stored) {
    final digits = stored.replaceAll(RegExp(r'[^\d]'), '');
    final national = digits.startsWith('94') && digits.length == 11
        ? digits.substring(2)
        : digits.startsWith('0')
        ? digits.substring(1)
        : digits;
    if (national.length != 9) return stored;
    return '0${national.substring(0, 2)} ${national.substring(2, 5)} '
        '${national.substring(5)}';
  }

  static String? toE164(String local) {
    var digits = local.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.startsWith('94') && digits.length == 11) {
      digits = digits.substring(2);
    }
    if (digits.startsWith('0')) digits = digits.substring(1);
    return RegExp(r'^\d{9}$').hasMatch(digits) ? '+94$digits' : null;
  }
}

class _ChosenAddress {
  const _ChosenAddress({
    required this.id,
    required this.label,
    required this.line,
    required this.area,
    this.isDefault = false,
  });

  factory _ChosenAddress.from(Address a) => _ChosenAddress(
    id: a.id,
    label: a.label,
    line: a.line,
    area: a.province,
    isDefault: a.isDefault,
  );

  final String? id, label, area;
  final String line;
  final bool isDefault;
}

class EditBookingScreen extends StatefulWidget {
  const EditBookingScreen({super.key, required this.booking});
  final Booking booking;

  @override
  State<EditBookingScreen> createState() => _EditBookingScreenState();
}

class _EditBookingScreenState extends State<EditBookingScreen> {
  late _ChosenAddress _address = _ChosenAddress(
    id: widget.booking.addressId,
    label: widget.booking.addressLabel,
    line: widget.booking.address,
    area: widget.booking.addressArea,
  );
  late final _access = TextEditingController(text: widget.booking.accessNotes);
  late final _phone = TextEditingController(
    text: SriLankaPhone.toLocal(widget.booking.contactPhone),
  );
  late final _notes = TextEditingController(text: widget.booking.jobNotes);
  late final List<String> _kept = [...widget.booking.photoUrls];
  final List<Uint8List> _added = [];
  bool _saving = false;
  bool _dirty = false;

  int get _photoCount => _kept.length + _added.length;

  @override
  void initState() {
    super.initState();
    for (final c in [_access, _phone, _notes]) {
      c.addListener(_markDirty);
    }
  }

  // Rebuilds on every keystroke so the phone check icon stays current.
  void _markDirty() => setState(() => _dirty = true);

  @override
  void dispose() {
    _access.dispose();
    _phone.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _changeAddress() async {
    final scope = CustomerScope.of(context);
    final picked = await showModalBottomSheet<_ChosenAddress>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _AddressPicker(
        load: scope.addresses.getAddresses,
        selectedId: _address.id,
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        _address = picked;
        _dirty = true;
      });
    }
  }

  Future<void> _addAddress() async {
    final scope = CustomerScope.of(context);
    final id = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const AddressFormScreen()),
    );
    if (id == null || !mounted) return;
    try {
      final address = await scope.addresses.getAddress(id);
      if (address != null && mounted) {
        setState(() {
          _address = _ChosenAddress.from(address);
          _dirty = true;
        });
        showAppSnack(context, 'New address selected for this booking.');
      }
    } catch (error) {
      if (mounted) showAppSnack(context, AppError.message(error), error: true);
    }
  }

  Future<void> _addPhoto() async {
    if (_photoCount >= BookingPolicy.maxPhotos) return;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      useRootNavigator: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.md),
            const SheetHandle(),
            ListTile(
              leading: const Icon(LucideIcons.camera),
              title: const Text('Take a photo'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(LucideIcons.image),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    try {
      final file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 80,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (mounted) {
        setState(() {
          _added.add(bytes);
          _dirty = true;
        });
      }
    } catch (_) {
      if (mounted) {
        showAppSnack(
          context,
          'Could not open the camera or gallery. Check app permissions.',
          error: true,
        );
      }
    }
  }

  Future<void> _save() async {
    final phone = SriLankaPhone.toE164(_phone.text);
    if (phone == null) {
      showAppSnack(
        context,
        'Enter a valid Sri Lankan phone number, e.g. 077 123 4567.',
        error: true,
      );
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      await CustomerScope.of(context).bookings.updateDetails(
        widget.booking,
        BookingEdit(
          addressId: _address.id,
          address: _address.line,
          addressLabel: _address.label,
          addressArea: _address.area,
          accessNotes: _access.text,
          contactPhone: phone,
          jobNotes: _notes.text,
          keptPhotoUrls: _kept,
          newPhotos: _added,
        ),
      );
      if (!mounted) return;
      showAppSnack(context, 'Booking details updated.');
      Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        showAppSnack(context, AppError.message(error), error: true);
      }
    }
  }

  Future<bool> _confirmDiscard() async {
    if (!_dirty) return true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('Your edits to this booking will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  Future<void> _leave() async {
    if (await _confirmDiscard() && mounted) {
      _dirty = false;
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final validPhone = SriLankaPhone.toE164(_phone.text) != null;
    return PopScope(
      canPop: !_dirty && !_saving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_saving) _leave();
      },
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              ScreenHeader(title: 'Edit Booking Details', onBack: _leave),
              Expanded(
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screen,
                    AppSpacing.xs,
                    AppSpacing.screen,
                    AppSpacing.xxl,
                  ),
                  children: [
                    SectionLabel(
                      'Service address',
                      trailing: _address.area == null
                          ? null
                          : Text(
                              _address.area!,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AppCard(
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const IconTile(
                                icon: LucideIcons.mapPin,
                                circle: true,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Wrap(
                                      spacing: 6,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        Text(
                                          _address.label ?? 'Service location',
                                          style: AppTypography.title,
                                        ),
                                        if (_address.isDefault)
                                          const StatusPill(label: 'Primary'),
                                      ],
                                    ),
                                    Text(
                                      _address.line,
                                      style: AppTypography.body,
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: _saving ? null : _changeAddress,
                                child: const Text('Change'),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          SecondaryButton(
                            label: 'Add New Address',
                            icon: LucideIcons.plusCircle,
                            background: AppColors.surfaceLavender,
                            onPressed: _saving ? null : _addAddress,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SectionLabel(
                      'Gate & access instructions',
                      trailing: Text('Optional', style: AppTypography.caption),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _BoxedTextArea(
                      controller: _access,
                      hint: 'Gate colour, bell, parking or pets…',
                      maxLength: BookingPolicy.maxAccessNotes,
                      footerLeading: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            LucideIcons.checkCircle,
                            size: 13,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Auto-shared with assigned pro',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.primary,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const SectionLabel('Contact phone number'),
                    const SizedBox(height: AppSpacing.xs),
                    AppCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLavender,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Text(
                              'LK +94',
                              style: AppTypography.bodyStrong,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: TextField(
                              controller: _phone,
                              keyboardType: TextInputType.phone,
                              autofillHints: const [
                                AutofillHints.telephoneNumber,
                              ],
                              style: AppTypography.subtitle.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: const InputDecoration(
                                hintText: '07X XXX XXXX',
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                              ),
                            ),
                          ),
                          Icon(
                            validPhone
                                ? LucideIcons.badgeCheck
                                : LucideIcons.alertCircle,
                            color: validPhone
                                ? AppColors.primary
                                : AppColors.subtle,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SectionLabel(
                      'Job notes & issue photos',
                      trailing: Text(
                        widget.booking.serviceName,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _notes,
                            minLines: 3,
                            maxLines: 6,
                            maxLength: BookingPolicy.maxJobNotes,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              hintText: 'Describe the issue for your pro…',
                              counterText: '',
                              fillColor: AppColors.surfaceLavender,
                              border: OutlineInputBorder(
                                borderRadius: AppRadius.field,
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: AppRadius.field,
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _PhotoGrid(
                            urls: _kept,
                            added: _added,
                            canAdd: _photoCount < BookingPolicy.maxPhotos,
                            onAdd: _saving ? null : _addPhoto,
                            onRemoveUrl: (url) => setState(() {
                              _kept.remove(url);
                              _dirty = true;
                            }),
                            onRemoveAdded: (i) => setState(() {
                              _added.removeAt(i);
                              _dirty = true;
                            }),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            children: [
                              const Icon(
                                LucideIcons.camera,
                                size: 14,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Attach up to ${BookingPolicy.maxPhotos} '
                                  'photos for faster diagnostic prep.',
                                  style: AppTypography.caption,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const InfoBanner(
                      title: 'HomeCare Guarantee',
                      message:
                          'Verified technicians with 100% background checks '
                          'and free 30-day rework cover.',
                      background: AppColors.surfaceLavender,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    PrimaryButton(
                      label: 'Save Changes',
                      icon: LucideIcons.check,
                      color: AppColors.primaryDark,
                      busy: _saving,
                      onPressed: _save,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SecondaryButton(
                      label: 'Discard Changes',
                      onPressed: _saving ? null : _leave,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BoxedTextArea extends StatefulWidget {
  const _BoxedTextArea({
    required this.controller,
    required this.hint,
    required this.maxLength,
    required this.footerLeading,
  });

  final TextEditingController controller;
  final String hint;
  final int maxLength;
  final Widget footerLeading;

  @override
  State<_BoxedTextArea> createState() => _BoxedTextAreaState();
}

class _BoxedTextAreaState extends State<_BoxedTextArea> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
    widget.controller.addListener(_onText);
  }

  void _onText() => setState(() {});

  @override
  void dispose() {
    widget.controller.removeListener(_onText);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 150),
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.md,
      AppSpacing.xs,
      AppSpacing.md,
      AppSpacing.sm,
    ),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(
        color: _focus.hasFocus ? AppColors.primaryDark : AppColors.border,
        width: _focus.hasFocus ? 1.8 : 1,
      ),
    ),
    child: Column(
      children: [
        TextField(
          controller: widget.controller,
          focusNode: _focus,
          minLines: 3,
          maxLines: 5,
          maxLength: widget.maxLength,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: widget.hint,
            counterText: '',
            filled: false,
            contentPadding: EdgeInsets.zero,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
        ),
        Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: widget.footerLeading,
              ),
            ),
            Text(
              '${widget.controller.text.length}/${widget.maxLength}',
              style: AppTypography.caption.copyWith(fontSize: 14),
            ),
          ],
        ),
      ],
    ),
  );
}

class _PhotoGrid extends StatelessWidget {
  const _PhotoGrid({
    required this.urls,
    required this.added,
    required this.canAdd,
    required this.onAdd,
    required this.onRemoveUrl,
    required this.onRemoveAdded,
  });

  final List<String> urls;
  final List<Uint8List> added;
  final bool canAdd;
  final VoidCallback? onAdd;
  final ValueChanged<String> onRemoveUrl;
  final ValueChanged<int> onRemoveAdded;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final size = (constraints.maxWidth - AppSpacing.xs * 2) / 3;
      Widget tile(Widget image, VoidCallback onRemove, String label) =>
          SizedBox(
            width: size,
            height: size,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: image,
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: Semantics(
                    button: true,
                    label: 'Remove $label',
                    child: InkWell(
                      onTap: onRemove,
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: const BoxDecoration(
                          color: Color(0xCC344255), // ink 2 at 80%
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.x,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
      final broken = Container(
        color: AppColors.surfaceLavender,
        child: const Icon(LucideIcons.imageOff, color: AppColors.muted),
      );
      return Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: [
          for (final (i, url) in urls.indexed)
            tile(
              Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => broken,
              ),
              () => onRemoveUrl(url),
              'photo ${i + 1}',
            ),
          for (final (i, bytes) in added.indexed)
            tile(
              Image.memory(bytes, fit: BoxFit.cover),
              () => onRemoveAdded(i),
              'new photo ${i + 1}',
            ),
          if (canAdd)
            // At least as tall as a photo, but it grows with large text.
            ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: size,
                maxWidth: size,
                minHeight: size,
              ),
              child: Material(
                color: AppColors.surfaceSage,
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  onTap: onAdd,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const IconTile(
                        icon: LucideIcons.imagePlus,
                        circle: true,
                        size: 36,
                        background: AppColors.surface,
                      ),
                      const SizedBox(height: 6),
                      Text('Add Photo', style: AppTypography.label),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}

class _AddressPicker extends StatefulWidget {
  const _AddressPicker({required this.load, required this.selectedId});
  final Future<List<Address>> Function() load;
  final String? selectedId;

  @override
  State<_AddressPicker> createState() => _AddressPickerState();
}

class _AddressPickerState extends State<_AddressPicker> {
  late Future<List<Address>> _future = widget.load();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.md,
      AppSpacing.lg,
      AppSpacing.lg,
    ),
    child: FutureBuilder<List<Address>>(
      future: _future,
      builder: (context, snapshot) {
        Widget body;
        if (snapshot.hasError) {
          body = ErrorState(
            error: snapshot.error!,
            onRetry: () => setState(() => _future = widget.load()),
          );
        } else if (!snapshot.hasData) {
          body = const LoadingState();
        } else if (snapshot.data!.isEmpty) {
          body = Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              'You have no saved addresses yet. Use "Add New Address".',
              textAlign: TextAlign.center,
              style: AppTypography.body,
            ),
          );
        } else {
          body = Flexible(
            child: RadioGroup<String>(
              groupValue: widget.selectedId,
              onChanged: (id) => Navigator.of(context).pop(
                _ChosenAddress.from(
                  snapshot.data!.firstWhere((a) => a.id == id),
                ),
              ),
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final a in snapshot.data!)
                    RadioListTile<String>(
                      value: a.id,
                      contentPadding: EdgeInsets.zero,
                      title: Text(a.label, style: AppTypography.subtitle),
                      subtitle: Text(a.fullAddress),
                    ),
                ],
              ),
            ),
          );
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SheetHandle(),
            Text('Choose service address', style: AppTypography.title),
            const SizedBox(height: AppSpacing.sm),
            body,
          ],
        );
      },
    ),
  );
}
