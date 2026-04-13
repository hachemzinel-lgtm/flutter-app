import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/router/route_paths.dart';
import 'package:flutter_application_1/core/models/user_model.dart';
import '../models/search_params.dart';

class SearchResultItem {
  final UserModel user;
  final double distance;

  SearchResultItem({required this.user, required this.distance});
}

class SearchRepository {
  double _haversineDistance(GeoPoint a, GeoPoint b) {
    const radius = 6371.0;
    final lat1 = a.latitude * pi / 180;
    final lat2 = b.latitude * pi / 180;
    final dLat = (b.latitude - a.latitude) * pi / 180;
    final dLon = (b.longitude - a.longitude) * pi / 180;
    final x =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(x), sqrt(1 - x));
    return radius * c;
  }

  Future<List<SearchResultItem>> search(
    SearchParams params, {
    required GeoPoint userLocation,
    required String currentAccountType,
    required String currentUid,
  }) async {
    final normalizedRole =
        AppRoutes.normalizeAccountType(currentAccountType) ?? 'client';
    final normalizedTarget =
        AppRoutes.normalizeAccountType(params.targetType) ?? 'marketplace';

    late final String effectiveTarget;
    late final bool excludeOwnMarketplace;

    switch (normalizedRole) {
      case 'client':
        effectiveTarget = normalizedTarget == 'workProvider'
            ? 'workProvider'
            : 'marketplace';
        excludeOwnMarketplace = false;
        break;
      case 'workProvider':
        effectiveTarget = 'marketplace';
        excludeOwnMarketplace = false;
        break;
      case 'marketplace':
        effectiveTarget = 'marketplace';
        excludeOwnMarketplace = true;
        break;
      default:
        effectiveTarget = 'marketplace';
        excludeOwnMarketplace = false;
    }

    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('users')
        .where('profileComplete', isEqualTo: true);

    if (effectiveTarget == 'workProvider') {
      query = query.where(
        'accountType',
        whereIn: ['workProvider', 'work_provider'],
      );
      if (params.availableOnly) {
        query = query.where('availabilityToggle', isEqualTo: true);
      }
    } else {
      query = query.where('accountType', isEqualTo: 'marketplace');
      if (params.availableOnly) {
        query = query.where('openStatus', isEqualTo: true);
      }
    }

    final snapshot = await query.get();
    final results = <SearchResultItem>[];

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final user = UserModel.fromJson({...data, 'uid': doc.id});

      if (excludeOwnMarketplace && user.uid == currentUid) {
        continue;
      }
      if (params.excludeUid != null && user.uid == params.excludeUid) {
        continue;
      }
      if (user.location == null) {
        continue;
      }

      final distance = _haversineDistance(userLocation, user.location!);
      if (distance > params.radius) {
        continue;
      }

      if (params.minRating > 0 && user.averageRating < params.minRating) {
        continue;
      }

      if (effectiveTarget == 'workProvider' &&
          params.verifiedOnly &&
          user.badgeVisible != true) {
        continue;
      }

      if (params.categories.isNotEmpty &&
          user.category != null &&
          !params.categories.contains(user.category)) {
        continue;
      }

      if (params.presetCategory != null &&
          user.category != params.presetCategory) {
        continue;
      }

      if (params.searchQuery != null && params.searchQuery!.isNotEmpty) {
        final queryLower = params.searchQuery!.toLowerCase();
        final nameLower = user.displayName.toLowerCase();
        final businessLower = user.businessName?.toLowerCase() ?? '';
        final descriptionLower = user.description?.toLowerCase() ?? '';
        final bioLower = user.bio?.toLowerCase() ?? '';

        if (!nameLower.contains(queryLower) &&
            !businessLower.contains(queryLower) &&
            !descriptionLower.contains(queryLower) &&
            !bioLower.contains(queryLower)) {
          continue;
        }
      }

      results.add(SearchResultItem(user: user, distance: distance));
    }

    results.sort((left, right) {
      if (effectiveTarget == 'workProvider' &&
          left.user.badgeVisible != right.user.badgeVisible) {
        return left.user.badgeVisible == true ? -1 : 1;
      }
      if (left.user.averageRating != right.user.averageRating) {
        return right.user.averageRating.compareTo(left.user.averageRating);
      }
      return left.distance.compareTo(right.distance);
    });

    return results;
  }
}
