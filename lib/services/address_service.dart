import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/address.dart';
import '../models/booking.dart';

/// Saved addresses live under `users/{uid}/addresses`, so security rules can
/// restrict every read and write to the signed-in owner.
class AddressService {
  AddressService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _authOverride = auth,
      _dbOverride = firestore;

  final FirebaseAuth? _authOverride;
  final FirebaseFirestore? _dbOverride;
  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;
  FirebaseFirestore get _db => _dbOverride ?? FirebaseFirestore.instance;

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Please log in again.');
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> _addresses(String uid) =>
      _db.collection('users').doc(uid).collection('addresses');

  static List<Address> _sorted(Iterable<Address> items) =>
      items.toList()..sort((a, b) {
        if (a.isDefault != b.isDefault) return a.isDefault ? -1 : 1;
        return (a.createdAt ?? DateTime(1970)).compareTo(
          b.createdAt ?? DateTime(1970),
        );
      });

  Stream<List<Address>> watchAddresses() {
    final uid = _uid;
    return _addresses(uid).snapshots().map(
      (snapshot) => _sorted(
        snapshot.docs.map((doc) => Address.fromMap(doc.id, doc.data())),
      ),
    );
  }

  Future<List<Address>> getAddresses() async {
    final snapshot = await _addresses(_uid).get();
    return _sorted(
      snapshot.docs.map((doc) => Address.fromMap(doc.id, doc.data())),
    );
  }

  Future<Address?> getAddress(String id) async {
    final doc = await _addresses(_uid).doc(id).get();
    final data = doc.data();
    return data == null ? null : Address.fromMap(doc.id, data);
  }

  /// Creates an address. The first address automatically becomes default,
  /// and a new default clears the flag on every other address.
  Future<String> create(AddressInput input) async {
    input.validate();
    final uid = _uid;
    final existing = await _addresses(uid).get();
    final makeDefault = input.isDefault || existing.docs.isEmpty;
    final ref = _addresses(uid).doc();
    final batch = _db.batch();
    if (makeDefault) _clearDefaults(batch, existing.docs, except: ref.id);
    batch.set(ref, {
      ...input.toMap(),
      'isDefault': makeDefault,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
    return ref.id;
  }

  Future<void> update(String id, AddressInput input) async {
    input.validate();
    final uid = _uid;
    final existing = await _addresses(uid).get();
    final current = existing.docs.where((d) => d.id == id).firstOrNull;
    if (current == null) throw StateError('This address no longer exists.');
    // The only default cannot be switched off; pick another default instead.
    final wasDefault = current.data()['isDefault'] == true;
    final makeDefault = input.isDefault || wasDefault;
    final batch = _db.batch();
    if (makeDefault) _clearDefaults(batch, existing.docs, except: id);
    batch.update(current.reference, {
      ...input.toMap(),
      'isDefault': makeDefault,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> setDefault(String id) async {
    final uid = _uid;
    final existing = await _addresses(uid).get();
    final target = existing.docs.where((d) => d.id == id).firstOrNull;
    if (target == null) throw StateError('This address no longer exists.');
    final batch = _db.batch();
    _clearDefaults(batch, existing.docs, except: id);
    batch.update(target.reference, {
      'isDefault': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  /// Upcoming bookings that use this address as their service location.
  Future<List<Booking>> linkedActiveBookings(String addressId) async {
    final snapshot = await _db
        .collection('bookings')
        .where('customerId', isEqualTo: _uid)
        .get();
    return snapshot.docs
        .map((doc) => Booking.fromMap(doc.id, doc.data()))
        .where((b) => b.addressId == addressId && b.status.isUpcoming)
        .toList()
      ..sort(
        (a, b) => (a.scheduledAt ?? DateTime(9999)).compareTo(
          b.scheduledAt ?? DateTime(9999),
        ),
      );
  }

  /// Deletes an address. Bookings that are already underway block deletion;
  /// scheduled bookings keep their address snapshot and are flagged so the
  /// customer is prompted to pick a new service location.
  Future<void> delete(Address address) async {
    final uid = _uid;
    final linked = await linkedActiveBookings(address.id);
    if (linked.any(
      (b) =>
          b.status == BookingStatus.onTheWay ||
          b.status == BookingStatus.inProgress,
    )) {
      throw StateError(
        'A professional is already on the way to this address. '
        'You can delete it after the job is finished.',
      );
    }
    final others = (await _addresses(
      uid,
    ).get()).docs.where((d) => d.id != address.id).toList();
    final batch = _db.batch();
    batch.delete(_addresses(uid).doc(address.id));
    for (final booking in linked) {
      batch.update(_db.collection('bookings').doc(booking.id), {
        'addressId': null,
        'addressNeedsUpdate': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    if (address.isDefault &&
        others.isNotEmpty &&
        others.every((d) => d.data()['isDefault'] != true)) {
      final next = _sorted(others.map((d) => Address.fromMap(d.id, d.data())))
          .first;
      batch.update(_addresses(uid).doc(next.id), {
        'isDefault': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  static void _clearDefaults(
    WriteBatch batch,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs, {
    required String except,
  }) {
    for (final doc in docs) {
      if (doc.id != except && doc.data()['isDefault'] == true) {
        batch.update(doc.reference, {
          'isDefault': false,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }
  }
}
