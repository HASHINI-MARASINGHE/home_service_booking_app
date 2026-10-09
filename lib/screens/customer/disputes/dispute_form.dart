import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/booking.dart';
import '../../../models/dispute.dart';
import '../../../services/app_error.dart';
import '../../../services/dispute_photo_picker.dart';
import '../../../services/dispute_service.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/common/app_widgets.dart';
import 'dispute_widgets.dart';

/// The "Dispute Resolution" form. Used to file a new dispute and, with
/// [existing], to edit a pending one.
class DisputeForm extends StatefulWidget {
  const DisputeForm({
    super.key,
    required this.booking,
    required this.service,
    required this.onSaved,
    this.existing,
    this.existingPhotos = const [],
  });

  final Booking booking;
  final DisputeService service;
  final Dispute? existing;
  final List<DisputePhoto> existingPhotos;

  /// Called after the dispute was saved (created or edited).
  final VoidCallback onSaved;

  /// The Safety Desk phone number. Left empty until the real number is known;
  /// the link then says so instead of dialing something made up.
  static const safetyDeskPhone = '';

  @override
  State<DisputeForm> createState() => _DisputeFormState();
}

class _DisputeFormState extends State<DisputeForm> {
  final _description = TextEditingController();
  String? _reason;
  String? _tag;
  late final List<DisputePhoto> _photos;
  bool _busy = false, _addingPhoto = false;
  late DateTime _now;
  Timer? _ticker;

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _photos = [...widget.existingPhotos];
    if (existing != null) {
      _reason = DisputeReasons.all.contains(existing.reason)
          ? existing.reason
          : null;
      _tag = existing.tag;
      _description.text = existing.description;
    }
    _now = widget.service.now();
    // Keep the warranty countdown fresh while the screen is open.
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _now = widget.service.now());
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _description.dispose();
    super.dispose();
  }

  // 3-day warranty check - disputes can only be filed within 72 hours of completion.
  bool get _warrantyOpen => DisputeWarranty.isOpen(widget.booking, _now);

  /// Reason chosen and a long enough description, inside the warranty.
  // Submit gatekeeper - ensures reason is chosen, description >= 10 chars, warranty is active, and not busy.
  bool get _canSubmit =>
      _reason != null &&
      _description.text.trim().length >= DisputeService.minDescription &&
      (_editing || _warrantyOpen) &&
      !_busy;

  Future<void> _addPhoto() async {
    if (_photos.length >= DisputeService.maxPhotos) {
      showAppSnack(
        context,
        'You can attach up to ${DisputeService.maxPhotos} photos.',
        error: true,
      );
      return;
    }
    setState(() => _addingPhoto = true);
    try {
      final photo = await DisputePhotoPicker.instance.pick();
      if (photo != null && mounted) setState(() => _photos.add(photo));
    } catch (error) {
      if (mounted) showAppSnack(context, AppError.message(error), error: true);
    } finally {
      if (mounted) setState(() => _addingPhoto = false);
    }
  }

  // Handles create vs update dispatch for the customer dispute.
  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      if (_editing) {
        await widget.service.update(
          dispute: widget.existing!,
          reason: _reason!,
          tag: _tag,
          description: _description.text,
          photos: _photos,
        );
      } else {
        await widget.service.submit(
          booking: widget.booking,
          reason: _reason!,
          tag: _tag,
          description: _description.text,
          photos: _photos,
        );
      }
      if (!mounted) return;
      showAppSnack(
        context,
        _editing ? 'Your dispute was updated.' : 'Dispute submitted.',
      );
      widget.onSaved();
    } catch (error) {
      if (mounted) {
        setState(() => _busy = false);
        showAppSnack(context, AppError.message(error), error: true);
      }
    }
  }

  Future<void> _callSafetyDesk() async {
    if (DisputeForm.safetyDeskPhone.isEmpty) {
      showAppSnack(
        context,
        'The Safety Desk number is not available yet. We will contact you '
        'after you submit your claim.',
      );
      return;
    }
    await launchUrl(Uri(scheme: 'tel', path: DisputeForm.safetyDeskPhone));
  }

  @override
  Widget build(BuildContext context) {
    final length = _description.text.length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.xs,
        AppSpacing.screen,
        AppSpacing.xl,
      ),
      children: [
        DisputeJobCard(booking: widget.booking),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: Text(
                'Reason for Dispute *',
                style: AppTypography.title.copyWith(
                  color: AppColors.primaryDark,
                ),
              ),
            ),
            Text(
              'Mandatory',
              style: AppTypography.caption.copyWith(
                color: AppColors.warning,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.warningSoft,
            borderRadius: AppRadius.button,
            border: Border.all(color: AppColors.warningBorder),
          ),
          child: Row(
            children: [
              const Icon(
                LucideIcons.triangleAlert,
                size: 20,
                color: AppColors.warning,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    key: const ValueKey('dispute-reason'),
                    value: _reason,
                    isExpanded: true,
                    hint: Text(
                      'Select a reason',
                      style: AppTypography.bodyStrong,
                    ),
                    style: AppTypography.bodyStrong,
                    dropdownColor: AppColors.surface,
                    onChanged: _busy
                        ? null
                        : (value) => setState(() => _reason = value),
                    items: [
                      for (final reason in DisputeReasons.all)
                        DropdownMenuItem(
                          value: reason,
                          child: Text(reason, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final tag in DisputeReasons.tags)
              DisputeTagChip(
                label: tag,
                selected: _tag == tag,
                onTap: () => setState(() => _tag = _tag == tag ? null : tag),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: Text(
                'Describe the Issue in Detail *',
                style: AppTypography.title.copyWith(
                  color: AppColors.primaryDark,
                ),
              ),
            ),
            Text(
              '$length / ${DisputeService.maxDescription}',
              key: const ValueKey('dispute-counter'),
              style: AppTypography.caption,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          key: const ValueKey('dispute-description'),
          controller: _description,
          minLines: 4,
          maxLines: 6,
          maxLength: DisputeService.maxDescription,
          enabled: !_busy,
          buildCounter: (
            _, {
            required currentLength,
            required isFocused,
            maxLength,
          }) => null,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText:
                'What went wrong? (at least ${DisputeService.minDescription} '
                'characters)',
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: AppColors.successSoft,
            borderRadius: AppRadius.button,
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.info, size: 16, color: AppColors.success),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'Clear descriptions resolve 40% faster',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.success,
                  ),
                ),
              ),
              TextButton(
                key: const ValueKey('clear-description'),
                onPressed: _busy || _description.text.isEmpty
                    ? null
                    : () => setState(_description.clear),
                child: const Text('Clear'),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: Text(
                'Supporting Photos or Receipts',
                style: AppTypography.title.copyWith(
                  color: AppColors.primaryDark,
                ),
              ),
            ),
            Text(
              'Max ${DisputeService.maxPhotos} files',
              style: AppTypography.caption,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        DisputePhotoGrid(
          photos: _photos,
          adding: _addingPhoto,
          onRemove: _busy ? null : (i) => setState(() => _photos.removeAt(i)),
          onAdd: _busy || _photos.length >= DisputeService.maxPhotos
              ? null
              : _addPhoto,
        ),
        const SizedBox(height: AppSpacing.md),
        const _GuaranteeBox(),
        const SizedBox(height: AppSpacing.md),
        if (!_editing)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.clock,
                  size: 15,
                  color: _warrantyOpen ? AppColors.primary : AppColors.danger,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    DisputeWarranty.label(widget.booking, _now),
                    key: const ValueKey('warranty-label'),
                    textAlign: TextAlign.center,
                    style: AppTypography.caption.copyWith(
                      color: _warrantyOpen
                          ? AppColors.primary
                          : AppColors.danger,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        PrimaryButton(
          key: const ValueKey('submit-dispute'),
          label: !_editing && !_warrantyOpen
              ? 'Warranty period ended'
              : _editing
              ? 'Save Changes'
              : 'Submit Dispute Claim',
          icon: !_editing && !_warrantyOpen ? null : LucideIcons.arrowRight,
          busy: _busy,
          onPressed: _canSubmit ? _submit : null,
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('Need urgent mediation? ', style: AppTypography.caption),
            InkWell(
              key: const ValueKey('call-safety-desk'),
              onTap: _callSafetyDesk,
              child: Text(
                'Call Safety Desk',
                style: AppTypography.caption.copyWith(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
        if (widget.booking.completedAt != null && !_editing)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              'Job completed ${Formatters.shortDate(widget.booking.completedAt!.toLocal())}',
              textAlign: TextAlign.center,
              style: AppTypography.caption,
            ),
          ),
      ],
    );
  }
}

class _GuaranteeBox extends StatelessWidget {
  const _GuaranteeBox();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.sm),
    decoration: BoxDecoration(
      color: AppColors.successSoft,
      borderRadius: AppRadius.button,
      border: Border.all(color: AppColors.primarySoft),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(LucideIcons.shieldCheck, color: AppColors.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Protected by HomeCare Guarantee',
                style: AppTypography.subtitle.copyWith(
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Our safety desk reviews every claim made within the 3-day '
                'warranty. If your claim is approved, the refund goes back to '
                'your original payment method.',
                style: AppTypography.caption.copyWith(color: AppColors.body),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
