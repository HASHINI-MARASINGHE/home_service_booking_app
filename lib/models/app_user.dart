class AppUser {
  static const customerRole = 'customer';
  static const providerRole = 'provider';

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
  });

  final String uid;
  final String name;
  final String email;
  final String role;

  factory AppUser.fromMap(String uid, Map<String, dynamic> data) {
    final name = data['name'];
    final email = data['email'];
    final role = data['role'];
    if (name is! String ||
        email is! String ||
        (role != customerRole && role != providerRole)) {
      throw const FormatException('The user profile is invalid.');
    }
    return AppUser(uid: uid, name: name, email: email, role: role as String);
  }

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'name': name,
    'email': email,
    'role': role,
  };
}
