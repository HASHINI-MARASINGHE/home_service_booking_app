import 'package:flutter/material.dart';

import '../../../models/app_user.dart';
import '../../../models/provider_verification.dart';
import '../../../models/verification_draft.dart';
import '../../../services/auth_service.dart';
import '../../../services/provider_verification_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/common/app_widgets.dart';
import 'verification_widgets.dart';

/// "Identity Verification" for a signed-in provider who has not submitted yet
/// (older accounts) or whose submission was sent back for changes.
class VerificationScreen extends StatefulWidget {
  const VerificationScreen({
    super.key,
    required this.user,
    required this.service,
    this.previous,
  });

  final AppUser user;
  final ProviderVerificationService service;

  /// The rejected submission, used to pre-fill the details and show why.
  final ProviderVerification? previous;

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _detailsKey = GlobalKey<FormState>();
  late final VerificationDraft _draft = _initialDraft();
  bool _busy = false;
  String? _error;

  // Pre-fills form fields if this is a resubmission of an earlier rejected request.
  VerificationDraft _initialDraft() {
    final p = widget.previous;
    final draft = VerificationDraft(
      fullName: p?.fullName ?? widget.user.name,
      phone: p?.phone ?? '',
      profession: p?.profession ?? '',
      experienceYears: p == null ? '' : '${p.experienceYears}',
      about: p?.about ?? '',
      idType: p?.idType ?? 'nic',
    );
    if (p != null) draft.experiences.addAll(p.experiences);
    return draft;
  }

  // Validates both form inputs and document draft completeness before dispatching upload.
  Future<void> _submit() async {
    // The form lives on this page, so it is always built; the draft check
    // covers it too (isComplete includes the details).
    if (_busy || !_draft.isComplete) return;
    if (_detailsKey.currentState?.validate() == false) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.service.submit(_draft);
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = AuthService.errorMessage(error);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reason = widget.previous?.rejectionReason;
    final problem = _draft.firstProblem;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Identity Verification'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: Center(
              child: StatusPill(
                label: '${_draft.documentStepsDone}/3 done',
                background: AppColors.primaryTint,
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screen),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (reason != null) ...[
                Container(
                  key: const ValueKey('rejection-reason'),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.warningSoft,
                    border: Border.all(color: AppColors.warningBorder),
                    borderRadius: AppRadius.card,
                  ),
                  child: Text(
                    'Our team asked for changes: $reason',
                    style: AppTypography.body,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your details', style: AppTypography.title),
                    const SizedBox(height: AppSpacing.md),
                    VerificationDetailsForm(
                      draft: _draft,
                      formKey: _detailsKey,
                      onChanged: () => setState(() {}),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              VerificationDocumentsStep(
                draft: _draft,
                onChanged: () => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (_error != null) ...[
                Text(
                  _error!,
                  style: AppTypography.body.copyWith(color: AppColors.danger),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              if (problem != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Text(
                    problem,
                    key: const ValueKey('missing-hint'),
                    textAlign: TextAlign.center,
                    style: AppTypography.caption,
                  ),
                ),
              PrimaryButton(
                key: const ValueKey('verification-submit'),
                label: 'Submit for review',
                busy: _busy,
                onPressed: problem == null ? _submit : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
