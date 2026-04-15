import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Provider, Ref;
import 'package:flutter_riverpod/legacy.dart';

import 'package:flutter_application_1/providers/auth_providers.dart';
import 'package:flutter_application_1/routes/route_paths.dart';

class UserMigrationState {
  const UserMigrationState({
    this.isRunning = false,
    this.completedUid,
    this.errorMessage,
  });

  final bool isRunning;
  final String? completedUid;
  final String? errorMessage;

  UserMigrationState copyWith({
    bool? isRunning,
    String? completedUid,
    String? errorMessage,
    bool clearError = false,
  }) {
    return UserMigrationState(
      isRunning: isRunning ?? this.isRunning,
      completedUid: completedUid ?? this.completedUid,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class UserMigrationService {
  UserMigrationService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<void> cleanupDuplicateProfileField(String userId) async {
    final snapshot = await _firestore.collection('users').doc(userId).get();
    if (!snapshot.exists) {
      return;
    }

    final data = snapshot.data() ?? <String, dynamic>{};
    final updates = <String, dynamic>{};
    final rawAccountType = data['accountType']?.toString();
    final normalizedAccountType = AppRoutes.normalizeAccountType(
      rawAccountType,
    );

    if (data.containsKey('profileCompleted')) {
      updates['profileCompleted'] = FieldValue.delete();
    }

    final derivedProfileComplete = _deriveProfileComplete(
      accountType: normalizedAccountType,
      data: data,
    );
    if (data['profileComplete'] != derivedProfileComplete) {
      updates['profileComplete'] = derivedProfileComplete;
    }

    final emailVerified = _auth.currentUser?.emailVerified == true;
    if (data['emailVerified'] != emailVerified) {
      updates['emailVerified'] = emailVerified;
    }

    if (updates.isNotEmpty) {
      await _firestore
          .collection('users')
          .doc(userId)
          .set(updates, SetOptions(merge: true));
    }
  }

  bool _deriveProfileComplete({
    required String? accountType,
    required Map<String, dynamic> data,
  }) {
    final current = data['profileComplete'] == true;
    if (current) {
      return true;
    }

    switch (accountType) {
      case 'admin':
        return true;
      case 'client':
        return (_hasText(data['name']) || _hasText(data['displayName'])) &&
            (_hasText(data['city']) || data['location'] is GeoPoint);
      case 'workProvider':
        return (_hasText(data['name']) || _hasText(data['displayName'])) &&
            _hasText(data['phone']) &&
            (_hasText(data['profession']) || _hasText(data['category'])) &&
            data['location'] is GeoPoint;
      case 'marketplace':
        return _hasText(data['businessName']) &&
            _hasText(data['phone']) &&
            _hasText(data['category']) &&
            data['location'] is GeoPoint;
      default:
        return false;
    }
  }

  bool _hasText(Object? value) {
    return value is String && value.trim().isNotEmpty;
  }
}

class UserMigrationController extends StateNotifier<UserMigrationState> {
  UserMigrationController(this._ref, this._service)
    : super(const UserMigrationState());

  final Ref _ref;
  final UserMigrationService _service;

  Future<void> cleanupDuplicateProfileField() async {
    final user = _ref.read(authStateProvider).value;
    if (user == null) {
      state = const UserMigrationState();
      return;
    }

    if (state.completedUid == user.uid && !state.isRunning) {
      return;
    }

    state = UserMigrationState(
      isRunning: true,
      completedUid: state.completedUid,
    );
    try {
      await _service.cleanupDuplicateProfileField(user.uid);
      state = UserMigrationState(isRunning: false, completedUid: user.uid);
    } catch (error) {
      print('--- [USER MIGRATION] ERROR: $error');
      state = UserMigrationState(
        isRunning: false,
        completedUid: user.uid,
        errorMessage: error.toString(),
      );
    }
  }

  void reset() {
    state = const UserMigrationState();
  }
}

final userMigrationServiceProvider = Provider<UserMigrationService>((ref) {
  return UserMigrationService(
    firestore: ref.read(firestoreProvider),
    auth: ref.read(firebaseAuthProvider),
  );
});

final userMigrationControllerProvider =
    StateNotifierProvider<UserMigrationController, UserMigrationState>((ref) {
      return UserMigrationController(
        ref,
        ref.read(userMigrationServiceProvider),
      );
    });
