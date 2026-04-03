import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/models/review_model.dart';
import '../core/models/user_model.dart';
import '../features/notifications/services/notification_service.dart';

class ReviewService {
  ReviewService({
    FirebaseFirestore? firestore,
    NotificationService? notificationService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _notificationService = notificationService ?? NotificationService();

  final FirebaseFirestore _firestore;
  final NotificationService _notificationService;

  Future<void> submitReview({
    required String targetUserId,
    required String reviewerId,
    required String reviewerName,
    required String reviewerPhoto,
    required double rating,
    required String text,
  }) async {
    if (reviewerId == targetUserId) {
      throw Exception('You cannot review your own profile.');
    }

    final reviewerSnapshot = await _firestore
        .collection('users')
        .doc(reviewerId)
        .get();
    final targetSnapshot = await _firestore
        .collection('users')
        .doc(targetUserId)
        .get();
    if (!reviewerSnapshot.exists || !targetSnapshot.exists) {
      throw Exception('The review target could not be found.');
    }

    final reviewerType = UserModel.parseUserType(
      reviewerSnapshot.data()?['accountType']?.toString() ??
          reviewerSnapshot.data()?['userType']?.toString() ??
          'client',
    );
    final targetType = UserModel.parseUserType(
      targetSnapshot.data()?['accountType']?.toString() ??
          targetSnapshot.data()?['userType']?.toString() ??
          'client',
    );

    if (reviewerType != UserType.client) {
      throw Exception('Only clients can submit reviews.');
    }
    if (targetType == UserType.client) {
      throw Exception('Clients cannot receive public marketplace reviews.');
    }

    final reviewRef = _firestore
        .collection('users')
        .doc(targetUserId)
        .collection('reviews')
        .doc(reviewerId);

    final review = ReviewModel(
      id: reviewRef.id,
      reviewerId: reviewerId,
      reviewerName: reviewerName,
      reviewerPhoto: reviewerPhoto,
      rating: rating,
      text: text,
      createdAt: DateTime.now(),
    );

    await reviewRef.set(review.toJson());
    await _refreshAggregate(targetUserId);
    await _notificationService.createNotification(
      userId: targetUserId,
      title: 'New review received',
      body: '$reviewerName left a ${rating.toStringAsFixed(1)}-star review.',
      type: 'review',
      route: '/reviews/$targetUserId',
      metadata: {'targetUserId': targetUserId},
    );
  }

  Future<void> respondToReview({
    required String targetUserId,
    required String reviewId,
    required String response,
  }) async {
    await _firestore
        .collection('users')
        .doc(targetUserId)
        .collection('reviews')
        .doc(reviewId)
        .update({'response': response.trim()});
  }

  Stream<List<ReviewModel>> getReviews(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ReviewModel.fromFirestore(doc))
              .toList(),
        );
  }

  Future<void> _refreshAggregate(String userId) async {
    final reviewsSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('reviews')
        .get();

    if (reviewsSnapshot.docs.isEmpty) {
      await _firestore.collection('users').doc(userId).update({
        'rating': 0,
        'reviewCount': 0,
      });
      return;
    }

    double total = 0;
    for (final doc in reviewsSnapshot.docs) {
      total += (doc.data()['rating'] as num?)?.toDouble() ?? 0;
    }

    final average = total / reviewsSnapshot.docs.length;
    await _firestore.collection('users').doc(userId).update({
      'rating': average,
      'reviewCount': reviewsSnapshot.docs.length,
    });
  }
}
