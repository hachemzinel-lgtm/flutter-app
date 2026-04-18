import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

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
    List<String> imageUrls = [];
    if (portfolioImages != null) {
      for (var image in portfolioImages) {
        final ref = _storage.ref().child('portfolios/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg');
        await ref.putFile(image);
        imageUrls.add(await ref.getDownloadURL());
      }
    }

    await _firestore.collection('providers').doc(uid).set({
      'profession': profession,
      'category': category,
      'description': description,
      'experience': experience,
      'hourlyRate': hourlyRate,
      'portfolioImages': imageUrls,
      'isAvailable': true,
      'rating': 5.0,
      'reviewCount': 0,
      'workZone': workZone,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> setupMerchantProfile({
    required String uid,
    required String storeName,
    required String category,
    required String description,
    required String address,
    required Map<String, String> openingHours,
    List<File>? storeImages,
  }) async {
    List<String> imageUrls = [];
    if (storeImages != null) {
      for (var image in storeImages) {
        final ref = _storage.ref().child('stores/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg');
        await ref.putFile(image);
        imageUrls.add(await ref.getDownloadURL());
      }
    }

    await _firestore.collection('merchants').doc(uid).set({
      'storeName': storeName,
      'category': category,
      'description': description,
      'address': address,
      'openingHours': openingHours,
      'storeImages': imageUrls,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<DocumentSnapshot> getProviderData(String uid) {
    return _firestore.collection('providers').doc(uid).get();
  }

  Future<DocumentSnapshot> getMerchantData(String uid) {
    return _firestore.collection('merchants').doc(uid).get();
  }
}
