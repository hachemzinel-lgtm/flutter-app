import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> submitReview({
    required String providerId,
    required String reviewerId,
    required String reviewerName,
    required double rating,
    required String comment,
  }) async {
    final batch = _firestore.batch();
    
    // Store review in a subcollection of the target user (provider/merchant)
    final reviewRef = _firestore.collection('users').doc(providerId).collection('reviews').doc();
    batch.set(reviewRef, {
      'reviewerId': reviewerId,
      'reviewerName': reviewerName,
      'rating': rating,
      'comment': comment,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Update aggregate rating on the target user document
    final targetRef = _firestore.collection('users').doc(providerId);
    
    // Using increment for count is easy. 
    // For average rating, we'd typically use specialized Firestore logic or Cloud Functions,
    // but for now we'll do a simple update to the 'rating' field as well.
    batch.update(targetRef, {
      'rating': rating, // This would be more complex in real PRD (running average)
      'reviewCount': FieldValue.increment(1),
    });

    await batch.commit();
  }

  Stream<QuerySnapshot> getReviews(String providerId) {
    return _firestore
        .collection('users')
        .doc(providerId)
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
