import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/auth_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/customer_home_theme.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({
    super.key,
    required this.authService,
    required this.userEmail,
  });

  final AuthService authService;
  final String userEmail;

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  static const _kBiometric = 'privacy_biometric_enabled';
  static const _kPersonalized = 'privacy_personalized_recommendations';
  static const _kAnalytics = 'privacy_share_analytics';

  bool _biometric = false;
  bool _personalized = true;
  bool _analytics = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadToggles();
  }

  Future<void> _loadToggles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _biometric = prefs.getBool(_kBiometric) ?? false;
        _personalized = prefs.getBool(_kPersonalized) ?? true;
        _analytics = prefs.getBool(_kAnalytics) ?? true;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _setToggle(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (_) {}
  }

  Future<void> _openChangePasswordDialog() async {
    final formKey = GlobalKey<FormState>();
    final currentPass = TextEditingController();
    final newPass = TextEditingController();
    final confirmPass = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool saving = false;
    String? errorText;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text('Change Password'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Enter your current password and choose a new secure password.',
                    style: TextStyle(
                      color: CustomerHomeTheme.mutedText,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: currentPass,
                    obscureText: obscureCurrent,
                    decoration: InputDecoration(
                      labelText: 'Current password',
                      hintText: '••••••••',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureCurrent
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () => setDialogState(
                          () => obscureCurrent = !obscureCurrent,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Current password is required.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: newPass,
                    obscureText: obscureNew,
                    decoration: InputDecoration(
                      labelText: 'New password',
                      hintText: '••••••••',
                      prefixIcon: const Icon(Icons.vpn_key_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureNew
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () => setDialogState(
                          () => obscureNew = !obscureNew,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.length < 6) {
                        return 'At least 6 characters required.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: confirmPass,
                    obscureText: obscureConfirm,
                    decoration: InputDecoration(
                      labelText: 'Confirm new password',
                      hintText: '••••••••',
                      prefixIcon: const Icon(Icons.check_circle_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureConfirm
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () => setDialogState(
                          () => obscureConfirm = !obscureConfirm,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    validator: (val) {
                      if (val != newPass.text) {
                        return 'Passwords do not match.';
                      }
                      return null;
                    },
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      errorText!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: CustomerHomeTheme.primary,
              ),
              onPressed: saving
                  ? null
                  : () async {
                      if (formKey.currentState?.validate() ?? false) {
                        setDialogState(() {
                          saving = true;
                          errorText = null;
                        });
                        try {
                          await widget.authService.changePassword(
                            currentPassword: currentPass.text,
                            newPassword: newPass.text,
                          );
                          if (dialogCtx.mounted) {
                            Navigator.pop(dialogCtx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Password changed successfully.'),
                              ),
                            );
                          }
                        } catch (err) {
                          setDialogState(() {
                            errorText = AuthService.errorMessage(err);
                            saving = false;
                          });
                        }
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Update Password'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleDeleteAccount() async {
    final passCtrl = TextEditingController();
    bool saving = false;
    String? error;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete Account?'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This action is irreversible. All your profile information, booking history, and saved addresses will be permanently deleted.',
                style: TextStyle(
                  color: CustomerHomeTheme.text,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Please enter your password to confirm:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: passCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: '••••••••',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 10),
                Text(
                  error!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(dialogCtx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: saving
                  ? null
                  : () async {
                      if (passCtrl.text.isEmpty) {
                        setDialogState(() => error = 'Password is required.');
                        return;
                      }
                      setDialogState(() {
                        saving = true;
                        error = null;
                      });
                      try {
                        await widget.authService.deleteAccount(
                          password: passCtrl.text,
                        );
                        if (dialogCtx.mounted) {
                          Navigator.pop(dialogCtx, true);
                        }
                      } catch (err) {
                        setDialogState(() {
                          error = AuthService.errorMessage(err);
                          saving = false;
                        });
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Delete Permanently'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account deleted.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomerHomeTheme.background,
      appBar: AppBar(
        backgroundColor: CustomerHomeTheme.background,
        foregroundColor: CustomerHomeTheme.primaryDark,
        elevation: 0,
        title: const Text(
          'Privacy & Security',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screen,
                  vertical: AppSpacing.lg,
                ),
                children: [
                  const Text(
                    'Security & Access',
                    style: TextStyle(
                      color: CustomerHomeTheme.primaryDark,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: CustomerHomeTheme.border),
                      boxShadow: const [
                        BoxShadow(
                          color: CustomerHomeTheme.shadow,
                          blurRadius: 14,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: CustomerHomeTheme.mint,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.vpn_key_outlined,
                              color: CustomerHomeTheme.primary,
                            ),
                          ),
                          title: const Text(
                            'Change Password',
                            style: TextStyle(
                              color: CustomerHomeTheme.text,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: const Text(
                            'Update your account login password',
                            style: TextStyle(
                              color: CustomerHomeTheme.mutedText,
                              fontSize: 13,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: CustomerHomeTheme.mutedText,
                          ),
                          onTap: _openChangePasswordDialog,
                        ),
                        const Divider(
                          height: 1,
                          indent: 72,
                          color: CustomerHomeTheme.border,
                        ),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: CustomerHomeTheme.mint,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.verified_user_outlined,
                              color: CustomerHomeTheme.primary,
                            ),
                          ),
                          title: const Text(
                            'Login & Security Status',
                            style: TextStyle(
                              color: CustomerHomeTheme.text,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            widget.userEmail,
                            style: const TextStyle(
                              color: CustomerHomeTheme.mutedText,
                              fontSize: 13,
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.brand100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Protected',
                              style: TextStyle(
                                color: CustomerHomeTheme.primaryDark,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const Divider(
                          height: 1,
                          indent: 72,
                          color: CustomerHomeTheme.border,
                        ),
                        SwitchListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 4,
                          ),
                          secondary: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: CustomerHomeTheme.mint,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.fingerprint_rounded,
                              color: CustomerHomeTheme.primary,
                            ),
                          ),
                          title: const Text(
                            'Biometric / Quick Unlock',
                            style: TextStyle(
                              color: CustomerHomeTheme.text,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: const Text(
                            'Require fingerprint or face ID to open',
                            style: TextStyle(
                              color: CustomerHomeTheme.mutedText,
                              fontSize: 13,
                            ),
                          ),
                          value: _biometric,
                          activeTrackColor: AppColors.brand700,
                          activeThumbColor: Colors.white,
                          onChanged: (val) {
                            setState(() => _biometric = val);
                            _setToggle(_kBiometric, val);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                  const SizedBox(height: AppSpacing.xl),
                  const Text(
                    'Data & Privacy Settings',
                    style: TextStyle(
                      color: CustomerHomeTheme.primaryDark,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: CustomerHomeTheme.border),
                      boxShadow: const [
                        BoxShadow(
                          color: CustomerHomeTheme.shadow,
                          blurRadius: 14,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                      children: [
                        SwitchListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 4,
                          ),
                          title: const Text(
                            'Personalized Recommendations',
                            style: TextStyle(
                              color: CustomerHomeTheme.text,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: const Text(
                            'Allow suggestions based on previous home bookings',
                            style: TextStyle(
                              color: CustomerHomeTheme.mutedText,
                              fontSize: 13,
                            ),
                          ),
                          value: _personalized,
                          activeTrackColor: AppColors.brand700,
                          activeThumbColor: Colors.white,
                          onChanged: (val) {
                            setState(() => _personalized = val);
                            _setToggle(_kPersonalized, val);
                          },
                        ),
                        const Divider(height: 1, color: CustomerHomeTheme.border),
                        SwitchListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 4,
                          ),
                          title: const Text(
                            'Share App Analytics',
                            style: TextStyle(
                              color: CustomerHomeTheme.text,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: const Text(
                            'Help improve app speed and crash diagnostics',
                            style: TextStyle(
                              color: CustomerHomeTheme.mutedText,
                              fontSize: 13,
                            ),
                          ),
                          value: _analytics,
                          activeTrackColor: AppColors.brand700,
                          activeThumbColor: Colors.white,
                          onChanged: (val) {
                            setState(() => _analytics = val);
                            _setToggle(_kAnalytics, val);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                  const SizedBox(height: AppSpacing.xxl),
                  // Danger Zone - Delete Account
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.delete_forever_outlined, color: Colors.red),
                            SizedBox(width: 8),
                            Text(
                              'Danger Zone',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Permanently delete your HomeCare account and erase all associated personal data.',
                          style: TextStyle(
                            color: CustomerHomeTheme.mutedText,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 14),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _handleDeleteAccount,
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: const Text('Delete Account'),
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
