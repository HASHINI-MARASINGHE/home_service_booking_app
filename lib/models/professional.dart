/// Public profile of a service professional at `professionals/{providerId}`.
/// Written only by the trusted backend; any signed-in customer may read it.
class Professional {
  const Professional({
    required this.id,
    required this.name,
    this.photoUrl,
    this.specialty = '',
    this.rating,
    this.completedJobs = 0,
    this.verified = false,
    this.phone = '',
    this.licenseNumber = '',
    this.area = '',
    this.workingSlots = defaultSlots,
    this.workingDays = defaultDays,
    this.about = '',
    this.experience = 0,
    this.services = const [],
    this.pricing,
  });

  final String id, name, specialty, phone, licenseNumber, area;
  final String? photoUrl;
  final double? rating;
  final int completedJobs;
  final bool verified;

  /// Daily slot template as `(start, end)` in `HH:mm` Colombo time.
  final List<(String, String)> workingSlots;

  /// ISO weekdays the professional works (Monday = 1).
  final List<int> workingDays;

  /// Mirrored from the provider's own profile when they save it.
  final String about;
  final int experience;
  final List<String> services;

  /// Starting price in LKR.
  final double? pricing;

  static const defaultSlots = [
    ('08:30', '10:00'),
    ('10:30', '12:00'),
    ('13:30', '15:00'),
    ('15:30', '17:00'),
    ('17:30', '19:00'),
  ];
  static const defaultDays = [1, 2, 3, 4, 5, 6];

  String get firstName => name.trim().split(RegExp(r'\s+')).first;

  static final _time = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');

  factory Professional.fromMap(String id, Map<String, dynamic> data) {
    final slots = <(String, String)>[
      if (data['workingSlots'] is List)
        for (final slot in data['workingSlots'] as List)
          if (slot is Map &&
              slot['start'] is String &&
              slot['end'] is String &&
              _time.hasMatch(slot['start'] as String) &&
              _time.hasMatch(slot['end'] as String))
            (slot['start'] as String, slot['end'] as String),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    final days = data['workingDays'] is List
        ? (data['workingDays'] as List)
              .whereType<num>()
              .map((d) => d.toInt())
              .where((d) => d >= 1 && d <= 7)
              .toList()
        : defaultDays;
    final rating = data['rating'];
    final photo = data['photoUrl'];
    final experience = data['experience'];
    final pricing = data['pricing'];
    String text(String key) => data[key] is String ? data[key] as String : '';
    return Professional(
      id: id,
      name: text('name').trim().isEmpty ? 'Your professional' : text('name'),
      photoUrl: photo is String && photo.isNotEmpty ? photo : null,
      specialty: text('specialty'),
      rating: rating is num && rating >= 0 && rating <= 5
          ? rating.toDouble()
          : null,
      completedJobs: (data['completedJobs'] as num?)?.toInt() ?? 0,
      verified: data['verified'] == true,
      phone: text('phone'),
      licenseNumber: text('licenseNumber'),
      area: text('area'),
      workingSlots: slots.isEmpty ? defaultSlots : slots,
      workingDays: days.isEmpty ? defaultDays : days,
      about: text('about'),
      experience: experience is num && experience >= 0 && experience <= 80
          ? experience.toInt()
          : 0,
      services: data['services'] is List
          ? (data['services'] as List)
                .whereType<String>()
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toList()
          : const [],
      pricing: pricing is num && pricing.isFinite && pricing >= 0
          ? pricing.toDouble()
          : null,
    );
  }
}
