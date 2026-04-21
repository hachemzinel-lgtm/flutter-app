import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_application_1/models/review_model.dart';

final reviewServiceProvider = Provider<ReviewService>((ref) {
  return ReviewService();
});

class ReviewService {
  ReviewService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Returns a live stream of reviews for the given [userId], newest first.
  Stream<List<ReviewModel>> getReviews(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ReviewModel.fromFirestore(doc)).toList());
  }

  /// Submit a new review. Uses a transaction to atomically update the
  /// target user's rating and review count.
  Future<void> submitReview({
    required String targetUserId,
    required String reviewerId,
    required String reviewerName,
    required String reviewerPhoto,
    required double rating,
    required String text,
  }) async {
    final targetRef = _firestore.collection('users').doc(targetUserId);
    final newReviewRef = targetRef.collection('reviews').doc();

    await _firestore.runTransaction((transaction) async {
      final targetDoc = await transaction.get(targetRef);
      if (!targetDoc.exists) {
        throw Exception('Target user not found.');
      }

      final data = targetDoc.data()!;
      final currentCount = (data['reviewCount'] as int?) ?? 0;
      final currentRating = (data['rating'] as num?)?.toDouble() ??
          (data['averageRating'] as num?)?.toDouble() ??
          0.0;

      final newCount = currentCount + 1;
      final newRating =
          ((currentRating * currentCount) + rating) / newCount;

      transaction.set(newReviewRef, {
        'reviewerId': reviewerId,
        'reviewerName': reviewerName,
        'reviewerPhoto': reviewerPhoto,
        'rating': rating,
        'reviewText': text,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });

      transaction.update(targetRef, {
        'rating': newRating,
        'averageRating': newRating,
        'reviewCount': newCount,
      });
    });
  }

  /// Delete a review (admin-only in practice, enforced by Firestore rules).
  Future<void> deleteReview(String userId, String reviewId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('reviews')
        .doc(reviewId)
        .delete();
  }
}
