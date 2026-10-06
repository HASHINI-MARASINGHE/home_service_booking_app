import 'package:cloud_firestore/cloud_firestore.dart';

enum VerificationStatus {
  /// Nothing submitted yet (new or older provider accounts).
  none,
  pending,
  verified,
  rejected;

  static VerificationStatus parse(Object? value) =>
      VerificationStatus.values.firstWhere(
        (status) => status.name == value,
        orElse: () => VerificationStatus.none,
      );
}

/// An uploaded document: a display name and its Cloudinary image URL.
class VerificationFile {
  const VerificationFile({required this.name, required this.url});
  final String name, url;

  Map<String, dynamic> toMap() => {'name': name, 'url': url};

  static VerificationFile? fromMap(Object? value) {
    if (value is! Map) return null;
    final name = value['name'];
    final url = value['url'];
    if (name is! String || url is! String || url.isEmpty) return null;
    return VerificationFile(name: name, url: url);
  }

  bool get isImage {
    final lower = name.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp');
  }
}

/// Optional extra work experience a provider can add (never required).
class ExperienceEntry {
  const ExperienceEntry({
    required this.title,
    this.company = '',
    this.years = 0,
  });
  final String title, company;
  final int years;

  static const maxEntries = 5;

  Map<String, dynamic> toMap() => {
    'title': title,
    'company': company,
    'years': years,
  };

  static ExperienceEntry? fromMap(Object? value) {
    if (value is! Map) return null;
    final title = value['title'];
    if (title is! String || title.trim().isEmpty) return null;
    final years = value['years'];
    return ExperienceEntry(
      title: title,
      company: value['company'] is String ? value['company'] as String : '',
      years: years is num ? years.toInt() : 0,
    );
  }
}

/// A provider's verification submission at `providerVerifications/{uid}`.
/// Only an admin can move it from pending to verified or rejected.
class ProviderVerification {
  const ProviderVerification({
    required this.uid,
    required this.fullName,
    required this.phone,
    required this.profession,
    required this.experienceYears,
    required this.status,
    this.idType = 'nic',
    this.idNumber = '',
    this.idFront,
    this.selfie,
    this.cv,
    this.certificates = const [],
    this.about = '',
    this.idBack,
    this.experiences = const [],
    this.providerCode,
    this.submittedAt,
    this.reviewedAt,
    this.rejectionReason,
  });

  final String uid, fullName, phone, profession, idType, idNumber, about;
  final int experienceYears;
  // Documents are optional while sign-up is relaxed (see
  // VerificationDraft.requireEverything); the admin sees what was provided.
  final VerificationFile? idFront, idBack, selfie, cv;
  final List<VerificationFile> certificates;
  final List<ExperienceEntry> experiences;
  final VerificationStatus status;

  /// Public Provider ID (e.g. HCP-1001), generated when an admin verifies.
  final String? providerCode;
  final DateTime? submittedAt, reviewedAt;
  final String? rejectionReason;

  bool get isVerified => status == VerificationStatus.verified;

  /// Nothing was uploaded with this submission.
  bool get hasNoDocuments =>
      idFront == null &&
      idBack == null &&
      selfie == null &&
      cv == null &&
      certificates.isEmpty;
  String get idTypeLabel => idType == 'passport' ? 'Passport' : 'National ID';

  static ProviderVerification? fromMap(String uid, Map<String, dynamic>? d) {
    if (d == null) return null;
    String text(String key) => d[key] is String ? d[key] as String : '';
    if (text('fullName').isEmpty || d['status'] is! String) return null;
    DateTime? time(String key) =>
        d[key] is Timestamp ? (d[key] as Timestamp).toDate() : null;
    final certificates = d['certificates'];
    final experiences = d['experiences'];
    return ProviderVerification(
      uid: uid,
      fullName: text('fullName'),
      phone: text('phone'),
      profession: text('profession'),
      about: text('about'),
      experienceYears: (d['experienceYears'] as num?)?.toInt() ?? 0,
      idType: text('idType') == 'passport' ? 'passport' : 'nic',
      idNumber: text('idNumber'),
      idFront: VerificationFile.fromMap(d['idFront']),
      idBack: VerificationFile.fromMap(d['idBack']),
      selfie: VerificationFile.fromMap(d['selfie']),
      cv: VerificationFile.fromMap(d['cv']),
      certificates: certificates is List
          ? [for (final c in certificates) ?VerificationFile.fromMap(c)]
          : const [],
      experiences: experiences is List
          ? [for (final e in experiences) ?ExperienceEntry.fromMap(e)]
          : const [],
      status: VerificationStatus.parse(d['status']),
      providerCode: d['providerCode'] is String
          ? d['providerCode'] as String
          : null,
      submittedAt: time('submittedAt'),
      reviewedAt: time('reviewedAt'),
      rejectionReason: d['rejectionReason'] is String
          ? d['rejectionReason'] as String
          : null,
    );
  }
}
