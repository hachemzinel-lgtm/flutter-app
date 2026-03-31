import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/models/review_model.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> submitReview({
    required String targetUserId,
    required String reviewerId,
    required String reviewerName,
    required String reviewerPhoto,
    required double rating,
    required String text,
  }) async {
    final docRef = _firestore.collection('users').doc(targetUserId).collection('reviews').doc();
    
    final review = ReviewModel(
      id: docRef.id,
      reviewerId: reviewerId,
      reviewerName: reviewerName,
      reviewerPhoto: reviewerPhoto,
      rating: rating,
      text: text,
      createdAt: DateTime.now(),
    );

    await docRef.set(review.toJson());

    // Update target user's aggregate rating
    await _updateUserRating(targetUserId);
  }

  Future<void> _updateUserRating(String userId) async {
    final reviewsSnapshot = await _firestore.collection('users').doc(userId).collection('reviews').get();
    
    if (reviewsSnapshot.docs.isEmpty) return;

    double totalRating = 0;
    for (var doc in reviewsSnapshot.docs) {
      totalRating += (doc.data()['rating'] as num?)?.toDouble() ?? 0.0;
    }

    final averageRating = totalRating / reviewsSnapshot.docs.length;

    await _firestore.collection('users').doc(userId).update({
      'rating': averageRating,
      'reviewCount': reviewsSnapshot.docs.length,
    });
  }

  Stream<List<ReviewModel>> getReviews(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => ReviewModel.fromFirestore(doc)).toList());
  }
}
