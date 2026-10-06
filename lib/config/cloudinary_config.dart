/// Cloudinary settings for image uploads. These are public identifiers, not
/// credentials, so they are safe to commit. Uploads use an *unsigned* preset:
/// never add a Cloudinary API key or API secret to this app.
abstract final class CloudinaryConfig {
  static const cloudName = 'dclo5pyll';

  /// Unsigned preset with no fixed asset folder; the app sends the folder.
  static const uploadPreset = 'homecare_unsigned';

  static final uploadUrl = Uri.parse(
    'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
  );

  /// Prefix of every URL Cloudinary returns for this account.
  static const deliveryUrlPrefix = 'https://res.cloudinary.com/$cloudName/';
}

/// The only Cloudinary folders the app uploads into. Add new ones here.
abstract final class UploadFolders {
  /// Customer issue photos for one booking.
  static String booking(String bookingId) => 'bookings/$bookingId';

  /// A provider's verification documents (ID, selfie, CV, certificates).
  static String providerDocs(String uid) => 'provider_docs/$uid';

  /// A user's profile photo.
  static String profile(String uid) => 'profiles/$uid';

  /// Anything that doesn't belong to one of the folders above.
  static const misc = 'misc';
}
