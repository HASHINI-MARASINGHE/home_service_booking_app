import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../../theme/customer_home_theme.dart';
import 'widgets/customer_home_widgets.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
    required this.user,
    required this.authService,
    this.onUserUpdated,
  });

  final AppUser user;
  final AuthService authService;
  final ValueChanged<AppUser>? onUserUpdated;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _newEmailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _picker = ImagePicker();

  Uint8List? _pickedImageBytes;
  bool _showEmailChange = false;
  bool _obscurePassword = true;
  bool _saving = false;
  String? _error;

  bool get _emailChanged =>
      _showEmailChange &&
      _newEmailController.text.trim() != widget.user.email.trim();

  bool get _hasChanges =>
      _nameController.text.trim() != widget.user.name.trim() ||
      _phoneController.text.trim() != (widget.user.phone ?? '').trim() ||
      _pickedImageBytes != null ||
      _emailChanged;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.user.name;
    _phoneController.text = widget.user.phone ?? '';
    _newEmailController.text = widget.user.email;
    _nameController.addListener(_onFieldChanged);
    _phoneController.addListener(_onFieldChanged);
    _newEmailController.addListener(_onFieldChanged);
    _passwordController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _newEmailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  Future<bool> _confirmDiscard() async {
    if (!_hasChanges) return true;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Discard changes?'),
            content: const Text('Your unsaved profile changes will be lost.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Keep editing'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Discard'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    final image = await _picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );
    if (image != null && mounted) {
      final bytes = await image.readAsBytes();
      if (mounted) setState(() => _pickedImageBytes = bytes);
    }
  }

  Future<void> _save() async {
    if (_saving || !_hasChanges) return;
    final name = _nameController.text.trim();
    if (name.isEmpty || name.length > 80) {
      setState(() => _error = 'Enter a name between 1 and 80 characters.');
      return;
    }
    final phone = _phoneController.text.trim();
    if (phone.isNotEmpty &&
        !RegExp(r'^\+?[0-9\s\-()]{7,20}$').hasMatch(phone)) {
      setState(() => _error = 'Enter a valid phone number (e.g. +94 77 123 4567).');
      return;
    }
    if (_emailChanged &&
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
            .hasMatch(_newEmailController.text.trim())) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }
    if (_emailChanged && _passwordController.text.isEmpty) {
      setState(() => _error = 'Enter your current password to change email.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (_emailChanged) {
        await widget.authService.changeEmail(
          currentPassword: _passwordController.text,
          newEmail: _newEmailController.text,
        );
      }
      String? photoUrl;
      if (_pickedImageBytes != null) {
        photoUrl = await widget.authService.uploadProfilePhoto(
          uid: widget.user.uid,
          fileBytes: _pickedImageBytes!,
        );
      }
      await widget.authService.updateProfile(
        uid: widget.user.uid,
        name: name,
        photoUrl: photoUrl,
        phone: phone,
      );
      final updated = await widget.authService.getUserProfile(widget.user.uid);
      if (!mounted) return;
      if (updated == null) {
        throw StateError('The updated profile could not be loaded.');
      }
      widget.onUserUpdated?.call(updated);
      Navigator.pop(context, updated);
    } catch (error) {
      if (mounted) {
        setState(() => _error = AuthService.errorMessage(error));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope<void>(
    canPop: false,
    onPopInvokedWithResult: (didPop, result) async {
      if (didPop || !mounted) return;
      final shouldDiscard = await _confirmDiscard();
      if (!context.mounted) return;
      if (shouldDiscard) Navigator.pop(context);
    },
    child: Scaffold(
      backgroundColor: CustomerHomeTheme.background,
      appBar: AppBar(
        title: const Text('Edit profile'),
        backgroundColor: CustomerHomeTheme.background,
        foregroundColor: CustomerHomeTheme.primaryDark,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: GestureDetector(
                  onTap: _saving ? null : _pickImage,
                  child: Stack(
                    children: [
                      _pickedImageBytes == null
                          ? CustomerAvatar(
                              photoUrl: widget.user.photoUrl,
                              radius: 54,
                            )
                          : CircleAvatar(
                              radius: 54,
                              backgroundColor: CustomerHomeTheme.mint,
                              child: ClipOval(
                                child: Image.memory(
                                  _pickedImageBytes!,
                                  width: 108,
                                  height: 108,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: CustomerHomeTheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt_outlined,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              TextField(
                controller: _nameController,
                enabled: !_saving,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Full name',
                  hintText: 'e.g. John Doe',
                  prefixIcon: const Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _phoneController,
                enabled: !_saving,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone number',
                  hintText: '+94 77 123 4567',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                initialValue: widget.user.email,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _saving
                      ? null
                      : () => setState(() {
                          _showEmailChange = !_showEmailChange;
                          _error = null;
                        }),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(
                    _showEmailChange ? 'Cancel email change' : 'Change email',
                  ),
                ),
              ),
              if (_showEmailChange) ...[
                const SizedBox(height: 4),
                TextField(
                  controller: _newEmailController,
                  enabled: !_saving,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'New email',
                    hintText: 'you@example.com',
                    prefixIcon: const Icon(Icons.alternate_email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  enabled: !_saving,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Current password',
                    hintText: '••••••••',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      tooltip: _obscurePassword
                          ? 'Show password'
                          : 'Hide password',
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your current password is required to securely update your email.',
                  style: TextStyle(
                    color: CustomerHomeTheme.mutedText,
                    fontSize: 14,
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 18),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 28),
              FilledButton(
                onPressed: _saving || !_hasChanges ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: CustomerHomeTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
