import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';
import 'image_upload_service.dart';

class IncorrectPasswordException implements Exception {
  const IncorrectPasswordException();
}

class NotAnAdminException implements Exception {
  const NotAnAdminException();
}

class AuthService {
  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    ImageUploadService? imageUploads,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _uploadsOverride = imageUploads;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final ImageUploadService? _uploadsOverride;
  ImageUploadService get _uploads => _uploadsOverride ?? ImageUploadService();
  Completer<void>? _registration;

  // Account creation signs in immediately. Delay that event until the profile
  // write (or cleanup) finishes so the wrapper never routes a partial account.
  Stream<User?> authStateChanges() =>
      _auth.authStateChanges().asyncMap((_) async {
        await _registration?.future;
        return _auth.currentUser;
      });

  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
    required String role,
    // Runs right after the account exists and before the app sees the new
    // session (e.g. uploading provider documents). If it throws, the new
    // account is removed again so nothing is left half created.
    Future<void> Function(User user)? onCreated,
  }) async {
    if (name.trim().isEmpty ||
        (role != AppUser.customerRole && role != AppUser.providerRole)) {
      throw ArgumentError('A name and a valid role are required.');
    }
    if (_registration != null) {
      throw StateError('Registration is already in progress.');
    }
    final completion = Completer<void>();
    _registration = completion;
    User? createdUser;
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      createdUser = credential.user!;
      final profile = AppUser(
        uid: createdUser.uid,
        name: name.trim(),
        email: createdUser.email ?? email.trim(),
        role: role,
      );
      await _firestore
          .collection('users')
          .doc(profile.uid)
          .set(profile.toMap());
      await onCreated?.call(createdUser);
      return profile;
    } catch (_) {
      if (createdUser != null) {
        // Auth and Firestore cannot share a transaction. Attempt to roll back
        // the new account, then sign out if deletion could not finish.
        try {
          await createdUser.delete();
        } catch (_) {
          await _auth.signOut();
        }
      }
      rethrow;
    } finally {
      _registration = null;
      completion.complete();
    }
  }

  Future<void> login({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Admin accounts sign in with a username. Usernames map to a fixed
  /// address, so `admin` is `admin@admin.homecare.app`; a full email also works.
  static String adminEmailFor(String username) {
    final name = username.trim().toLowerCase();
    return name.contains('@') ? name : '$name@admin.homecare.app';
  }

  /// Signs in an admin. Anyone whose account is not an admin is signed straight
  /// back out, so this screen can never be used to enter another role.
  Future<void> adminLogin({
    required String username,
    required String password,
  }) async {
    if (_registration != null) {
      throw StateError('Another sign-in is in progress.');
    }
    // Hold back the session change until the role is known, so a non-admin
    // never flashes into their own home screen from this form.
    final completion = Completer<void>();
    _registration = completion;
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: adminEmailFor(username),
        password: password,
      );
      final uid = credential.user?.uid;
      final profile = uid == null ? null : await getUserProfile(uid);
      if (profile?.role != AppUser.adminRole) {
        await _auth.signOut();
        throw const NotAnAdminException();
      }
    } finally {
      _registration = null;
      completion.complete();
    }
  }

  Future<void> logout() => _auth.signOut();

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  Future<AppUser?> getUserProfile(String uid) async {
    final snapshot = await _firestore.collection('users').doc(uid).get();
    var data = snapshot.data();
    if (data == null) return null;
    final currentUser = _auth.currentUser;
    if (currentUser?.uid == uid) {
      await currentUser!.reload();
      final refreshedEmail = _auth.currentUser?.email;
      if (refreshedEmail != null && data['email'] != refreshedEmail) {
        await snapshot.reference.update({'email': refreshedEmail});
        data = {...data, 'email': refreshedEmail};
      }
    }
    return AppUser.fromMap(snapshot.id, data);
  }

  Future<AppUser> updateProfile({
    required String uid,
    required String name,
    String? photoUrl,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty || trimmedName.length > 80) {
      throw ArgumentError('Enter a name between 1 and 80 characters.');
    }
    final updates = <String, Object>{'name': trimmedName};
    if (photoUrl != null) updates['photoUrl'] = photoUrl;
    await _firestore.collection('users').doc(uid).update(updates);
    final updated = await getUserProfile(uid);
    if (updated == null) throw StateError('The user profile was not found.');
    return updated;
  }

  Future<String> uploadProfilePhoto({
    required String uid,
    required Uint8List fileBytes,
  }) async {
    return _uploads.uploadImage(
      fileBytes,
      folder: UploadFolders.profile(uid),
      fileName: 'profile_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  Future<void> changeEmail({
    required String currentPassword,
    required String newEmail,
  }) async {
    final user = _auth.currentUser;
    final currentEmail = user?.email;
    if (user == null || currentEmail == null) {
      throw StateError('No signed-in user was found.');
    }
    final email = newEmail.trim();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      throw ArgumentError('Enter a valid email address.');
    }
    try {
      final credential = EmailAuthProvider.credential(
        email: currentEmail,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (error) {
      if (error.code == 'wrong-password' ||
          error.code == 'invalid-credential') {
        throw const IncorrectPasswordException();
      }
      rethrow;
    }
    await user.verifyBeforeUpdateEmail(email);
  }

  static String errorMessage(Object error) {
    if (error is IncorrectPasswordException) return 'Incorrect password.';
    if (error is ImageUploadException) return error.message;
    if (error is NotAnAdminException) {
      return 'This sign-in is for HomeCare admins only.';
    }
    if (error is StateError) return error.message;
    if (error is FormatException) {
      return "This account's profile is incomplete. Check the name, email and "
          'role fields in its users record.';
    }
    if (error is ArgumentError)
      return error.message?.toString() ?? 'Invalid input.';
    if (error is FirebaseException) {
      return switch (error.code) {
        'invalid-email' => 'Enter a valid email address.',
        'invalid-credential' ||
        'wrong-password' ||
        'user-not-found' => 'The email or password is incorrect.',
        'email-already-in-use' => 'An account already uses this email.',
        'weak-password' =>
          'Choose a stronger password (at least 6 characters).',
        'user-disabled' => 'This account has been disabled.',
        'too-many-requests' => 'Too many attempts. Please try again later.',
        'network-request-failed' ||
        'unavailable' => 'Check your connection and try again.',
        'unauthorized' =>
          'A document could not be uploaded. Use a PDF, Word file or photo '
              'under 10 MB.',
        'retry-limit-exceeded' ||
        'canceled' => 'The upload was interrupted. Please try again.',
        'permission-denied' =>
          'Your profile could not be accessed. Please contact support.',
        'requires-recent-login' =>
          'Please re-authenticate before changing your email.',
        _ => 'Authentication could not be completed. Please try again.',
      };
    }
    return 'Something went wrong. Please try again.';
  }
}
