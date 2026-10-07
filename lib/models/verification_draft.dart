import '../services/document_picker.dart';
import 'provider_verification.dart';

/// Everything a provider fills in for verification, before it is uploaded.
///
/// [requireEverything] is the single switch for how strict sign-up is:
/// * `false` (now): only the full name is required. Phone, profession, years,
///   ID, selfie, CV and certificates can be added, but nothing is compulsory.
///   Handy while testing sign-up without documents.
/// * `true`: details, ID document + number, live selfie, CV and at least one
///   certificate are all compulsory (extra work experience stays optional).
class VerificationDraft {
  VerificationDraft({
    this.fullName = '',
    this.phone = '',
    this.profession = '',
    this.experienceYears = '',
    this.about = '',
    this.idType = 'nic',
    this.idNumber = '',
  });

  /// Flip to `true` to make every document compulsory.
  static bool requireEverything = false;

  String fullName, phone, profession, experienceYears, about;
  String idType, idNumber;
  PickedDocument? idFront, idBack, selfie, cv;
  final certificates = <PickedDocument>[];
  final experiences = <ExperienceEntry>[];

  static const maxCertificates = 5;

  // ------------------------------------------------------------ validators
  static String? nameError(String? v) =>
      (v ?? '').trim().length < 2 ? 'Enter your full name.' : null;

  static bool _blank(String? v) => (v ?? '').trim().isEmpty;

  static String? phoneError(String? v) {
    if (_blank(v) && !requireEverything) return null;
    return RegExp(r'^\+?\d{9,15}$')
            .hasMatch((v ?? '').replaceAll(RegExp(r'[\s-]'), ''))
        ? null
        : 'Enter a valid phone number.';
  }

  static String? professionError(String? v) => _blank(v) && requireEverything
      ? 'Tell us what you do (e.g. Plumber).'
      : null;

  static String? yearsError(String? v) {
    if (_blank(v) && !requireEverything) return null;
    final years = int.tryParse((v ?? '').trim());
    return years == null || years < 0 || years > 80
        ? 'Enter your years of experience (0 to 80).'
        : null;
  }

  /// NIC: 9 digits + V/X, or 12 digits. Passport: 6 to 9 letters/digits.
  static bool validIdNumber(String type, String value) => type == 'passport'
      ? RegExp(r'^[A-Za-z0-9]{6,9}$').hasMatch(value.trim())
      : RegExp(r'^(\d{9}[vVxX]|\d{12})$').hasMatch(value.trim());

  static String idNumberHint(String type) => type == 'passport'
      ? 'Passport number (6 to 9 letters or digits)'
      : 'NIC number (e.g. 928471923V or 199284719231)';

  // --------------------------------------------------------------- progress
  bool get detailsDone =>
      nameError(fullName) == null &&
      phoneError(phone) == null &&
      professionError(profession) == null &&
      yearsError(experienceYears) == null;

  bool get idDone =>
      idFront != null &&
      validIdNumber(idType, idNumber) &&
      (idType == 'passport' || idBack != null);

  bool get selfieDone => selfie != null;
  bool get qualificationsDone => cv != null && certificates.isNotEmpty;

  /// Document steps finished (of 3): ID, selfie, CV + certificates.
  int get documentStepsDone =>
      [idDone, selfieDone, qualificationsDone].where((done) => done).length;

  /// The first thing still missing, in plain words (null when it can be sent).
  String? get firstProblem {
    if (!detailsDone) return 'Complete your details first.';
    if (!requireEverything) {
      // Optional, but if an ID number is typed it must be a real one.
      if (!_blank(idNumber) && !validIdNumber(idType, idNumber)) {
        return idType == 'passport'
            ? 'Enter a valid passport number.'
            : 'Enter a valid NIC number.';
      }
      return null;
    }
    if (idFront == null) return 'Upload the front of your ID or passport.';
    if (idType == 'nic' && idBack == null) {
      return 'Upload the back of your National ID.';
    }
    if (!validIdNumber(idType, idNumber)) {
      return idType == 'passport'
          ? 'Enter a valid passport number.'
          : 'Enter a valid NIC number.';
    }
    if (!selfieDone) return 'Take your live selfie.';
    if (cv == null) return 'Upload your CV.';
    if (certificates.isEmpty) {
      return 'Upload at least one course or training certificate.';
    }
    return null;
  }

  bool get isComplete => firstProblem == null;

  /// Whether any document was chosen (so anything needs uploading).
  bool get hasDocuments =>
      idFront != null ||
      idBack != null ||
      selfie != null ||
      cv != null ||
      certificates.isNotEmpty;
}
