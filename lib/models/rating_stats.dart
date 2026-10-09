/// A provider's overall rating at `ratingStats/{providerId}`: the running
/// total of every customer review. It is updated in the same transaction
/// that saves a review (Firestore rules check the arithmetic), so the average
/// always reflects exactly the reviews customers have given.
class RatingStats {
  const RatingStats({required this.sum, required this.count});

  final int sum, count;

  /// Mean star rating, or null while there are no reviews.
  double? get average => count <= 0 ? null : sum / count;

  /// "4.7", the way the rating is shown on profiles and cards.
  String get label => (average ?? 0).toStringAsFixed(1);

  RatingStats plus(int rating) =>
      RatingStats(sum: sum + rating, count: count + 1);

  static RatingStats? fromMap(Map<String, dynamic>? data) {
    final sum = data?['ratingSum'];
    final count = data?['ratingCount'];
    if (sum is! num || count is! num || count < 1 || sum < count) return null;
    return RatingStats(sum: sum.toInt(), count: count.toInt());
  }
}
