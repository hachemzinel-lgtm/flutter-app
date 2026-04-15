import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_application_1/models/user_model.dart';
import 'package:flutter_application_1/services/services_notification_service.dart';
import 'package:flutter_application_1/providers/auth_provider.dart';
import 'package:flutter_application_1/routes/route_paths.dart';

final adminServiceProvider = Provider<AdminService>((ref) {
  return AdminService(
    notificationService: ref.read(notificationServiceProvider),
  );
});

final isAdminProvider = FutureProvider<bool>((ref) async {
  try {
    final userData = await ref.watch(currentUserDataProvider.future);
    return AppRoutes.isAdminAccountType(userData?['accountType']?.toString());
  } catch (error, stackTrace) {
    Error.throwWithStackTrace(error, stackTrace);
  }
});

class AdminService {
  AdminService({
    FirebaseFirestore? firestore,
    NotificationService? notificationService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _notificationService = notificationService ?? NotificationService();

  final FirebaseFirestore _firestore;
  final NotificationService _notificationService;

  Future<bool> isAdminUser(User? authUser) async {
    if (authUser == null) {
      return false;
    }

    try {
      final userDoc =
          await _firestore.collection('users').doc(authUser.uid).get();
      return AppRoutes.isAdminAccountType(
        userDoc.data()?['accountType']?.toString(),
      );
    } catch (_) {
      return false;
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchUsers() {
    return _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchPendingVerifications() {
    return _firestore
        .collection('users')
        .where('accountType', isEqualTo: UserType.workProvider.name)
        .where('verificationStatus', isEqualTo: 'pending')
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchReports() {
    return _firestore
        .collection('reports')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchReviews() {
    return _firestore
        .collectionGroup('reviews')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<Map<String, dynamic>> getPlatformStats() async {
    final usersSnapshot = await _firestore.collection('users').get();
    final conversationsSnapshot =
        await _firestore.collection('conversations').get();
    final reportsSnapshot = await _firestore.collection('reports').get();
    final reviewsSnapshot = await _firestore.collectionGroup('reviews').get();

    var clientCount = 0;
    var providerCount = 0;
    var marketplaceCount = 0;
    var bannedCount = 0;
    var pendingVerificationCount = 0;

    final professionCounts = <String, int>{};
    for (final doc in usersSnapshot.docs) {
      final data = doc.data();
      final type = UserModel.parseUserType(
        data['accountType']?.toString() ??
            data['userType']?.toString() ??
            'client',
      );
      switch (type) {
        case UserType.client:
          clientCount++;
          break;
        case UserType.workProvider:
          providerCount++;
          final profession = data['profession']?.toString().trim();
          if (profession != null && profession.isNotEmpty) {
            professionCounts[profession] =
                (professionCounts[profession] ?? 0) + 1;
          }
          break;
        case UserType.marketplace:
          marketplaceCount++;
          break;
      }

      if (data['isBanned'] == true) {
        bannedCount++;
      }
      if (data['verificationStatus'] == 'pending') {
        pendingVerificationCount++;
      }
    }

    var averageRating = 0.0;
    if (usersSnapshot.docs.isNotEmpty) {
      double ratingTotal = 0;
      int ratingUsers = 0;
      for (final doc in usersSnapshot.docs) {
        final rating = (doc.data()['rating'] as num?)?.toDouble() ?? 0;
        if (rating > 0) {
          ratingTotal += rating;
          ratingUsers++;
        }
      }
      if (ratingUsers > 0) {
        averageRating = ratingTotal / ratingUsers;
      }
    }

    var topProfession = 'N/A';
    var topProfessionCount = 0;
    professionCounts.forEach((profession, pCount) {
      if (pCount > topProfessionCount) {
        topProfession = profession;
        topProfessionCount = pCount;
      }
    });

    return <String, dynamic>{
      'totalUsers': usersSnapshot.size,
      'clients': clientCount,
      'providers': providerCount,
      'marketplaces': marketplaceCount,
      'bannedUsers': bannedCount,
      'pendingVerifications': pendingVerificationCount,
      'totalMessages': conversationsSnapshot.docs.fold<int>(
        0,
        (total, doc) =>
            total + ((doc.data()['messageCount'] as num?)?.toInt() ?? 0),
      ),
      'totalConversations': conversationsSnapshot.size,
      'totalReports': reportsSnapshot.size,
      'totalReviews': reviewsSnapshot.size,
      'topProfessionCount': topProfessionCount,
      'averageRatingX100': (averageRating * 100).round(),
      'topProfession': topProfession,
    };
  }

  Future<void> setUserBanState({
    required String userId,
    required bool isBanned,
    required String reason,
  }) async {
    await _firestore.collection('users').doc(userId).set({
      'isBanned': isBanned,
      'banReason': reason,
      'bannedAt': isBanned ? FieldValue.serverTimestamp() : null,
    }, SetOptions(merge: true));

    await _notificationService.createNotification(
      userId: userId,
      title: isBanned ? 'Account restricted' : 'Account restored',
      body:
          isBanned
              ? 'Your account has been restricted. Reason: $reason'
              : 'Your account access has been restored.',
      type: 'system',
      route: '/profile',
    );
  }

  Future<void> reviewVerification({
    required String userId,
    required bool approved,
    required String reason,
  }) async {
    await _firestore.collection('users').doc(userId).set({
      'verificationStatus': approved ? 'approved' : 'rejected',
      'verificationReason': reason,
      'isVerified': approved,
      'verifiedAt': approved ? FieldValue.serverTimestamp() : null,
    }, SetOptions(merge: true));

    await _notificationService.createNotification(
      userId: userId,
      title: approved ? 'Documents approved' : 'Documents need attention',
      body:
          approved
              ? 'Your verification documents were approved.'
              : 'Your verification documents were rejected. $reason',
      type: 'verification',
      route: '/profile',
    );
  }

  Future<void> resolveReport({
    required String reportId,
    required String status,
    String? adminAction,
  }) {
    return _firestore.collection('reports').doc(reportId).set({
      'status': status,
      'adminAction': adminAction,
      'resolvedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteUserProfile(String userId) async {
    await _firestore.collection('users').doc(userId).delete();
  }

  Future<void> deleteReview(String reviewPath) async {
    await _firestore.doc(reviewPath).delete();
  }
}
