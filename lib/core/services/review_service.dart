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
    
    final reviewRef = _firestore.collection('providers').doc(providerId).collection('reviews').doc();
    batch.set(reviewRef, {
      'reviewerId': reviewerId,
      'reviewerName': reviewerName,
      'rating': rating,
      'comment': comment,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Update aggregate rating (simplified version)
    // In a real app, use a Cloud Function for this
    final providerRef = _firestore.collection('providers').doc(providerId);
    batch.update(providerRef, {
      'rating': rating, // This would be an average in reality
      'reviewCount': FieldValue.increment(1),
    });

    await batch.commit();
  }

  Stream<QuerySnapshot> getReviews(String providerId) {
    return _firestore
        .collection('providers')
        .doc(providerId)
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
