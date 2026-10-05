import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../models/provider_profile.dart';
import '../../services/auth_service.dart';
import '../../services/provider_profile_service.dart';
import '../../widgets/provider/provider_widgets.dart';
import '../auth/logout_button.dart';
import 'provider_theme.dart';

class ProviderProfileScreen extends StatefulWidget {
  const ProviderProfileScreen({
    super.key,
    required this.user,
    required this.authService,
    required this.service,
  });
  final AppUser user;
  final AuthService authService;
  final ProviderProfileService service;
  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen> {
  late Stream<ProviderProfile> _profile = widget.service.watchProfile();
  bool _editing = false;

  @override
  Widget build(BuildContext context) => StreamBuilder<ProviderProfile>(
    stream: _profile,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Column(
          children: [
            Expanded(
              child: ProviderFailure(
                error: snapshot.error,
                onRetry: () =>
                    setState(() => _profile = widget.service.watchProfile()),
              ),
            ),
            LogoutButton(authService: widget.authService),
            const SizedBox(height: 20),
          ],
        );
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final profile = snapshot.data!;
      if (_editing) {
        return _ProfileEditor(
          profile: profile,
          service: widget.service,
          onClose: () => setState(() => _editing = false),
        );
      }
      return ProviderPage(
        children: [
          ProviderCard(
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 32,
                  backgroundColor: ProviderTheme.tealLight,
                  child: Icon(
                    Icons.person_outline,
                    size: 36,
                    color: ProviderTheme.teal,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.user.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  widget.user.email,
                  style: const TextStyle(color: ProviderTheme.muted),
                ),
                const SizedBox(height: 12),
                Text(
                  'Verification: ${profile.verificationStatus}',
                  style: const TextStyle(color: ProviderTheme.teal),
                ),
                const SizedBox(height: 6),
                Text(
                  profile.rating == null
                      ? 'No ratings yet'
                      : 'Rating: ${profile.rating!.toStringAsFixed(1)} / 5',
                ),
              ],
            ),
          ),
          ProviderCard(
            child: Column(
              children: [
                DetailRow(
                  icon: Icons.phone_outlined,
                  label: 'Phone',
                  value: _value(profile.phone),
                ),
                DetailRow(
                  icon: Icons.work_outline,
                  label: 'Profession',
                  value: _value(profile.profession),
                ),
                DetailRow(
                  icon: Icons.workspace_premium_outlined,
                  label: 'Experience',
                  value: '${profile.experience} years',
                ),
                DetailRow(
                  icon: Icons.notes_outlined,
                  label: 'About',
                  value: _value(profile.about),
                ),
                DetailRow(
                  icon: Icons.handyman_outlined,
                  label: 'Services',
                  value: profile.services.isEmpty
                      ? 'Not added yet'
                      : profile.services.join(', '),
                ),
                DetailRow(
                  icon: Icons.payments_outlined,
                  label: 'Starting price',
                  value: money(profile.pricing),
                ),
                DetailRow(
                  icon: Icons.event_available_outlined,
                  label: 'Availability',
                  value: profile.availability
                      ? 'Available for new jobs'
                      : 'Not currently available',
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: () => setState(() => _editing = true),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit Profile'),
          ),
          const SizedBox(height: 10),
          LogoutButton(authService: widget.authService),
        ],
      );
    },
  );
  String _value(String value) => value.isEmpty ? 'Not added yet' : value;
}

class _ProfileEditor extends StatefulWidget {
  const _ProfileEditor({
    required this.profile,
    required this.service,
    required this.onClose,
  });
  final ProviderProfile profile;
  final ProviderProfileService service;
  final VoidCallback onClose;
  @override
  State<_ProfileEditor> createState() => _ProfileEditorState();
}

class _ProfileEditorState extends State<_ProfileEditor> {
  final _form = GlobalKey<FormState>();
  late final _phone = TextEditingController(text: widget.profile.phone);
  late final _profession = TextEditingController(
    text: widget.profile.profession,
  );
  late final _experience = TextEditingController(
    text: '${widget.profile.experience}',
  );
  late final _about = TextEditingController(text: widget.profile.about);
  late final _services = TextEditingController(
    text: widget.profile.services.join(', '),
  );
  late final _pricing = TextEditingController(
    text: widget.profile.pricing?.toString() ?? '',
  );
  late bool _available = widget.profile.availability;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final controller in [
      _phone,
      _profession,
      _experience,
      _about,
      _services,
      _pricing,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.service.save(
        ProviderProfile(
          providerId: widget.profile.providerId,
          phone: _phone.text.trim(),
          profession: _profession.text.trim(),
          experience: int.parse(_experience.text.trim()),
          about: _about.text.trim(),
          services: _services.text
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toSet()
              .toList(),
          pricing: _pricing.text.trim().isEmpty
              ? null
              : double.parse(_pricing.text.trim()),
          availability: _available,
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Profile saved.')));
      widget.onClose();
    } catch (error) {
      if (mounted) setState(() => _error = providerError(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _form,
    child: ProviderPage(
      children: [
        Text(
          'Edit provider profile',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        const Text(
          'Your account name and email stay with your account. Add your professional details here.',
          style: TextStyle(color: ProviderTheme.muted),
        ),
        const SizedBox(height: 20),
        _field(
          _phone,
          'Phone (optional)',
          maxLength: 40,
          keyboard: TextInputType.phone,
        ),
        _field(
          _profession,
          'Profession',
          maxLength: 100,
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Enter your profession.'
              : null,
        ),
        _field(
          _experience,
          'Years of experience',
          keyboard: TextInputType.number,
          validator: (value) {
            final years = int.tryParse(value?.trim() ?? '');
            return years == null || years < 0 || years > 80
                ? 'Enter a whole number from 0 to 80.'
                : null;
          },
        ),
        _field(_about, 'About', maxLength: 2000, lines: 4),
        _field(
          _services,
          'Services (separate with commas)',
          lines: 2,
          validator: (value) {
            final services = (value ?? '')
                .split(',')
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty);
            return services.length > 20 || services.any((s) => s.length > 100)
                ? 'Use up to 20 services, each at most 100 characters.'
                : null;
          },
        ),
        _field(
          _pricing,
          'Starting price in LKR (optional)',
          keyboard: const TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            if (value == null || value.trim().isEmpty) return null;
            final price = double.tryParse(value.trim());
            return price == null ||
                    !price.isFinite ||
                    price < 0 ||
                    price > 10000000
                ? 'Enter an amount from 0 to 10,000,000.'
                : null;
          },
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('Available for new jobs'),
          value: _available,
          onChanged: _saving
              ? null
              : (value) => setState(() => _available = value),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              _error!,
              style: const TextStyle(color: ProviderTheme.red),
            ),
          ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saving…' : 'Save profile'),
        ),
        TextButton(
          onPressed: _saving ? null : widget.onClose,
          child: const Text('Cancel'),
        ),
      ],
    ),
  );

  Widget _field(
    TextEditingController controller,
    String label, {
    int? maxLength,
    int lines = 1,
    TextInputType? keyboard,
    String? Function(String?)? validator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: controller,
      enabled: !_saving,
      decoration: InputDecoration(labelText: label),
      maxLength: maxLength,
      maxLines: lines,
      keyboardType: keyboard,
      validator: validator,
    ),
  );
}
