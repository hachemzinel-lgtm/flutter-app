import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_application_1/models/review_model.dart';
import 'package:flutter_application_1/models/user_model.dart';
import 'package:flutter_application_1/models/client_model.dart';
import 'package:flutter_application_1/models/work_provider_model.dart';
import 'package:flutter_application_1/models/marketplace_model.dart';
import 'package:flutter_application_1/providers/auth_providers.dart';

class ClientProfileStats {
  const ClientProfileStats({
    required this.activeServiceRequests,
    required this.pastBookings,
  });

  final int activeServiceRequests;
  final int pastBookings;
}

class WorkProviderProfileStats {
  const WorkProviderProfileStats({required this.completedJobs});

  final int completedJobs;
}

class MarketplaceProfileStats {
  const MarketplaceProfileStats({required this.listings});

  final int listings;
}

class EditProfileSeed {
  const EditProfileSeed({
    required this.user,
    required this.name,
    required this.phone,
    required this.address,
    required this.language,
    required this.notificationsEnabled,
    required this.bio,
    required this.hourlyRate,
    required this.availabilityEnabled,
    required this.customQuoteEnabled,
    required this.businessName,
    required this.category,
    required this.description,
    required this.alwaysOpen,
  });

  final UserModel user;
  final String name;
  final String phone;
  final String address;
  final String language;
  final bool notificationsEnabled;
  final String bio;
  final String hourlyRate;
  final bool availabilityEnabled;
  final bool customQuoteEnabled;
  final String businessName;
  final String category;
  final String description;
  final bool alwaysOpen;

  factory EditProfileSeed.fromUser(UserModel user) {
    if (user is WorkProviderModel) {
      return EditProfileSeed(
        user: user,
        name: user.name,
        phone: user.phone ?? '',
        address: user.address ?? '',
        language: user.language,
        notificationsEnabled: user.notificationsEnabled,
        bio: user.bio ?? '',
        hourlyRate: user.hourlyRate?.toString() ?? '',
        availabilityEnabled: user.isAvailableNow,
        customQuoteEnabled: user.customQuoteEnabled,
        businessName: '',
        category: user.profession ?? '',
        description: '',
        alwaysOpen: false,
      );
    }

    if (user is MarketplaceModel) {
      return EditProfileSeed(
        user: user,
        name: user.name,
        phone: user.phone ?? '',
        address: user.address ?? '',
        language: user.language,
        notificationsEnabled: user.notificationsEnabled,
        bio: '',
        hourlyRate: '',
        availabilityEnabled: user.openStatus,
        customQuoteEnabled: false,
        businessName: user.businessName ?? user.name,
        category: user.category ?? '',
        description: user.description ?? '',
        alwaysOpen: user.openingHours?['alwaysOpen'] == true,
      );
    }

    return EditProfileSeed(
      user: user,
      name: user.name,
      phone: user.phone ?? '',
      address: user.address ?? '',
      language: user.language,
      notificationsEnabled: user.notificationsEnabled,
      bio: '',
      hourlyRate: '',
      availabilityEnabled: false,
      customQuoteEnabled: false,
      businessName: '',
      category: '',
      description: '',
      alwaysOpen: false,
    );
  }
}

final profileProvider = FutureProvider.family<UserModel, String>((
  ref,
  userId,
) async {
  final snapshot =
      await ref.read(firestoreProvider).collection('users').doc(userId).get();
  final data = snapshot.data();
  if (!snapshot.exists || data == null) {
    throw Exception('Profile not found');
  }
  return _mapUser(snapshot.id, data);
});

final currentProfileProvider = FutureProvider<UserModel>((ref) async {
  final authUser = ref.watch(currentUserProvider);
  if (authUser == null) {
    throw Exception('You must be signed in to load your profile.');
  }
  return ref.watch(profileProvider(authUser.uid).future);
});

final editProfileProvider = Provider.family<EditProfileSeed, UserModel>((
  ref,
  user,
) {
  return EditProfileSeed.fromUser(user);
});

final profileReviewsProvider = FutureProvider.family<List<ReviewModel>, String>(
  (ref, userId) async {
    final snapshot =
        await ref
            .read(firestoreProvider)
            .collection('users')
            .doc(userId)
            .collection('reviews')
            .get();

    final reviews = snapshot.docs.map(ReviewModel.fromFirestore).toList();
    reviews.sort((left, right) => right.createdAt.compareTo(left.createdAt));
    return reviews.take(5).toList();
  },
);

final clientProfileStatsProvider =
    FutureProvider.family<ClientProfileStats, String>((ref, userId) async {
      final firestore = ref.read(firestoreProvider);

      final requestsSnapshot =
          await firestore
              .collection('serviceRequests')
              .where('clientId', isEqualTo: userId)
              .get();
      final bookingsSnapshot =
          await firestore
              .collection('bookings')
              .where('clientId', isEqualTo: userId)
              .get();

      final activeRequests =
          requestsSnapshot.docs.where((doc) {
            final status = doc.data()['status']?.toString().toLowerCase() ?? '';
            return const {
              'open',
              'pending',
              'active',
              'in_progress',
            }.contains(status);
          }).length;

      final pastBookings =
          bookingsSnapshot.docs.where((doc) {
            final status = doc.data()['status']?.toString().toLowerCase() ?? '';
            return const {'completed', 'cancelled', 'closed'}.contains(status);
          }).length;

      return ClientProfileStats(
        activeServiceRequests: activeRequests,
        pastBookings: pastBookings,
      );
    });

final workProviderProfileStatsProvider =
    FutureProvider.family<WorkProviderProfileStats, String>((
      ref,
      userId,
    ) async {
      final bookingsSnapshot =
          await ref
              .read(firestoreProvider)
              .collection('bookings')
              .where('providerId', isEqualTo: userId)
              .get();

      final completedJobs =
          bookingsSnapshot.docs.where((doc) {
            final status = doc.data()['status']?.toString().toLowerCase() ?? '';
            return status == 'completed';
          }).length;

      return WorkProviderProfileStats(completedJobs: completedJobs);
    });

final marketplaceProfileStatsProvider =
    FutureProvider.family<MarketplaceProfileStats, String>((ref, userId) async {
      final firestore = ref.read(firestoreProvider);
      final byOwner =
          await firestore
              .collection('listings')
              .where('ownerId', isEqualTo: userId)
              .get();

      if (byOwner.docs.isNotEmpty) {
        return MarketplaceProfileStats(listings: byOwner.docs.length);
      }

      final byMarketplace =
          await firestore
              .collection('listings')
              .where('marketplaceId', isEqualTo: userId)
              .get();

      return MarketplaceProfileStats(listings: byMarketplace.docs.length);
    });

UserModel _mapUser(String id, Map<String, dynamic> data) {
  final type = UserModel.parseUserType(
    data['accountType']?.toString() ?? data['userType']?.toString() ?? 'client',
  );

  switch (type) {
    case UserType.workProvider:
      return WorkProviderModel.fromMap(id, data);
    case UserType.marketplace:
      return MarketplaceModel.fromMap(id, data);
    case UserType.client:
      return ClientModel.fromMap(id, data);
  }
}
