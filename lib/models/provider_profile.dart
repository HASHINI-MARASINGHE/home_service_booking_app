class ProviderProfile {
  const ProviderProfile({
    required this.providerId,
    this.phone = '',
    this.profession = '',
    this.experience = 0,
    this.about = '',
    this.services = const [],
    this.pricing,
    this.availability = false,
    this.verificationStatus = 'unverified',
    this.rating,
  });

  final String providerId, phone, profession, about, verificationStatus;
  final int experience;
  final List<String> services;
  final double? pricing, rating;
  final bool availability;

  factory ProviderProfile.fromMap(
    String uid,
    Map<String, dynamic> data,
  ) => ProviderProfile(
    providerId: uid,
    phone: data['phone'] as String? ?? '',
    profession: data['profession'] as String? ?? '',
    experience: (data['experience'] as num?)?.toInt() ?? 0,
    about: data['about'] as String? ?? '',
    services:
        (data['services'] as List?)?.whereType<String>().toList() ?? const [],
    pricing: (data['pricing'] as num?)?.toDouble(),
    availability: data['availability'] as bool? ?? false,
    verificationStatus: data['verificationStatus'] as String? ?? 'unverified',
    rating: (data['rating'] as num?)?.toDouble(),
  );

  // Ratings and verification belong to a trusted backend, never the edit form.
  Map<String, dynamic> editableFields() => {
    'providerId': providerId,
    'phone': phone,
    'profession': profession,
    'experience': experience,
    'about': about,
    'services': services,
    'pricing': pricing,
    'availability': availability,
  };

  void validate() {
    if (phone.length > 40 ||
        profession.trim().isEmpty ||
        profession.length > 100 ||
        experience < 0 ||
        experience > 80 ||
        about.length > 2000 ||
        services.length > 20 ||
        services.any((s) => s.trim().isEmpty || s.length > 100) ||
        (pricing != null &&
            (!pricing!.isFinite || pricing! < 0 || pricing! > 10000000))) {
      throw ArgumentError('Check your profile fields and try again.');
    }
  }
}
