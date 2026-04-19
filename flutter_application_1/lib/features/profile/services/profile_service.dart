import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Creates or updates the provider profile. Critically: does NOT touch
  /// `rating` / `reviewCount` if the document already exists, so the running
  /// aggregate maintained by [ReviewService] is never clobbered.
  Future<void> setupProviderProfile({
    required String uid,
    required String profession,
    required String category,
    required String description,
    required int experience,
    double? hourlyRate,
    List<File>? portfolioImages,
    required GeoPoint workZone,
  }) async {
    final imageUrls = await _uploadAll(
      files: portfolioImages,
      pathPrefix: 'portfolios/$uid',
    );

    final docRef = _firestore.collection('providers').doc(uid);
    final existing = await docRef.get();
    final isNew = !existing.exists;

    final payload = <String, dynamic>{
      'profession': profession,
      'category': category,
      'description': description,
      'experience': experience,
      'hourlyRate': hourlyRate,
      if (imageUrls.isNotEmpty) 'portfolioImages': imageUrls,
      'isAvailable': true,
      'workZone': workZone,
      'lat': workZone.latitude,
      'lng': workZone.longitude,
      'updatedAt': FieldValue.serverTimestamp(),
      // Only seed aggregates the FIRST time the doc is created; subsequent
      // calls must leave them alone to preserve the running average.
      if (isNew) ...{
        'rating': 0.0,
        'reviewCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      },
    };

    await docRef.set(payload, SetOptions(merge: true));

    // Keep the users/{uid} master doc in sync so other screens (settings,
    // chat, reviews) can render a consistent view.
    await _firestore.collection('users').doc(uid).set({
      'userType': 'serviceProvider',
      'profession': profession,
      'hasCompletedSetup': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Creates or updates the merchant profile without stomping aggregates.
  Future<void> setupMerchantProfile({
    required String uid,
    required String storeName,
    required String category,
    required String description,
    required String address,
    required Map<String, String> openingHours,
    GeoPoint? location,
    List<File>? storeImages,
  }) async {
    final imageUrls = await _uploadAll(
      files: storeImages,
      pathPrefix: 'stores/$uid',
    );

    final docRef = _firestore.collection('merchants').doc(uid);
    final existing = await docRef.get();
    final isNew = !existing.exists;

    final payload = <String, dynamic>{
      'storeName': storeName,
      'category': category,
      'description': description,
      'address': address,
      'openingHours': openingHours,
      if (imageUrls.isNotEmpty) 'storeImages': imageUrls,
      if (location != null) ...{
        'location': location,
        'lat': location.latitude,
        'lng': location.longitude,
      },
      'updatedAt': FieldValue.serverTimestamp(),
      if (isNew) ...{
        'rating': 0.0,
        'reviewCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      },
    };

    await docRef.set(payload, SetOptions(merge: true));

    await _firestore.collection('users').doc(uid).set({
      'userType': 'marketplace',
      'storeName': storeName,
      'hasCompletedSetup': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Stream of the provider doc — lets screens react to profile edits live
  /// and to aggregate updates from reviews.
  Stream<DocumentSnapshot<Map<String, dynamic>>> providerStream(String uid) {
    return _firestore.collection('providers').doc(uid).snapshots();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getProviderData(String uid) {
    return _firestore.collection('providers').doc(uid).get();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getMerchantData(String uid) {
    return _firestore.collection('merchants').doc(uid).get();
  }

  // ─── Internal ──────────────────────────────────────────────────────────
  Future<List<String>> _uploadAll({
    required List<File>? files,
    required String pathPrefix,
  }) async {
    if (files == null || files.isEmpty) return const [];
    final urls = <String>[];
    for (final file in files) {
      final ref = _storage
          .ref()
          .child('$pathPrefix/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(file);
      urls.add(await ref.getDownloadURL());
    }
    return urls;
  }
}
