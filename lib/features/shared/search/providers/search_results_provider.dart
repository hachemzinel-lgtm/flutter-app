import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/search_filter_model.dart';

// ---------------------------------------------------------------------------
// Haversine distance (returns km)
// ---------------------------------------------------------------------------
double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
  const r = 6371.0;
  final dLat = (lat2 - lat1) * pi / 180;
  final dLon = (lon2 - lon1) * pi / 180;
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1 * pi / 180) * cos(lat2 * pi / 180) * sin(dLon / 2) * sin(dLon / 2);
  return r * 2 * atan2(sqrt(a), sqrt(1 - a));
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------
final searchResultsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, SearchFilterModel>(
  (ref, filter) async {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('users')
        .where('accountType', isEqualTo: filter.target);

    // Step 2 — verified
    if (filter.verifiedOnly && filter.target == 'work_provider') {
      query = query.where('isVerified', isEqualTo: true);
    }

    // Step 3 & 4 — availability
    if (filter.availableOnly) {
      if (filter.target == 'work_provider') {
        query = query.where('isAvailable', isEqualTo: true);
      } else {
        query = query.where('isOpen', isEqualTo: true);
      }
    }

    // Step 5 — category
    if (filter.category != null && filter.category != 'Any') {
      if (filter.target == 'work_provider') {
        query = query.where('profession', isEqualTo: filter.category);
      } else {
        query = query.where('shopCategory', isEqualTo: filter.category);
      }
    }

    final snapshot = await query.get();
    List<Map<String, dynamic>> results = snapshot.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data());
      data['uid'] = doc.id;
      return data;
    }).toList();

    // Step 6 — excludeId (client-side)
    if (filter.excludeId != null) {
      results = results.where((d) => d['uid'] != filter.excludeId).toList();
    }

    // Step 7 — distance filter (client-side Haversine)
    if (filter.isLocationSet) {
      results = results.where((d) {
        final lat = (d['latitude'] as num?)?.toDouble() ??
            (d['lat'] as num?)?.toDouble();
        final lng = (d['longitude'] as num?)?.toDouble() ??
            (d['lng'] as num?)?.toDouble();
        if (lat == null || lng == null) return false;
        final dist = _haversineKm(filter.latitude, filter.longitude, lat, lng);
        return dist <= filter.radiusKm;
      }).toList();
    }

    // Step 8 — min rating
    if (filter.minRating > 0) {
      results = results.where((d) {
        final rating = (d['averageRating'] as num?)?.toDouble() ?? 0.0;
        return rating >= filter.minRating;
      }).toList();
    }

    // Step 9 — sort by rating desc
    results.sort((a, b) {
      final rA = (a['averageRating'] as num?)?.toDouble() ?? 0.0;
      final rB = (b['averageRating'] as num?)?.toDouble() ?? 0.0;
      return rB.compareTo(rA);
    });

    return results;
  },
);
