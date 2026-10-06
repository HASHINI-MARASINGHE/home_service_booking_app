import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../models/verification_draft.dart';
import '../../services/auth_service.dart';
import '../../services/provider_verification_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/app_widgets.dart';
import '../provider/verification/verification_widgets.dart';

/// Provider sign-up in three steps: your details, identity documents, then
/// the login (email + password). The account is only created at the end,
/// together with the upload, so an admin always has everything to review.
class ProviderRegistrationScreen extends StatefulWidget {
  const ProviderRegistrationScreen({
    super.key,
    required this.authService,
    this.verificationService,
  });

  final AuthService authService;
  final ProviderVerificationService? verificationService;

  @override
  State<ProviderRegistrationScreen> createState() =>
      _ProviderRegistrationScreenState();
}

class _ProviderRegistrationScreenState
    extends State<ProviderRegistrationScreen> {
  final _draft = VerificationDraft();
  final _detailsKey = GlobalKey<FormState>();
  final _accountKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  int _step = 0;
  bool _busy = false;
  String? _error;

  late final ProviderVerificationService _verification =
      widget.verificationService ?? ProviderVerificationService();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _next() {
    if (_step == 0 && !_detailsKey.currentState!.validate()) return;
    if (_step == 1 && !_draft.isComplete) return;
    setState(() => _step++);
  }

  void _back() {
    if (_busy) return;
    if (_step == 0) {
      Navigator.of(context).maybePop();
    } else {
      setState(() => _step--);
    }
  }

  Future<void> _submit() async {
    if (_busy || !_accountKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.authService.register(
        name: _draft.fullName,
        email: _email.text,
        password: _password.text,
        role: AppUser.providerRole,
        onCreated: (user) => _verification.submitFor(user.uid, _draft),
      );
      // The session changes to the provider's own screens; close this flow.
      if (mounted) {
        setState(() => _busy = false);
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
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
  Widget build(BuildContext context) => PopScope(
    canPop: _step == 0 && !_busy,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) _back();
    },
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Provider Registration'),
        leading: BackButton(onPressed: _back),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: Center(
              child: StatusPill(
                key: const ValueKey('registration-step'),
                label: 'Step ${_step + 1} of 3',
                background: AppColors.primaryTint,
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.screen),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: switch (_step) {
                      0 => _detailsStep(),
                      1 => VerificationDocumentsStep(
                        draft: _draft,
                        onChanged: () => setState(() {}),
                      ),
                      _ => _accountStep(),
                    },
                  ),
                ),
              ),
            ),
            _bottomBar(),
          ],
        ),
      ),
    ),
  );

  Widget _detailsStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('Tell us about you', style: AppTypography.headline),
      const SizedBox(height: AppSpacing.xs),
      Text(
        VerificationDraft.requireEverything
            ? 'These details are shown on your provider profile. Everything '
                  'except "About you" is required.'
            : 'Only your full name is required for now. You can add the rest '
                  'later.',
        style: AppTypography.body,
      ),
      const SizedBox(height: AppSpacing.lg),
      VerificationDetailsForm(draft: _draft, formKey: _detailsKey),
    ],
  );

  Widget _accountStep() => Form(
    key: _accountKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Create your login', style: AppTypography.headline),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Use these to log in. An admin will review your documents before you '
          'can accept jobs. Until then you can use your profile and '
          'notifications.',
          style: AppTypography.body,
        ),
        const SizedBox(height: AppSpacing.lg),
        TextFormField(
          key: const ValueKey('register-email'),
          controller: _email,
          enabled: !_busy,
          decoration: const InputDecoration(labelText: 'Email'),
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          autocorrect: false,
          textInputAction: TextInputAction.next,
          validator: (value) =>
              RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                  .hasMatch(value?.trim() ?? '')
              ? null
              : 'Enter a valid email address.',
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          key: const ValueKey('register-password'),
          controller: _password,
          enabled: !_busy,
          decoration: const InputDecoration(labelText: 'Password'),
          obscureText: true,
          autocorrect: false,
          enableSuggestions: false,
          autofillHints: const [AutofillHints.newPassword],
          textInputAction: TextInputAction.next,
          validator: (value) =>
              (value ?? '').length < 6 ? 'Use at least 6 characters.' : null,
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          key: const ValueKey('register-confirm'),
          controller: _confirm,
          enabled: !_busy,
          decoration: const InputDecoration(labelText: 'Confirm password'),
          obscureText: true,
          autocorrect: false,
          enableSuggestions: false,
          onFieldSubmitted: (_) => _submit(),
          validator: (value) =>
              value != _password.text ? 'The passwords do not match.' : null,
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            _error!,
            key: const ValueKey('registration-error'),
            style: AppTypography.body.copyWith(color: AppColors.danger),
          ),
        ],
        if (_busy) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            'Uploading your documents. Please keep this screen open.',
            style: AppTypography.caption,
          ),
        ],
      ],
    ),
  );

  Widget _bottomBar() {
    final problem = _step == 1 ? _draft.firstProblem : null;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (problem != null) ...[
              Text(
                problem,
                key: const ValueKey('missing-hint'),
                textAlign: TextAlign.center,
                style: AppTypography.caption,
              ),
              const SizedBox(height: AppSpacing.xs),
            ],
            PrimaryButton(
              key: const ValueKey('registration-next'),
              label: _step == 2
                  ? 'Submit for verification'
                  : (_step == 1 &&
                            !VerificationDraft.requireEverything &&
                            !_draft.hasDocuments
                        ? 'Skip for now'
                        : 'Continue'),
              busy: _busy,
              onPressed: _step == 2
                  ? _submit
                  : (_step == 1 && !_draft.isComplete ? null : _next),
            ),
          ],
        ),
      ),
    );
  }
}
