import 'package:firebase_core/firebase_core.dart' show FirebaseException;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth/auth_error_banner.dart';
import '../../widgets/auth/auth_text_field.dart';
import '../../widgets/auth/login_hero.dart';
import '../../widgets/auth/primary_button.dart';
import 'admin_login_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.authService,
    required this.onRegister,
    this.preferences,
  });

  final AuthService authService;
  final VoidCallback onRegister;

  /// Stores the remembered email. Defaults to the platform store.
  final SharedPreferencesAsync? preferences;

  /// Only the email is ever remembered, never the password.
  static const rememberedEmailKey = 'login_remembered_email';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  final _email = TextEditingController();
  final _password = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  SharedPreferencesAsync? _prefs;
  bool _busy = false;
  bool _obscure = true;
  bool _remember = false;
  String? _emailError;
  String? _passwordError;
  String? _error;

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(_onEmailFocus);
    _loadRememberedEmail();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage(LoginHero.floatingIcons), context);
    precacheImage(const AssetImage(LoginHero.illustration), context);
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  // Preferences are optional: if the platform store is unavailable the screen
  // still works, it just cannot remember the email.
  SharedPreferencesAsync? get _store {
    try {
      return _prefs ??= widget.preferences ?? SharedPreferencesAsync();
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadRememberedEmail() async {
    try {
      final saved = await _store?.getString(LoginScreen.rememberedEmailKey);
      if (!mounted || saved == null || _email.text.isNotEmpty) return;
      setState(() {
        _email.text = saved;
        _remember = true;
      });
    } catch (_) {}
  }

  Future<void> _saveRememberedEmail(String email) async {
    try {
      if (_remember) {
        await _store?.setString(LoginScreen.rememberedEmailKey, email);
      } else {
        await _store?.remove(LoginScreen.rememberedEmailKey);
      }
    } catch (_) {}
  }

  void _setRemember(bool value) {
    setState(() => _remember = value);
    if (!value) _saveRememberedEmail('');
  }

  String? _validateEmail() => _emailPattern.hasMatch(_email.text.trim())
      ? null
      : 'Enter a valid email address';

  void _onEmailFocus() {
    if (!_emailFocus.hasFocus && _email.text.trim().isNotEmpty) {
      setState(() => _emailError = _validateEmail());
    }
  }

  void _onEmailChanged(String _) => setState(() {
    _error = null;
    // Once flagged, clear the error as soon as the address becomes valid.
    if (_emailError != null) _emailError = _validateEmail();
  });

  void _onPasswordChanged(String value) => setState(() {
    _error = null;
    if (value.isNotEmpty) _passwordError = null;
  });

  /// Maps sign-in failures to the copy in the login designs and defers to
  /// [AuthService.errorMessage] for everything else.
  String _messageFor(Object error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'invalid-credential' || 'wrong-password' || 'user-not-found':
          return 'Incorrect email or password. Please try again.';
      }
    }
    return AuthService.errorMessage(error);
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() {
      _emailError = _validateEmail();
      _passwordError = _password.text.isEmpty ? 'Enter your password' : null;
    });
    if (_emailError != null || _passwordError != null) return;
    FocusScope.of(context).unfocus();
    final email = _email.text.trim();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.authService.login(email: email, password: _password.text);
      TextInput.finishAutofillContext();
      await _saveRememberedEmail(email);
    } catch (error) {
      if (mounted) setState(() => _error = _messageFor(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _email.text.trim();
    if (!_emailPattern.hasMatch(email)) {
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

  void _openAdminLogin() => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => AdminLoginScreen(authService: widget.authService),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final keyboardOpen = media.viewInsets.bottom > 0;
    final heroHeight = keyboardOpen
        ? media.padding.top + 72
        : (media.size.height * 0.38).clamp(260.0, 340.0);
    // Firebase's web emulator pins a notice to the bottom of the page in
    // debug builds; leave room so it never covers the links.
    final bottomGap = 24.0 + (kIsWeb && kDebugMode ? 32.0 : 0.0);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AuthColors.background,
        body: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: media.padding.bottom + bottomGap),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LoginHero(height: heroHeight, compact: keyboardOpen),
              ),
              Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // The card overlaps the full hero, and sits just
                        // below the compact header.
                        AnimatedContainer(
                          duration: LoginHero.duration,
                          curve: Curves.easeOut,
                          height: heroHeight + (keyboardOpen ? 24 : -24),
                        ),
                        _card(),
                        const SizedBox(height: 20),
                        _registerRow(),
                        if (!keyboardOpen) ..._footer(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card() => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: AuthColors.surface,
      borderRadius: BorderRadius.circular(24),
      boxShadow: const [
        BoxShadow(
          color: AuthColors.cardShadow,
          blurRadius: 24,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: const Text(
              'Welcome back',
              style: TextStyle(
                color: AuthColors.heading,
                fontSize: 26,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Log in to book and manage your home services',
            style: TextStyle(color: AuthColors.secondary, fontSize: 14.5),
          ),
          const SizedBox(height: 24),
          AuthTextField(
            fieldKey: const ValueKey('login-email'),
            label: 'Email',
            controller: _email,
            focusNode: _emailFocus,
            prefixIcon: LucideIcons.mail,
            hintText: 'you@example.com',
            errorText: _emailError,
            enabled: !_busy,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            onChanged: _onEmailChanged,
            onSubmitted: (_) => _passwordFocus.requestFocus(),
          ),
          const SizedBox(height: 16),
          AuthTextField(
            fieldKey: const ValueKey('login-password'),
            label: 'Password',
            controller: _password,
            focusNode: _passwordFocus,
            prefixIcon: LucideIcons.lock,
            hintText: '••••••••',
            errorText: _passwordError,
            enabled: !_busy,
            obscureText: _obscure,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            onChanged: _onPasswordChanged,
            onSubmitted: (_) => _submit(),
            suffix: IconButton(
              key: const ValueKey('login-password-toggle'),
              tooltip: _obscure ? 'Show password' : 'Hide password',
              onPressed: _busy
                  ? null
                  : () => setState(() => _obscure = !_obscure),
              icon: Icon(
                _obscure ? LucideIcons.eyeOff : LucideIcons.eye,
                size: 20,
                color: _obscure ? AuthColors.secondary : AuthColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _rememberMe()),
              Flexible(
                child: _link(
                  'Forgot password?',
                  _resetPassword,
                  key: const ValueKey('login-forgot'),
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            AuthErrorBanner(message: _error!),
          ],
          const SizedBox(height: 16),
          PrimaryButton(
            key: const ValueKey('login-submit'),
            label: 'Log in',
            loadingLabel: 'Logging in…',
            loading: _busy,
            onPressed: _submit,
          ),
        ],
      ),
    ),
  );

  Widget _rememberMe() => MergeSemantics(
    child: InkWell(
      key: const ValueKey('login-remember'),
      borderRadius: BorderRadius.circular(8),
      onTap: _busy ? null : () => _setRemember(!_remember),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: 20,
              child: Checkbox(
                value: _remember,
                onChanged: _busy ? null : (value) => _setRemember(value!),
                activeColor: AuthColors.primary,
                side: const BorderSide(
                  color: AuthColors.fieldBorder,
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                'Remember me',
                style: TextStyle(
                  color: _remember ? AuthColors.heading : AuthColors.secondary,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _link(String text, VoidCallback onPressed, {Key? key}) => TextButton(
    key: key,
    onPressed: _busy ? null : onPressed,
    style: TextButton.styleFrom(
      foregroundColor: AuthColors.primary,
      disabledForegroundColor: AuthColors.primary.withValues(alpha: 0.5),
      minimumSize: const Size(48, 48),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
    ),
    child: Text(text),
  );

  Widget _registerRow() => Wrap(
    alignment: WrapAlignment.center,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      const Text(
        'New to HomeCare?',
        style: TextStyle(color: AuthColors.heading, fontSize: 14.5),
      ),
      _link(
        'Create an account',
        widget.onRegister,
        key: const ValueKey('login-register-link'),
      ),
    ],
  );

  List<Widget> _footer() => [
    const SizedBox(height: 4),
    const Divider(color: AuthColors.fieldBorder, height: 1),
    const SizedBox(height: 8),
    Center(
      child: TextButton.icon(
        key: const ValueKey('admin-signin-link'),
        onPressed: _busy ? null : _openAdminLogin,
        icon: const Icon(LucideIcons.shield, size: 16),
        label: const Text('Admin sign in'),
        style: TextButton.styleFrom(
          foregroundColor: AuthColors.secondary,
          disabledForegroundColor: AuthColors.secondary.withValues(alpha: 0.5),
          minimumSize: const Size(48, 48),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
    ),
    const SizedBox(height: 4),
    // Secondary text rather than the lighter placeholder grey, which would
    // fail WCAG AA on this background.
    const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ExcludeSemantics(
          child: Icon(
            LucideIcons.shield,
            size: 14,
            color: AuthColors.secondary,
          ),
        ),
        SizedBox(width: 6),
        Flexible(
          child: Text(
            'Your details are protected',
            style: TextStyle(color: AuthColors.secondary, fontSize: 14),
          ),
        ),
      ],
    ),
  ];
}
