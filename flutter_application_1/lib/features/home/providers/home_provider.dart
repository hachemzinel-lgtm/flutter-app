import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A stream of all active service providers from Firestore.
/// Each document should have: lat, lng, name, profession, category, rating, reviewCount, isAvailable, photoUrl, hourlyRate
final providersStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return FirebaseFirestore.instance
      .collection('providers')
      .where('isAvailable', isEqualTo: true)
      .limit(20)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) {
            final data = Map<String, dynamic>.from(doc.data());
            data['uid'] = doc.id;
            return data;
          }).toList());
});
