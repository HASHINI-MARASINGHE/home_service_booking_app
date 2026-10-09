import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../models/address.dart';
import '../../../services/app_error.dart';
import '../../../services/location_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/address/address_widgets.dart';
import '../../../widgets/common/app_widgets.dart';
import '../customer_scope.dart';

/// Add New Address / Edit Address. Pops with the saved address ID.
class AddressFormScreen extends StatefulWidget {
  const AddressFormScreen({super.key, this.addressId, this.autoLocate = false});

  /// Null for a new address.
  final String? addressId;

  /// Starts a GPS lookup as soon as the form opens.
  final bool autoLocate;

  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _label = TextEditingController();
  final _house = TextEditingController();
  final _street = TextEditingController();
  final _city = TextEditingController();
  final _landmark = TextEditingController();
  final _notes = TextEditingController();
  AddressType _type = AddressType.home;
  String _province = '';
  double? _lat, _lng;
  bool _isDefault = false;
  bool _wasDefault = false;
  bool _loading = false;
  bool _locating = false;
  bool _saving = false;
  Object? _loadError;

  bool get _editing => widget.addressId != null;

  @override
  void initState() {
    super.initState();
    if (_editing) {
      _loading = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    } else if (widget.autoLocate) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _locate());
    }
  }

  @override
  void dispose() {
    for (final c in [_label, _house, _street, _city, _landmark, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final address = await CustomerScope.of(context).addresses
          .getAddress(widget.addressId!);
      if (!mounted) return;
      if (address == null) {
        setState(() {
          _loading = false;
          _loadError = StateError('This address no longer exists.');
        });
        return;
      }
      setState(() {
        _type = address.type;
        _label.text = address.label == address.type.label ? '' : address.label;
        _house.text = address.houseNumber;
        _street.text = address.street;
        _city.text = address.cityWithPostalCode;
        _landmark.text = address.landmark;
        _notes.text = address.accessNotes;
        _province = address.province;
        _lat = address.latitude;
        _lng = address.longitude;
        _isDefault = address.isDefault;
        _wasDefault = address.isDefault;
        _loading = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = error;
        });
      }
    }
  }

  Future<void> _locate() async {
    final location = CustomerScope.of(context).location;
    setState(() => _locating = true);
    try {
      final found = await location.currentAddress();
      if (!mounted) return;
      setState(() {
        _lat = found.latitude;
        _lng = found.longitude;
        if (found.houseNumber.isNotEmpty) _house.text = found.houseNumber;
        if (found.street.isNotEmpty) _street.text = found.street;
        if (found.city.isNotEmpty) _city.text = found.cityWithPostalCode;
        if (found.province.isNotEmpty) _province = found.province;
      });
      showAppSnack(
        context,
        found.street.isEmpty
            ? 'Location pinned. Please type your street details.'
            : 'Location found. Check the details below.',
      );
    } on LocationException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(error.message),
            action: error.canOpenSettings
                ? SnackBarAction(
                    label: 'Settings',
                    onPressed: location.openSettings,
                  )
                : null,
          ),
        );
    } catch (_) {
      if (mounted) {
        showAppSnack(
          context,
          'We could not read your location. Please type your address.',
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final input = AddressInput(
      type: _type,
      label: _label.text,
      houseNumber: _house.text,
      street: _street.text,
      cityAndPostalCode: _city.text,
      province: _province,
      landmark: _landmark.text,
      accessNotes: _notes.text,
      latitude: _lat,
      longitude: _lng,
      isDefault: _isDefault,
    );
    setState(() => _saving = true);
    try {
      final service = CustomerScope.of(context).addresses;
      final id = _editing ? widget.addressId! : await service.create(input);
      if (_editing) await service.update(id, input);
      if (mounted) Navigator.of(context).pop(id);
    } catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        showAppSnack(context, AppError.message(error), error: true);
      }
    }
  }

  String? _required(String? value, String what) =>
      value == null || value.trim().isEmpty ? 'Enter the $what.' : null;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      bottom: false,
      child: Column(
        children: [
          ScreenHeader(title: _editing ? 'Edit Address' : 'Add New Address'),
          Expanded(
            child: _loading
                ? const LoadingState()
                : _loadError != null
                ? ErrorState(error: _loadError!, onRetry: _load)
                : _form(),
          ),
        ],
      ),
    ),
  );

  // Not a lazy ListView: every field must stay mounted so Form.validate()
  // checks fields that are scrolled off-screen.
  Widget _form() => Form(
    key: _formKey,
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.xs,
        AppSpacing.screen,
        AppSpacing.xxl,
      ),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MapPreview(
            locating: _locating,
            pinned: _lat != null && _lng != null,
            onLocate: _locating || _saving ? null : _locate,
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionLabel('Address type'),
          const SizedBox(height: AppSpacing.xs),
          ChoiceChips<AddressType>(
            values: AddressType.values,
            selected: _type,
            labelOf: (t) => t.label,
            iconOf: (t) => addressTypeStyle(t).$1,
            onSelected: (t) => setState(() => _type = t),
          ),
          const SizedBox(height: AppSpacing.lg),
          _Field(
            label: 'Address Label',
            optional: true,
            controller: _label,
            icon: LucideIcons.tag,
            hint: _type == AddressType.parents ? "Parents' House" : _type.label,
            maxLength: 60,
          ),
          _Field(
            label: 'House / Apt / Building No.',
            controller: _house,
            icon: LucideIcons.building2,
            hint: 'No. 42, Apt 4B',
            validator: (v) => _required(v, 'house or building number'),
            maxLength: 80,
          ),
          _Field(
            label: 'Street Name',
            controller: _street,
            icon: LucideIcons.milestone,
            hint: 'Galle Road',
            validator: (v) => _required(v, 'street name'),
            maxLength: 120,
          ),
          _Field(
            label: 'City / Postal Code',
            controller: _city,
            icon: LucideIcons.map,
            hint: 'Colombo 03 (00300)',
            validator: (v) => _required(v, 'city'),
            maxLength: 90,
          ),
          _Field(
            label: 'Landmark',
            optional: true,
            controller: _landmark,
            icon: LucideIcons.navigation,
            hint: 'Opposite Majestic City',
            maxLength: 120,
          ),
          _Field(
            label: 'Access & Entry Notes',
            controller: _notes,
            hint: 'Ring intercom 4B. Park in visitor bay C.',
            maxLines: 3,
            maxLength: Address.maxNotes,
            optional: true,
          ),
          _DefaultToggle(
            value: _isDefault,
            locked: _wasDefault,
            onChanged: (v) => setState(() => _isDefault = v),
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: _editing ? 'Save Changes' : 'Save Address',
            icon: LucideIcons.checkCircle,
            busy: _saving,
            onPressed: _save,
          ),
        ],
      ),
    ),
  );
}

class _MapPreview extends StatelessWidget {
  const _MapPreview({
    required this.locating,
    required this.pinned,
    required this.onLocate,
  });

  final bool locating, pinned;
  final VoidCallback? onLocate;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: AppRadius.card,
    child: Container(
      height: 180,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.surfaceLavender,
            AppColors.surfaceLavender,
            AppColors.borderSubtle,
          ],
          stops: [0, 0.45, 1],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 62,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: pinned ? AppColors.primary : AppColors.muted,
                shape: BoxShape.circle,
                boxShadow: AppShadows.card,
              ),
              child: const Icon(
                LucideIcons.mapPin,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          Positioned(
            bottom: 12,
            child: Material(
              color: AppColors.surface,
              shape: const StadiumBorder(),
              elevation: 1,
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: onLocate,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      locating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            )
                          : const Icon(
                              LucideIcons.locateFixed,
                              size: 17,
                              color: AppColors.primary,
                            ),
                      const SizedBox(width: 8),
                      Text(
                        locating
                            ? 'Finding your location…'
                            : pinned
                            ? 'Location pinned • Update GPS'
                            : 'Use Current Location (GPS)',
                        style: AppTypography.label.copyWith(
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.icon,
    this.hint,
    this.validator,
    this.optional = false,
    this.maxLines = 1,
    this.maxLength,
  });

  final String label;
  final TextEditingController controller;
  final IconData? icon;
  final String? hint;
  final FormFieldValidator<String>? validator;
  final bool optional;
  final int maxLines;
  final int? maxLength;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: AppTypography.label)),
            if (optional)
              Text(
                'Optional',
                style: AppTypography.caption.copyWith(color: AppColors.subtle),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          controller: controller,
          validator: validator,
          maxLines: maxLines,
          minLines: 1,
          maxLength: maxLength,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: maxLines > 1
              ? TextInputAction.newline
              : TextInputAction.next,
          style: AppTypography.bodyStrong.copyWith(fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            counterText: '',
            prefixIcon: icon == null
                ? null
                : Icon(icon, size: 19, color: AppColors.muted),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.field,
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    ),
  );
}

class _DefaultToggle extends StatelessWidget {
  const _DefaultToggle({
    required this.value,
    required this.locked,
    required this.onChanged,
  });

  final bool value, locked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Row(
      children: [
        const IconTile(
          icon: Icons.star_rounded,
          circle: true,
          background: AppColors.primarySoft,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Set as default address', style: AppTypography.subtitle),
              Text(
                locked
                    ? 'This is your default. Choose another address as '
                          'default to change it.'
                    : 'Use automatically for service requests',
                style: AppTypography.caption,
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          activeTrackColor: AppColors.primaryDark,
          onChanged: locked ? null : onChanged,
        ),
      ],
    ),
  );
}
