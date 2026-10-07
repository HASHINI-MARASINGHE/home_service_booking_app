import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/provider_verification.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/common/app_widgets.dart';

/// One provider's submission: everything they sent, with the admin's actions
/// (verify, or send back with a reason) at the bottom while it is pending.
class AdminVerificationScreen extends StatefulWidget {
  const AdminVerificationScreen({
    super.key,
    required this.service,
    required this.submission,
  });

  final AdminService service;
  final ProviderVerification submission;

  @override
  State<AdminVerificationScreen> createState() =>
      _AdminVerificationScreenState();
}

class _AdminVerificationScreenState extends State<AdminVerificationScreen> {
  bool _busy = false;

  ProviderVerification get s => widget.submission;

  Future<void> _verify() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Verify ${s.fullName}?'),
        content: const Text(
          'They get a Provider ID, a public verified profile and access to '
          'jobs, and are notified straight away.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('confirm-verify'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Verify provider'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      final code = await widget.service.verify(s);
      if (!mounted) return;
      showAppSnack(context, '${s.fullName} is verified. Provider ID $code.');
      Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        setState(() => _busy = false);
        showAppSnack(context, AuthService.errorMessage(error), error: true);
      }
    }
  }

  Future<void> _reject() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const _ReasonDialog(),
    );
    if (reason == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await widget.service.reject(s, reason);
      if (!mounted) return;
      showAppSnack(context, '${s.fullName} was sent back with your note.');
      Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        setState(() => _busy = false);
        showAppSnack(context, AuthService.errorMessage(error), error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = s.status == VerificationStatus.pending;
    return Scaffold(
      appBar: AppBar(title: const Text('Review provider')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.screen),
                children: [
                  _header(),
                  if (s.hasNoDocuments) ...[
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      key: const ValueKey('no-documents-note'),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.warningSoft,
                        border: Border.all(color: AppColors.warningBorder),
                        borderRadius: AppRadius.card,
                      ),
                      child: Text(
                        'This provider uploaded no documents. Verify only if you '
                        'have checked them another way.',
                        style: AppTypography.body,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  _section('Details', [
                    _row('Phone', s.phone),
                    _row('Profession', s.profession),
                    _row(
                      'Experience',
                      '${s.experienceYears} year${s.experienceYears == 1 ? '' : 's'}',
                    ),
                    if (s.about.isNotEmpty) _row('About', s.about),
                  ]),
                  const SizedBox(height: AppSpacing.md),
                  _section('Identity (${s.idTypeLabel})', [
                    _row(
                      'Number',
                      s.idNumber.isEmpty ? 'Not provided' : s.idNumber,
                      key: 'detail-id-number',
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _doc('Front', s.idFront),
                    if (s.idBack != null) _doc('Back', s.idBack!),
                  ]),
                  const SizedBox(height: AppSpacing.md),
                  _section('Live selfie', [_doc('Selfie', s.selfie)]),
                  const SizedBox(height: AppSpacing.md),
                  _section('CV & certificates', [
                    _doc('CV', s.cv),
                    for (var i = 0; i < s.certificates.length; i++)
                      _doc('Certificate ${i + 1}', s.certificates[i]),
                  ]),
                  if (s.experiences.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    _section('Other experience', [
                      for (final e in s.experiences)
                        _row(
                          e.title,
                          [
                            if (e.company.isNotEmpty) e.company,
                            if (e.years > 0) '${e.years} yrs',
                          ].join(' · '),
                        ),
                    ]),
                  ],
                  if (s.status == VerificationStatus.rejected &&
                      s.rejectionReason != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    _section('Why it was sent back', [
                      Text(s.rejectionReason!, style: AppTypography.body),
                    ]),
                  ],
                ],
              ),
            ),
            if (pending)
              DecoratedBox(
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: SecondaryButton(
                          key: const ValueKey('reject-provider'),
                          label: 'Send back',
                          icon: LucideIcons.x,
                          onPressed: _busy ? null : _reject,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: PrimaryButton(
                          key: const ValueKey('verify-provider'),
                          label: 'Verify provider',
                          icon: LucideIcons.badgeCheck,
                          busy: _busy,
                          onPressed: _verify,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _header() => AppCard(
    padding: const EdgeInsets.all(AppSpacing.lg),
    child: Row(
      children: [
        PersonAvatar(name: s.fullName, size: 56),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.fullName, style: AppTypography.title),
              Text(s.profession, style: AppTypography.body),
              if (s.submittedAt != null)
                Text(
                  'Submitted ${Formatters.shortDate(s.submittedAt!)}',
                  style: AppTypography.caption,
                ),
              if (s.providerCode != null)
                Text(
                  'Provider ID · ${s.providerCode}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _section(String title, List<Widget> children) => AppCard(
    padding: const EdgeInsets.all(AppSpacing.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(title),
        const SizedBox(height: AppSpacing.sm),
        ...children,
      ],
    ),
  );

  Widget _row(String label, String value, {String? key}) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 104, child: Text(label, style: AppTypography.caption)),
        Expanded(
          child: Text(
            value,
            key: key == null ? null : ValueKey(key),
            style: AppTypography.bodyStrong,
          ),
        ),
      ],
    ),
  );

  Widget _doc(String label, VerificationFile? file) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: file == null
        ? Text('$label · Not provided', style: AppTypography.caption)
        : _DocumentView(label: label, file: file),
  );
}

/// An uploaded document: images are shown (tap to enlarge), others open in
/// the browser / a viewer app.
class _DocumentView extends StatelessWidget {
  const _DocumentView({required this.label, required this.file});
  final String label;
  final VerificationFile file;

  Future<void> _open(BuildContext context) async {
    final ok = await launchUrl(
      Uri.parse(file.url),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && context.mounted) {
      showAppSnack(context, 'Could not open ${file.name}.', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!file.isImage) {
      return ListTile(
        key: ValueKey('doc-${label.toLowerCase().replaceAll(' ', '-')}'),
        contentPadding: EdgeInsets.zero,
        leading: const Icon(LucideIcons.fileText, color: AppColors.primary),
        title: Text('$label · ${file.name}', style: AppTypography.bodyStrong),
        subtitle: const Text('Tap to open'),
        trailing: const Icon(LucideIcons.externalLink, size: 18),
        onTap: () => _open(context),
      );
    }
    return Column(
      key: ValueKey('doc-${label.toLowerCase().replaceAll(' ', '-')}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.caption),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => showDialog<void>(
            context: context,
            builder: (_) => Dialog(
              child: InteractiveViewer(
                child: Image.network(file.url, fit: BoxFit.contain),
              ),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: SizedBox(
                width: double.infinity,
                child: Image.network(
                  file.url,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) => progress == null
                      ? child
                      : const SizedBox(
                          height: 120,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                  errorBuilder: (_, _, _) => Container(
                    height: 90,
                    alignment: Alignment.center,
                    color: AppColors.surfaceLavender,
                    child: Text(
                      'Image could not be loaded',
                      style: AppTypography.caption,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReasonDialog extends StatefulWidget {
  const _ReasonDialog();

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Send back for changes'),
    content: TextField(
      key: const ValueKey('reject-reason'),
      controller: _reason,
      maxLines: 3,
      maxLength: 300,
      decoration: const InputDecoration(
        hintText: 'Tell the provider what to fix (e.g. ID photo is blurry)',
      ),
      onChanged: (_) => setState(() {}),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton(
        key: const ValueKey('confirm-reject'),
        onPressed: _reason.text.trim().length < 5
            ? null
            : () => Navigator.of(context).pop(_reason.text.trim()),
        child: const Text('Send back'),
      ),
    ],
  );
}
