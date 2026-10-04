class AppUser {
  static const customerRole = 'customer';
  static const providerRole = 'provider';

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.photoUrl,
  });

  final String uid;
  final String name;
  final String email;
  final String role;
  final String? photoUrl;

  factory AppUser.fromMap(String uid, Map<String, dynamic> data) {
    final name = data['name'];
    final email = data['email'];
    final role = data['role'];
    final photoUrl = data['photoUrl'];
    if (name is! String ||
        email is! String ||
        (role != customerRole && role != providerRole) ||
        (photoUrl != null && photoUrl is! String)) {
      throw const FormatException('The user profile is invalid.');
    }
    return AppUser(
      uid: uid,
      name: name,
      email: email,
      role: role as String,
      photoUrl: photoUrl as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'name': name,
    'email': email,
    'role': role,
    'photoUrl': photoUrl,
  };
}
