import 'package:cloud_firestore/cloud_firestore.dart';

/// Target collection for a review — providers or merchants share the same
/// shape (rating + reviewCount aggregate; /reviews subcollection).
enum ReviewTarget { provider, merchant }

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _collectionFor(ReviewTarget t) =>
      t == ReviewTarget.provider ? 'providers' : 'merchants';

  /// Submits a review and atomically updates the target's aggregate
  /// `rating` and `reviewCount` using a running-average formula.
  ///
  ///     newAvg = (oldAvg * oldCount + newRating) / (oldCount + 1)
  ///
  /// The previous implementation overwrote `rating` with the latest single
  /// review's score, which silently destroyed the aggregate.
  Future<void> submitReview({
    required String targetId,
    required String reviewerId,
    required String reviewerName,
    required double rating,
    required String comment,
    ReviewTarget target = ReviewTarget.provider,
  }) async {
    assert(rating >= 1 && rating <= 5, 'rating must be in [1, 5]');

    final collection = _collectionFor(target);
    final targetRef = _firestore.collection(collection).doc(targetId);
    final reviewRef = targetRef.collection('reviews').doc();

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(targetRef);

      // The target document may not yet exist for a brand-new profile; fall
      // back to neutral aggregates so the review still writes cleanly.
      final data = snap.data() ?? const <String, dynamic>{};
      final oldCount = (data['reviewCount'] as num?)?.toInt() ?? 0;
      final oldAvg = (data['rating'] as num?)?.toDouble() ?? 0.0;

      final newCount = oldCount + 1;
      final newAvg =
          oldCount == 0 ? rating : ((oldAvg * oldCount) + rating) / newCount;

      tx.set(reviewRef, {
        'reviewerId': reviewerId,
        'reviewerName': reviewerName,
        'rating': rating,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
      });

      tx.set(
        targetRef,
        {
          'rating': double.parse(newAvg.toStringAsFixed(2)),
          'reviewCount': newCount,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getReviews(
    String targetId, {
    ReviewTarget target = ReviewTarget.provider,
  }) {
    return _firestore
        .collection(_collectionFor(target))
        .doc(targetId)
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
