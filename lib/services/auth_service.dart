import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';

class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
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
    final data = snapshot.data();
    return data == null ? null : AppUser.fromMap(snapshot.id, data);
  }

  static String errorMessage(Object error) {
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
        _ => 'Authentication could not be completed. Please try again.',
      };
    }
    return 'Something went wrong. Please try again.';
  }
}
