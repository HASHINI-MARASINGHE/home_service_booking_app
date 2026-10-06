import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_notification.dart';

/// The signed-in provider's own notifications. Every query is scoped to the
/// current uid and security rules only ever serve a user their own documents.
class ProviderNotificationService {
  ProviderNotificationService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Please log in again.');
    return user.uid;
  }

  /// Newest first. A single equality query avoids a composite index, so the
  /// sort happens locally.
  Stream<List<AppNotification>> watchNotifications() => _db
      .collection('notifications')
      .where('recipientId', isEqualTo: _uid)
      .snapshots()
      .map((snapshot) {
        final items = [
          for (final doc in snapshot.docs)
            ?AppNotification.fromMap(doc.id, doc.data()),
        ];
        items.sort(
          (a, b) => (b.createdAt ?? DateTime.now()).compareTo(
            a.createdAt ?? DateTime.now(),
          ),
        );
        return items;
      });

  Stream<int> watchUnreadCount() => watchNotifications().map(
    (items) => items.where((item) => !item.read).length,
  );

  Future<void> markRead(String id) =>
      _db.collection('notifications').doc(id).update({'read': true});
}
