import 'dart:async';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationException implements Exception {
  const LocationException(this.message, {this.canOpenSettings = false});
  final String message;
  final bool canOpenSettings;
}

/// Address fields resolved from the device's current GPS position.
class LocatedAddress {
  const LocatedAddress({
    required this.latitude,
    required this.longitude,
    this.houseNumber = '',
    this.street = '',
    this.city = '',
    this.postalCode = '',
    this.province = '',
  });

  final double latitude, longitude;
  final String houseNumber, street, city, postalCode, province;

  String get cityWithPostalCode =>
      postalCode.isEmpty ? city : '$city ($postalCode)';
}

class LocationService {
  Future<LocatedAddress> currentAddress() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationException(
        'Location services are turned off. Turn them on to use GPS.',
        canOpenSettings: true,
      );
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const LocationException(
        'Location permission was denied. You can still type your address.',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
        'Location access is blocked. Allow it in Settings to use GPS.',
        canOpenSettings: true,
      );
    }
    final Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } on TimeoutException {
      throw const LocationException(
        'We could not get a GPS fix. Move near a window and try again.',
      );
    }
    try {
      final places = await Geocoding().placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      final place = places.firstOrNull;
      return LocatedAddress(
        latitude: position.latitude,
        longitude: position.longitude,
        houseNumber: place?.subThoroughfare ?? '',
        street: place?.thoroughfare ?? place?.street ?? '',
        city: place?.locality?.isNotEmpty == true
            ? place!.locality!
            : place?.subAdministrativeArea ?? '',
        postalCode: place?.postalCode ?? '',
        province: place?.administrativeArea ?? '',
      );
    } catch (_) {
      // Coordinates are still useful for dispatch even without a street name.
      return LocatedAddress(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    }
  }

  Future<void> openSettings() async {
    if (!await Geolocator.openLocationSettings()) {
      await Geolocator.openAppSettings();
    }
  }
}
