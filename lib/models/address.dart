import 'package:cloud_firestore/cloud_firestore.dart';

enum AddressType {
  home('Home', 'Residential'),
  office('Office', 'Workplace'),
  parents('Parents', 'Family'),
  other('Other', null);

  const AddressType(this.label, this.category);

  final String label;

  /// Filter chip on My Addresses that includes this type (`null` = All only).
  final String? category;

  static AddressType parse(Object? value) => AddressType.values.firstWhere(
    (type) => type.name == value,
    orElse: () => AddressType.other,
  );

  static const categories = ['Residential', 'Workplace', 'Family'];
}

/// A saved service location stored at `users/{uid}/addresses/{id}`.
class Address {
  const Address({
    required this.id,
    required this.type,
    required this.label,
    required this.houseNumber,
    required this.street,
    required this.city,
    this.postalCode = '',
    this.province = '',
    this.landmark = '',
    this.accessNotes = '',
    this.latitude,
    this.longitude,
    this.isDefault = false,
    this.createdAt,
    this.updatedAt,
  });

  final String id, label, houseNumber, street, city, postalCode, province;
  final String landmark, accessNotes;
  final AddressType type;
  final double? latitude, longitude;
  final bool isDefault;
  final DateTime? createdAt, updatedAt;

  static const maxNotes = 200;

  /// `No. 42 Galle Road, Colombo 03`
  String get line {
    final parts = [
      [houseNumber, street].where((p) => p.trim().isNotEmpty).join(' '),
      city,
    ].where((p) => p.trim().isNotEmpty);
    return parts.join(', ');
  }

  /// `No. 42 Galle Road, Colombo 03, Western Province`
  String get fullAddress =>
      [line, province].where((p) => p.trim().isNotEmpty).join(', ');

  /// `Colombo 03 • Western Province`
  String get area =>
      [city, province].where((p) => p.trim().isNotEmpty).join(' • ');

  /// Value shown in the single "City / Postal Code" field.
  String get cityWithPostalCode =>
      postalCode.isEmpty ? city : '$city ($postalCode)';

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return [
      label,
      fullAddress,
      landmark,
      postalCode,
      type.label,
    ].any((field) => field.toLowerCase().contains(q));
  }

  static String _text(Object? value) => value is String ? value : '';
  static double? _coordinate(Object? value) =>
      value is num && value.isFinite ? value.toDouble() : null;
  static DateTime? _date(Object? value) =>
      value is Timestamp ? value.toDate() : null;

  factory Address.fromMap(String id, Map<String, dynamic> data) {
    final type = AddressType.parse(data['type']);
    final label = _text(data['label']).trim();
    return Address(
      id: id,
      type: type,
      label: label.isEmpty ? type.label : label,
      houseNumber: _text(data['houseNumber']),
      street: _text(data['street']),
      city: _text(data['city']),
      postalCode: _text(data['postalCode']),
      province: _text(data['province']),
      landmark: _text(data['landmark']),
      accessNotes: _text(data['accessNotes']),
      latitude: _coordinate(data['latitude']),
      longitude: _coordinate(data['longitude']),
      isDefault: data['isDefault'] == true,
      createdAt: _date(data['createdAt']),
      updatedAt: _date(data['updatedAt']),
    );
  }
}

/// Validated form values for creating or updating an [Address].
class AddressInput {
  AddressInput({
    required this.type,
    required String label,
    required String houseNumber,
    required String street,
    required String cityAndPostalCode,
    String province = '',
    String landmark = '',
    String accessNotes = '',
    this.latitude,
    this.longitude,
    this.isDefault = false,
  }) : label = label.trim(),
       houseNumber = houseNumber.trim(),
       street = street.trim(),
       province = province.trim(),
       landmark = landmark.trim(),
       accessNotes = accessNotes.trim(),
       city = splitCityAndPostalCode(cityAndPostalCode).$1,
       postalCode = splitCityAndPostalCode(cityAndPostalCode).$2;

  final AddressType type;
  final String label, houseNumber, street, city, postalCode, province;
  final String landmark, accessNotes;
  final double? latitude, longitude;
  final bool isDefault;

  /// `Colombo 03 (00300)` → (`Colombo 03`, `00300`). Sri Lankan postal codes
  /// are five digits; anything else is kept as part of the city.
  static (String, String) splitCityAndPostalCode(String value) {
    final text = value.trim();
    final bracketed = RegExp(r'^(.*?)[\s,]*\((\d{5})\)$').firstMatch(text);
    if (bracketed != null) return (bracketed[1]!.trim(), bracketed[2]!);
    final trailing = RegExp(r'^(.*?)[\s,]+(\d{5})$').firstMatch(text);
    if (trailing != null) return (trailing[1]!.trim(), trailing[2]!);
    return (text, '');
  }

  void validate() {
    if (houseNumber.isEmpty || street.isEmpty || city.isEmpty) {
      throw ArgumentError('House number, street and city are required.');
    }
    if (label.length > 60 ||
        houseNumber.length > 80 ||
        street.length > 120 ||
        city.length > 80 ||
        province.length > 80 ||
        landmark.length > 120 ||
        accessNotes.length > Address.maxNotes) {
      throw ArgumentError('One of the address fields is too long.');
    }
  }

  Map<String, dynamic> toMap() => {
    'type': type.name,
    'label': label.isEmpty ? type.label : label,
    'houseNumber': houseNumber,
    'street': street,
    'city': city,
    'postalCode': postalCode,
    'province': province,
    'landmark': landmark,
    'accessNotes': accessNotes,
    'latitude': latitude,
    'longitude': longitude,
    'isDefault': isDefault,
  };
}
