import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/app_user.dart';

class IncorrectPasswordException implements Exception {
  const IncorrectPasswordException();
}

class AuthService {
  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance,
      _storage = storage ?? FirebaseStorage.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
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

  Future<void> logout() => _auth.signOut();

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
    final reference = _storage.ref().child('users/$uid/profile.jpg');
    await reference.putData(
      fileBytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return reference.getDownloadURL();
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
    if (error is ArgumentError) return error.message?.toString() ?? 'Invalid input.';
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
