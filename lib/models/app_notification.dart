import 'package:cloud_firestore/cloud_firestore.dart';

/// An in-app notification addressed to exactly one user (`recipientId`).
/// Today the only type is `review`: a customer reviewed the recipient's job.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.recipientId,
    required this.type,
    required this.bookingId,
    required this.title,
    required this.body,
    this.rating,
    this.read = false,
    this.createdAt,
  });

  final String id, recipientId, type, bookingId, title, body;
  final int? rating;
  final bool read;
  final DateTime? createdAt;

  static const reviewType = 'review';

  static AppNotification? fromMap(String id, Map<String, dynamic> data) {
    final recipientId = data['recipientId'];
    final type = data['type'];
    final bookingId = data['bookingId'];
    final title = data['title'];
    final body = data['body'];
    if (recipientId is! String ||
        type is! String ||
        bookingId is! String ||
        title is! String ||
        body is! String) {
      return null;
    }
    final created = data['createdAt'];
    final rating = data['rating'];
    return AppNotification(
      id: id,
      recipientId: recipientId,
      type: type,
      bookingId: bookingId,
      title: title,
      body: body,
      rating: rating is num ? rating.toInt() : null,
      read: data['read'] == true,
      createdAt: created is Timestamp ? created.toDate() : null,
    );
  }
}
