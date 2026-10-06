import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../models/provider_verification.dart';
import '../../../models/verification_draft.dart';
import '../../../services/document_picker.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/common/app_widgets.dart';

/// Step 1 of registration / verification: who the provider is.
class VerificationDetailsForm extends StatefulWidget {
  const VerificationDetailsForm({
    super.key,
    required this.draft,
    required this.formKey,
    this.onChanged,
  });

  final VerificationDraft draft;
  final GlobalKey<FormState> formKey;
  final VoidCallback? onChanged;

  @override
  State<VerificationDetailsForm> createState() =>
      _VerificationDetailsFormState();
}

class _VerificationDetailsFormState extends State<VerificationDetailsForm> {
  late final _name = TextEditingController(text: widget.draft.fullName);
  late final _phone = TextEditingController(text: widget.draft.phone);
  late final _profession = TextEditingController(
    text: widget.draft.profession,
  );
  late final _years = TextEditingController(text: widget.draft.experienceYears);
  late final _about = TextEditingController(text: widget.draft.about);

  @override
  void dispose() {
    for (final c in [_name, _phone, _profession, _years, _about]) {
      c.dispose();
    }
    super.dispose();
  }

  void _sync() {
    widget.draft
      ..fullName = _name.text
      ..phone = _phone.text
      ..profession = _profession.text
      ..experienceYears = _years.text
      ..about = _about.text;
    widget.onChanged?.call();
  }

  /// While sign-up is relaxed everything but the name is optional.
  String _optional(String label) =>
      VerificationDraft.requireEverything ? label : '$label (optional)';

  @override
  Widget build(BuildContext context) => Form(
    key: widget.formKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          key: const ValueKey('detail-name'),
          controller: _name,
          decoration: const InputDecoration(labelText: 'Full name'),
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.name],
          onChanged: (_) => _sync(),
          validator: VerificationDraft.nameError,
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          key: const ValueKey('detail-phone'),
          controller: _phone,
          decoration: InputDecoration(
            labelText: _optional('Phone number'),
            hintText: '+94 77 123 4567',
          ),
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.telephoneNumber],
          onChanged: (_) => _sync(),
          validator: VerificationDraft.phoneError,
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          key: const ValueKey('detail-profession'),
          controller: _profession,
          decoration: InputDecoration(
            labelText: _optional('What do you do?'),
            hintText: 'e.g. Plumber, AC technician, Electrician',
          ),
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          onChanged: (_) => _sync(),
          validator: VerificationDraft.professionError,
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          key: const ValueKey('detail-years'),
          controller: _years,
          decoration: InputDecoration(
            labelText: _optional('Years of experience'),
            hintText: '0 if you are just starting',
          ),
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          onChanged: (_) => _sync(),
          validator: VerificationDraft.yearsError,
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          key: const ValueKey('detail-about'),
          controller: _about,
          decoration: const InputDecoration(
            labelText: 'About you (optional)',
            hintText: 'Skills, specialities, the kind of jobs you like',
          ),
          maxLines: 3,
          maxLength: 500,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => _sync(),
        ),
      ],
    ),
  );
}

/// The "Provider Verification" screen from the design: an onboarding header,
/// a progress bar and three steps (ID, live selfie, CV and certificates).
class VerificationDocumentsStep extends StatefulWidget {
  const VerificationDocumentsStep({
    super.key,
    required this.draft,
    this.onChanged,
  });

  final VerificationDraft draft;
  final VoidCallback? onChanged;

  @override
  State<VerificationDocumentsStep> createState() =>
      _VerificationDocumentsStepState();
}

class _VerificationDocumentsStepState extends State<VerificationDocumentsStep> {
  int _open = 0;
  late final _idNumber = TextEditingController(text: widget.draft.idNumber);

  VerificationDraft get d => widget.draft;

  @override
  void dispose() {
    _idNumber.dispose();
    super.dispose();
  }

  void _changed() {
    setState(() {});
    widget.onChanged?.call();
  }

  Future<void> _pick(
    Future<PickedDocument?> Function() source,
    void Function(PickedDocument doc) assign,
  ) async {
    try {
      final doc = await source();
      if (doc == null) return;
      if (doc.size > DocumentPicker.maxBytes) {
        if (mounted) {
          showAppSnack(context, '${doc.name} is larger than 10 MB.', error: true);
        }
        return;
      }
      assign(doc);
      _changed();
    } catch (_) {
      if (mounted) {
        showAppSnack(
          context,
          'That file could not be read. Please try another one.',
          error: true,
        );
      }
    }
  }

  Future<void> _addExperience() async {
    final entry = await showDialog<ExperienceEntry>(
      context: context,
      builder: (_) => const _ExperienceDialog(),
    );
    if (entry == null) return;
    d.experiences.add(entry);
    _changed();
  }

  @override
  Widget build(BuildContext context) {
    final done = d.documentStepsDone;
    final percent = (done * 100 / 3).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.circle, size: 9, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text('ONBOARDING', style: AppTypography.overline.copyWith(
                    color: AppColors.primary,
                  )),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Provider Verification',
                style: AppTypography.headline.copyWith(color: AppColors.primaryDark),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Complete your profile verification to start accepting jobs '
                'and getting paid directly on the platform.',
                style: AppTypography.body,
              ),
            ],
          ),
        ),
        if (!VerificationDraft.requireEverything) ...[
          const SizedBox(height: AppSpacing.sm),
          Container(
            key: const ValueKey('documents-optional-note'),
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.primaryTint,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Text(
              'Documents are optional for now. Adding them helps our team '
              'verify you faster.',
              style: AppTypography.caption.copyWith(color: AppColors.primaryDark),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: Text(
                'Step ${math.min(done + 1, 3)} of 3 · $done Completed',
                key: const ValueKey('verification-progress-label'),
                style: AppTypography.caption.copyWith(color: AppColors.body),
              ),
            ),
            Text(
              '$percent%',
              style: AppTypography.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: done / 3,
            minHeight: 7,
            backgroundColor: AppColors.surfaceLavenderDeep,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _StepCard(
          key: const ValueKey('step-id'),
          number: 1,
          title: 'Upload National ID / Passport',
          subtitle: 'Clear, government-issued photo ID',
          done: d.idDone,
          open: _open == 0,
          onTap: () => setState(() => _open = _open == 0 ? -1 : 0),
          child: _idStep(),
        ),
        const SizedBox(height: AppSpacing.sm),
        _StepCard(
          key: const ValueKey('step-selfie'),
          number: 2,
          title: 'Take Live Selfie',
          subtitle: 'Liveness Detection Ready',
          done: d.selfieDone,
          open: _open == 1,
          onTap: () => setState(() => _open = _open == 1 ? -1 : 1),
          child: _selfieStep(),
        ),
        const SizedBox(height: AppSpacing.sm),
        _StepCard(
          key: const ValueKey('step-qualifications'),
          number: 3,
          title: 'CV & Certificates',
          subtitle: 'Your CV and a course or training certificate',
          done: d.qualificationsDone,
          open: _open == 2,
          onTap: () => setState(() => _open = _open == 2 ? -1 : 2),
          child: _qualificationsStep(),
        ),
      ],
    );
  }

  // ------------------------------------------------------------------ step 1
  Widget _idStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Clear government-issued identity photo card. Ensure text and '
        'picture are sharp and glare-free.',
        style: AppTypography.body,
      ),
      const SizedBox(height: AppSpacing.sm),
      SegmentedButton<String>(
        segments: const [
          ButtonSegment(value: 'nic', label: Text('National ID')),
          ButtonSegment(value: 'passport', label: Text('Passport')),
        ],
        selected: {d.idType},
        showSelectedIcon: false,
        onSelectionChanged: (s) {
          d.idType = s.first;
          if (d.idType == 'passport') d.idBack = null;
          _changed();
        },
      ),
      const SizedBox(height: AppSpacing.sm),
      if (d.idFront != null)
        _FileTile(
          key: const ValueKey('id-front-file'),
          document: d.idFront!,
          status: 'Uploaded',
          onRemove: () {
            d.idFront = null;
            _changed();
          },
        )
      else
        _UploadBox(
          key: const ValueKey('upload-id-front'),
          title: 'Front Side',
          hint: 'Tap to upload the photo side of your ID',
          icon: LucideIcons.upload,
          onTap: () => _pick(
            DocumentPicker.instance.pickImage,
            (doc) => d.idFront = doc,
          ),
        ),
      const SizedBox(height: AppSpacing.sm),
      if (d.idType == 'nic') ...[
        if (d.idBack != null)
          _FileTile(
            key: const ValueKey('id-back-file'),
            document: d.idBack!,
            status: 'Uploaded',
            onRemove: () {
              d.idBack = null;
              _changed();
            },
          )
        else
          _UploadBox(
            key: const ValueKey('upload-id-back'),
            title: 'Back Side',
            hint: 'Tap to upload Document back',
            icon: LucideIcons.upload,
            onTap: () => _pick(
              DocumentPicker.instance.pickImage,
              (doc) => d.idBack = doc,
            ),
          ),
      ] else
        Text(
          'A passport only needs the photo page.',
          style: AppTypography.caption,
        ),
      const SizedBox(height: AppSpacing.sm),
      Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surfaceLavender,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                key: const ValueKey('id-number'),
                controller: _idNumber,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: d.idType == 'passport'
                      ? 'PASSPORT NUMBER'
                      : 'NIC NUMBER',
                  hintText: VerificationDraft.idNumberHint(d.idType),
                  isDense: true,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                ),
                style: AppTypography.subtitle,
                onChanged: (v) {
                  d.idNumber = v;
                  _changed();
                },
              ),
            ),
            if (VerificationDraft.validIdNumber(d.idType, d.idNumber))
              const StatusPill(
                label: 'Validated',
                background: AppColors.successSoft,
                color: AppColors.success,
              ),
          ],
        ),
      ),
    ],
  );

  // ------------------------------------------------------------------ step 2
  Widget _selfieStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Take a clear selfie in good light. Your whole face must be visible, '
        'with no sunglasses or hat.',
        style: AppTypography.body,
      ),
      const SizedBox(height: AppSpacing.sm),
      if (d.selfie != null)
        _FileTile(
          key: const ValueKey('selfie-file'),
          document: d.selfie!,
          status: 'Captured',
          removeLabel: 'Retake',
          onRemove: () {
            d.selfie = null;
            _changed();
          },
        )
      else
        _UploadBox(
          key: const ValueKey('upload-selfie'),
          title: 'Take Selfie',
          hint: 'Tap to open the camera',
          icon: LucideIcons.camera,
          onTap: () => _pick(
            DocumentPicker.instance.takeSelfie,
            (doc) => d.selfie = doc,
          ),
        ),
    ],
  );

  // ------------------------------------------------------------------ step 3
  Widget _qualificationsStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SectionLabel('Your CV (required)'),
      const SizedBox(height: AppSpacing.xs),
      if (d.cv != null)
        _FileTile(
          key: const ValueKey('cv-file'),
          document: d.cv!,
          status: 'Uploaded',
          onRemove: () {
            d.cv = null;
            _changed();
          },
        )
      else
        _UploadBox(
          key: const ValueKey('upload-cv'),
          title: 'Upload CV',
          hint: 'PDF, Word document or photo, up to 10 MB',
          icon: LucideIcons.fileText,
          onTap: () => _pick(
            DocumentPicker.instance.pickDocument,
            (doc) => d.cv = doc,
          ),
        ),
      const SizedBox(height: AppSpacing.md),
      const SectionLabel('Course / training certificates (at least one)'),
      const SizedBox(height: AppSpacing.xs),
      for (var i = 0; i < d.certificates.length; i++) ...[
        _FileTile(
          key: ValueKey('certificate-file-$i'),
          document: d.certificates[i],
          status: 'Uploaded',
          onRemove: () {
            d.certificates.removeAt(i);
            _changed();
          },
        ),
        const SizedBox(height: AppSpacing.xs),
      ],
      if (d.certificates.length < VerificationDraft.maxCertificates)
        _UploadBox(
          key: const ValueKey('add-certificate'),
          title: d.certificates.isEmpty
              ? 'Upload Certificate'
              : 'Add another certificate',
          hint: 'PDF, Word document or photo, up to 10 MB',
          icon: LucideIcons.award,
          onTap: () => _pick(
            DocumentPicker.instance.pickDocument,
            d.certificates.add,
          ),
        ),
      const SizedBox(height: AppSpacing.md),
      const SectionLabel('Other work experience (optional)'),
      const SizedBox(height: AppSpacing.xs),
      for (var i = 0; i < d.experiences.length; i++)
        ListTile(
          key: ValueKey('experience-$i'),
          contentPadding: EdgeInsets.zero,
          dense: true,
          leading: const Icon(LucideIcons.briefcase, color: AppColors.primary),
          title: Text(d.experiences[i].title, style: AppTypography.bodyStrong),
          subtitle: Text(
            [
              if (d.experiences[i].company.isNotEmpty) d.experiences[i].company,
              if (d.experiences[i].years > 0)
                '${d.experiences[i].years} yr${d.experiences[i].years == 1 ? '' : 's'}',
            ].join(' · '),
            style: AppTypography.caption,
          ),
          trailing: IconButton(
            tooltip: 'Remove experience',
            icon: const Icon(LucideIcons.x, size: 18),
            onPressed: () {
              d.experiences.removeAt(i);
              _changed();
            },
          ),
        ),
      if (d.experiences.length < ExperienceEntry.maxEntries)
        TextButton.icon(
          key: const ValueKey('add-experience'),
          onPressed: _addExperience,
          icon: const Icon(LucideIcons.plus, size: 18),
          label: const Text('Add experience'),
        ),
    ],
  );
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    super.key,
    required this.number,
    required this.title,
    required this.subtitle,
    required this.done,
    required this.open,
    required this.onTap,
    required this.child,
  });

  final int number;
  final String title, subtitle;
  final bool done, open;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: EdgeInsets.zero,
    border: Border.all(
      color: open ? AppColors.primary.withValues(alpha: 0.45) : AppColors.border,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: AppRadius.card,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                _NumberDot(number: number, done: done, open: open),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.subtitle.copyWith(
                          color: open || done ? AppColors.navy : AppColors.body,
                        ),
                      ),
                      Text(subtitle, style: AppTypography.caption),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                if (done && !open)
                  const Icon(
                    LucideIcons.circleCheck,
                    color: AppColors.success,
                    size: 22,
                  )
                else if (open)
                  const StatusPill(
                    label: 'CURRENT',
                    background: AppColors.primaryTint,
                    color: AppColors.primaryDark,
                  )
                else
                  Text(
                    'Next',
                    style: AppTypography.label.copyWith(color: AppColors.primary),
                  ),
              ],
            ),
          ),
        ),
        if (open)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: child,
          ),
      ],
    ),
  );
}

class _NumberDot extends StatelessWidget {
  const _NumberDot({
    required this.number,
    required this.done,
    required this.open,
  });
  final int number;
  final bool done, open;

  @override
  Widget build(BuildContext context) {
    final filled = open || done;
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? (done ? AppColors.success : AppColors.primary) : Colors.white,
        border: Border.all(
          color: filled ? Colors.transparent : AppColors.divider,
          width: 1.5,
        ),
      ),
      child: done
          ? const Icon(LucideIcons.check, size: 16, color: Colors.white)
          : Text(
              '$number',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: filled ? Colors.white : AppColors.muted,
              ),
            ),
    );
  }
}

class _FileTile extends StatelessWidget {
  const _FileTile({
    super.key,
    required this.document,
    required this.status,
    required this.onRemove,
    this.removeLabel = 'Remove',
  });

  final PickedDocument document;
  final String status, removeLabel;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.xs),
    decoration: BoxDecoration(
      color: AppColors.primaryTint,
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: AppColors.primarySoft),
    ),
    child: Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: SizedBox(
            width: 48,
            height: 48,
            child: document.isImage
                ? Image.memory(
                    document.bytes,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const _FileIcon(),
                  )
                : const _FileIcon(),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                document.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyStrong,
              ),
              Text(
                '${document.sizeLabel} · $status',
                style: AppTypography.caption,
              ),
            ],
          ),
        ),
        const Icon(LucideIcons.check, color: AppColors.success, size: 20),
        TextButton(onPressed: onRemove, child: Text(removeLabel)),
      ],
    ),
  );
}

class _FileIcon extends StatelessWidget {
  const _FileIcon();

  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: AppColors.surface,
    child: Icon(LucideIcons.fileText, color: AppColors.primary),
  );
}

class _UploadBox extends StatelessWidget {
  const _UploadBox({
    super.key,
    required this.title,
    required this.hint,
    required this.icon,
    required this.onTap,
  });

  final String title, hint;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '$title. $hint',
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: CustomPaint(
        painter: _DashedBorderPainter(),
        child: ExcludeSemantics(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.lg,
              horizontal: AppSpacing.md,
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryTint,
                  ),
                  child: Icon(icon, size: 20, color: AppColors.primary),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(title, style: AppTypography.subtitle.copyWith(
                  color: AppColors.primaryDark,
                )),
                const SizedBox(height: 2),
                Text(
                  hint,
                  textAlign: TextAlign.center,
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(AppRadius.md),
        ),
      );
    for (final PathMetric metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 7), paint);
        distance += 12;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ExperienceDialog extends StatefulWidget {
  const _ExperienceDialog();

  @override
  State<_ExperienceDialog> createState() => _ExperienceDialogState();
}

class _ExperienceDialogState extends State<_ExperienceDialog> {
  final _title = TextEditingController();
  final _company = TextEditingController();
  final _years = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _company.dispose();
    _years.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Add experience'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const ValueKey('experience-title'),
            controller: _title,
            decoration: const InputDecoration(labelText: 'Role / what you did'),
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            key: const ValueKey('experience-company'),
            controller: _company,
            decoration: const InputDecoration(
              labelText: 'Company or place (optional)',
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            key: const ValueKey('experience-years'),
            controller: _years,
            decoration: const InputDecoration(labelText: 'Years (optional)'),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton(
        key: const ValueKey('experience-save'),
        onPressed: _title.text.trim().isEmpty
            ? null
            : () => Navigator.of(context).pop(
                ExperienceEntry(
                  title: _title.text.trim(),
                  company: _company.text.trim(),
                  years: (int.tryParse(_years.text.trim()) ?? 0).clamp(0, 80),
                ),
              ),
        child: const Text('Add'),
      ),
    ],
  );
}
