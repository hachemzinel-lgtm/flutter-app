import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/client_model.dart';
import '../../../core/models/marketplace_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/models/work_provider_model.dart';
import '../../../services/google_auth_service.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../data/repositories/user_repository_impl.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/user_repository.dart';
import '../services/auth_service.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final googleAuthServiceProvider = Provider<GoogleAuthService>((ref) {
  return GoogleAuthService(
    auth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firestoreProvider),
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    auth: ref.watch(firebaseAuthProvider),
    googleAuthService: ref.watch(googleAuthServiceProvider),
  );
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepositoryImpl(firestore: ref.watch(firestoreProvider));
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    authRepository: ref.watch(authRepositoryProvider),
    userRepository: ref.watch(userRepositoryProvider),
    firestore: ref.watch(firestoreProvider),
  );
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).value;
});

final currentUserDocProvider = StreamProvider<UserModel?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return Stream.value(null);
  }

  return ref
      .watch(firestoreProvider)
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((doc) {
        if (!doc.exists) {
          return null;
        }
        final data = doc.data() ?? <String, dynamic>{};
        final type = UserModel.parseUserType(
          data['accountType']?.toString() ??
              data['userType']?.toString() ??
              'client',
        );

        switch (type) {
          case UserType.workProvider:
            return WorkProviderModel.fromMap(doc.id, data);
          case UserType.marketplace:
            return MarketplaceModel.fromMap(doc.id, data);
          case UserType.client:
            return ClientModel.fromMap(doc.id, data);
        }
      });
});

final isEmailVerifiedProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider)?.emailVerified ?? false;
});

final isProfileCompleteProvider = Provider<bool>((ref) {
  final userDoc = ref.watch(currentUserDocProvider).value;
  return userDoc?.profileCompleted ?? false;
});

final userAccountTypeProvider = FutureProvider<UserType?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return null;
  }
  return ref.watch(authServiceProvider).getUserType(user.uid);
});

final workProviderNeedsReviewProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserDocProvider).value;
  if (user is! WorkProviderModel) {
    return false;
  }

  return user.verificationStatus == VerificationStatus.pending.name ||
      user.verificationStatus == VerificationStatus.rejected.name;
});
