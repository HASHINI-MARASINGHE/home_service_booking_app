import 'package:cloud_firestore/cloud_firestore.dart';

/// A customer's review of one completed job. The document id is the booking
/// id, so each job can be reviewed exactly once.
class Review {
  const Review({
    required this.bookingId,
    required this.customerId,
    required this.providerId,
    required this.rating,
    this.customerName = '',
    this.serviceName = '',
    this.tags = const [],
    this.comment = '',
    this.recommend,
    this.createdAt,
    this.updatedAt,
  });

  final String bookingId, customerId, providerId, customerName, serviceName;
  final int rating;
  final List<String> tags;
  final String comment;
  final bool? recommend;
  final DateTime? createdAt;

  /// Set when the customer edited the review after posting it.
  final DateTime? updatedAt;

  static const maxComment = 500;

  /// Quick "what stood out" choices, in the order the design shows them.
  static const tagOptions = [
    'On Time',
    'Polite & Professional',
    'Clean Work',
    'Fair Price',
    'Good Communication',
    'Careful with Furniture',
  ];

  static String ratingLabel(int rating) => switch (rating) {
    1 => 'Poor',
    2 => 'Fair',
    3 => 'Good',
    4 => 'Very Good',
    5 => 'Excellent',
    _ => 'Tap a star to rate',
  };

  /// Returns null for documents that are not valid reviews.
  static Review? fromMap(String id, Map<String, dynamic>? data) {
    if (data == null) return null;
    final rating = data['rating'];
    final customerId = data['customerId'];
    final providerId = data['providerId'];
    if (rating is! num ||
        rating < 1 ||
        rating > 5 ||
        customerId is! String ||
        providerId is! String) {
      return null;
    }
    final tags = data['tags'];
    final created = data['createdAt'];
    final updated = data['updatedAt'];
    return Review(
      bookingId: id,
      customerId: customerId,
      providerId: providerId,
      rating: rating.toInt(),
      customerName: data['customerName'] is String
          ? data['customerName'] as String
          : '',
      serviceName: data['serviceName'] is String
          ? data['serviceName'] as String
          : '',
      tags: tags is List ? tags.whereType<String>().toList() : const [],
      comment: data['comment'] is String ? data['comment'] as String : '',
      recommend: data['recommend'] is bool ? data['recommend'] as bool : null,
      createdAt: created is Timestamp ? created.toDate() : null,
      updatedAt: updated is Timestamp ? updated.toDate() : null,
    );
  }
}
