/// Shared input rules. Every method returns an error message for the field,
/// or null when the value is fine, so it can be used directly as a
/// `validator:` or for an `errorText:`.
class Validators {
  Validators._();

  static final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');
  static final _name = RegExp(r"^[A-Za-zÀ-ɏ඀-෿஀-௿ .'\-]+$");
  static final _phone = RegExp(r'^(0\d{9}|\+94\d{9})$');

  static const maxName = 80;
  static const maxEmail = 254;
  static const maxPassword = 64;
  static const minPassword = 6;

  /// A person's name: letters, spaces, apostrophes, dots and hyphens only.
  static String? name(String? value, {String label = 'name'}) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Enter your $label.';
    if (text.length < 2) return 'Your $label must be at least 2 characters.';
    if (text.length > maxName) {
      return 'Your $label must be at most $maxName characters.';
    }
    if (!_name.hasMatch(text)) {
      return 'Your $label can only contain letters and spaces.';
    }
    return null;
  }

  static String? email(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Enter your email address.';
    if (text.length > maxEmail || !_email.hasMatch(text)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  /// A Sri Lankan mobile or landline number: 10 digits starting with 0
  /// (e.g. 0771234567). The international form +94771234567 is accepted too.
  static String? phone(String? value, {bool required = false}) {
    final text = (value ?? '').replaceAll(RegExp(r'[\s\-()]'), '');
    if (text.isEmpty) {
      return required ? 'Enter your phone number.' : null;
    }
    if (!_phone.hasMatch(text)) {
      return 'Enter a 10-digit number starting with 0 (e.g. 0771234567).';
    }
    return null;
  }

  static String? password(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Enter your password.';
    if (text.length < minPassword) {
      return 'Use at least $minPassword characters.';
    }
    if (text.length > maxPassword) {
      return 'Use at most $maxPassword characters.';
    }
    return null;
  }

  static String? confirmPassword(String? value, String original) =>
      value != original ? 'The passwords do not match.' : null;

  /// Required free text with a maximum length.
  static String? required(String? value, String label, {int max = 200}) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Enter $label.';
    if (text.length > max) return 'Use at most $max characters.';
    return null;
  }

  /// A positive amount (price, refund, fee) with at most two decimals.
  static String? amount(
    String? value, {
    String label = 'an amount',
    bool required = true,
    double max = 10000000,
  }) {
    final text = (value ?? '').trim().replaceAll(',', '');
    if (text.isEmpty) return required ? 'Enter $label.' : null;
    final number = double.tryParse(text);
    if (number == null || !number.isFinite) return 'Enter a valid number.';
    if (number <= 0) return 'The amount must be greater than 0.';
    if (number > max) return 'The amount is too large.';
    if (RegExp(r'\.\d{3,}$').hasMatch(text)) {
      return 'Use at most 2 decimal places.';
    }
    return null;
  }

  /// A whole number in [min]..[max], e.g. years of experience.
  static String? wholeNumber(
    String? value, {
    required String label,
    int min = 0,
    required int max,
    bool required = true,
  }) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return required ? 'Enter $label.' : null;
    final number = int.tryParse(text);
    if (number == null || number < min || number > max) {
      return 'Enter a whole number from $min to $max.';
    }
    return null;
  }

  /// Card expiry as MM/YY: a real month, not in the past.
  static String? cardExpiry(String? value, DateTime now) {
    final text = (value ?? '').trim();
    final match = RegExp(r'^(\d{2})\/(\d{2})$').firstMatch(text);
    if (match == null) return 'Format MM/YY';
    final month = int.parse(match.group(1)!);
    final year = 2000 + int.parse(match.group(2)!);
    if (month < 1 || month > 12) return 'Enter a valid month (01-12).';
    // A card works until the end of its expiry month.
    if (!DateTime(year, month + 1).isAfter(DateTime(now.year, now.month))) {
      return 'This card has expired.';
    }
    if (year > now.year + 20) return 'Enter a valid expiry year.';
    return null;
  }
}
