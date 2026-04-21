import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter_application_1/services/user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<void> createUserDocument(
    String userId,
    Map<String, dynamic> data,
  ) async {
    print('--- [USER REPOSITORY] Creating user document for $userId');
    try {
      await _firestore.collection('users').doc(userId).set(data);
    } on FirebaseException catch (error, stackTrace) {
      print('--- [USER REPOSITORY] Firestore create error: ${error.code}');
      print('--- [USER REPOSITORY] Stack trace: $stackTrace');
      throw UserRepositoryException(
        error.message ?? 'Unable to create your profile. Please try again.',
      );
    } catch (error, stackTrace) {
      print('--- [USER REPOSITORY] Unexpected create error: $error');
      print('--- [USER REPOSITORY] Stack trace: $stackTrace');
      throw const UserRepositoryException(
        'Unable to create your profile right now. Please try again.',
      );
    }
  }

  @override
  Future<Map<String, dynamic>?> getUserDocument(String userId) async {
    print('--- [USER REPOSITORY] Fetching user document for $userId');
    try {
      final snapshot = await _firestore.collection('users').doc(userId).get();
      return snapshot.data();
    } on FirebaseException catch (error, stackTrace) {
      print('--- [USER REPOSITORY] Firestore fetch error: ${error.code}');
      print('--- [USER REPOSITORY] Stack trace: $stackTrace');
      throw UserRepositoryException(
        error.message ?? 'Unable to load your account data. Please try again.',
      );
    } catch (error, stackTrace) {
      print('--- [USER REPOSITORY] Unexpected fetch error: $error');
      print('--- [USER REPOSITORY] Stack trace: $stackTrace');
      throw const UserRepositoryException(
        'Unable to load your account data right now.',
      );
    }
  }

  @override
  Future<void> updateUserDocument(
    String userId,
    Map<String, dynamic> data,
  ) async {
    print('--- [USER REPOSITORY] Updating user document for $userId');
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .set(data, SetOptions(merge: true));
    } on FirebaseException catch (error, stackTrace) {
      print('--- [USER REPOSITORY] Firestore update error: ${error.code}');
      print('--- [USER REPOSITORY] Stack trace: $stackTrace');
      throw UserRepositoryException(
        error.message ?? 'Unable to save your changes. Please try again.',
      );
    } catch (error, stackTrace) {
      print('--- [USER REPOSITORY] Unexpected update error: $error');
      print('--- [USER REPOSITORY] Stack trace: $stackTrace');
      throw const UserRepositoryException(
        'Unable to save your changes right now. Please try again.',
      );
    }
  }

  @override
  Future<bool> userDocumentExists(String userId) async {
    print('--- [USER REPOSITORY] Checking user document for $userId');
    try {
      final snapshot = await _firestore.collection('users').doc(userId).get();
      return snapshot.exists;
    } on FirebaseException catch (error, stackTrace) {
      print('--- [USER REPOSITORY] Firestore exists error: ${error.code}');
      print('--- [USER REPOSITORY] Stack trace: $stackTrace');
      throw UserRepositoryException(
        error.message ??
            'Unable to check your account state. Please try again.',
      );
    } catch (error, stackTrace) {
      print('--- [USER REPOSITORY] Unexpected exists error: $error');
      print('--- [USER REPOSITORY] Stack trace: $stackTrace');
      throw const UserRepositoryException(
        'Unable to check your account state right now.',
      );
    }
  }
}
