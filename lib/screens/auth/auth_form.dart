import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import 'admin_login_screen.dart';
import 'provider_registration_screen.dart';

class AuthForm extends StatefulWidget {
  const AuthForm({
    super.key,
    required this.authService,
    required this.register,
    required this.onSwitch,
  });

  final AuthService authService;
  final bool register;
  final VoidCallback onSwitch;

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String _role = AppUser.customerRole;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    final email = _email.text.trim();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      setState(
        () => _error = 'Enter your email above, then tap Forgot password.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.authService.sendPasswordReset(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password reset link sent to $email.')),
        );
      }
    } catch (error) {
      if (mounted) setState(() => _error = AuthService.errorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (widget.register) {
        await widget.authService.register(
          name: _name.text,
          email: _email.text,
          password: _password.text,
          role: _role,
        );
      } else {
        await widget.authService.login(
          email: _email.text,
          password: _password.text,
        );
      }
    } catch (error) {
      if (mounted) setState(() => _error = AuthService.errorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openProviderRegistration() => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) =>
          ProviderRegistrationScreen(authService: widget.authService),
    ),
  );

  void _openAdminLogin() => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => AdminLoginScreen(authService: widget.authService),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final title = widget.register ? 'Create account' : 'Log in';
    // Providers go through the longer verification sign-up instead.
    final providerFlow = widget.register && _role == AppUser.providerRole;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: AutofillGroup(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (widget.register) ...[
                        DropdownButtonFormField<String>(
                          key: const ValueKey('role-dropdown'),
                          initialValue: _role,
                          decoration: const InputDecoration(
                            labelText: 'I am signing up as a',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: AppUser.customerRole,
                              child: Text('Customer'),
                            ),
                            DropdownMenuItem(
                              value: AppUser.providerRole,
                              child: Text('Provider'),
                            ),
                          ],
                          onChanged: _busy
                              ? null
                              : (value) => setState(() => _role = value!),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (providerFlow) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primaryContainer
                                .withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text(
                            'Providers are verified before they can accept '
                            'jobs. You will add your details, ID, a live '
                            'selfie, your CV and a course certificate, then '
                            'create your login. An admin reviews it.',
                          ),
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          key: const ValueKey('provider-continue'),
                          onPressed: _openProviderRegistration,
                          child: const Text('Continue as provider'),
                        ),
                      ] else ...[
                        if (widget.register) ...[
                          TextFormField(
                            controller: _name,
                            enabled: !_busy,
                            decoration: const InputDecoration(
                              labelText: 'Name',
                            ),
                            autofillHints: const [AutofillHints.name],
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? 'Enter your name.'
                                : null,
                          ),
                          const SizedBox(height: 16),
                        ],
                        TextFormField(
                          controller: _email,
                          enabled: !_busy,
                          decoration: const InputDecoration(labelText: 'Email'),
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          autocorrect: false,
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            final email = value?.trim() ?? '';
                            if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                .hasMatch(email)) {
                              return 'Enter a valid email address.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _password,
                          enabled: !_busy,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                          ),
                          obscureText: true,
                          autocorrect: false,
                          enableSuggestions: false,
                          autofillHints: [
                            widget.register
                                ? AutofillHints.newPassword
                                : AutofillHints.password,
                          ],
                          onFieldSubmitted: (_) => _submit(),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter your password.';
                            }
                            if (widget.register && value.length < 6) {
                              return 'Use at least 6 characters.';
                            }
                            return null;
                          },
                        ),
                        if (!widget.register)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _busy ? null : _resetPassword,
                              child: const Text('Forgot password?'),
                            ),
                          ),
                        if (_error != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            _error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: _busy ? null : _submit,
                          child: _busy
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(title),
                        ),
                      ],
                      TextButton(
                        onPressed: _busy ? null : widget.onSwitch,
                        child: Text(
                          widget.register
                              ? 'Already have an account? Log in'
                              : 'New here? Create an account',
                        ),
                      ),
                      if (!widget.register)
                        TextButton(
                          key: const ValueKey('admin-signin-link'),
                          onPressed: _busy ? null : _openAdminLogin,
                          child: const Text('Admin sign in'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
