import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Denormalized favorite entry.
///
/// We copy a small set of provider fields into each `users/{uid}/favorites`
/// document so the list can render without a second per-provider fetch —
/// and so the UI keeps working if the underlying provider doc is
/// temporarily unreachable. The live provider doc is still the source of
/// truth; callers can re-fetch on tap.
class FavoriteEntry {
  final String providerId;
  final String name;
  final String profession;
  final String? photoUrl;
  final double rating;
  final int reviewCount;
  final bool isAvailable;

  FavoriteEntry({
    required this.providerId,
    required this.name,
    required this.profession,
    required this.rating,
    required this.reviewCount,
    required this.isAvailable,
    this.photoUrl,
  });

  factory FavoriteEntry.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return FavoriteEntry(
      providerId: doc.id,
      name: (d['name'] as String?) ?? 'Provider',
      profession: (d['profession'] as String?) ?? '',
      photoUrl: d['photoUrl'] as String?,
      rating: ((d['rating'] as num?) ?? 0).toDouble(),
      reviewCount: ((d['reviewCount'] as num?) ?? 0).toInt(),
      isAvailable: (d['isAvailable'] as bool?) ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'profession': profession,
        if (photoUrl != null) 'photoUrl': photoUrl,
        'rating': rating,
        'reviewCount': reviewCount,
        'isAvailable': isAvailable,
        'favoritedAt': FieldValue.serverTimestamp(),
      };
}

class FavoritesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _firestore.collection('users').doc(uid).collection('favorites');

  Stream<List<FavoriteEntry>> stream(String uid) {
    return _col(uid)
        .orderBy('favoritedAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(FavoriteEntry.fromDoc).toList());
  }

  Future<bool> isFavorited({required String uid, required String providerId}) async {
    final doc = await _col(uid).doc(providerId).get();
    return doc.exists;
  }

  Future<void> add({
    required String uid,
    required FavoriteEntry entry,
  }) {
    return _col(uid).doc(entry.providerId).set(entry.toJson());
  }

  Future<void> remove({required String uid, required String providerId}) {
    return _col(uid).doc(providerId).delete();
  }

  Future<void> toggle({
    required String uid,
    required FavoriteEntry entry,
  }) async {
    final docRef = _col(uid).doc(entry.providerId);
    final snap = await docRef.get();
    if (snap.exists) {
      await docRef.delete();
    } else {
      await docRef.set(entry.toJson());
    }
  }
}

final favoritesServiceProvider = Provider((ref) => FavoritesService());

final favoritesStreamProvider =
    StreamProvider.family<List<FavoriteEntry>, String>(
  (ref, uid) => ref.watch(favoritesServiceProvider).stream(uid),
);
