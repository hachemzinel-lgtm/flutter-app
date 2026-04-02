import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../../../core/models/client_model.dart';
import '../../../core/models/marketplace_model.dart';
import '../../../core/models/work_provider_model.dart';
import '../../../core/models/user_model.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.userChanges();
});

/// Full user document from Firestore (null = not set up yet)
final currentUserDocProvider = StreamProvider<UserModel?>((ref) {
  final authAsync = ref.watch(authStateProvider);
  final user = authAsync.value;
  if (user == null) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((doc) {
        if (!doc.exists) return null;
        final data = doc.data()!;
        final type = UserModel.parseUserType(
          data['accountType'] ?? data['userType'] ?? 'client',
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

final userAccountTypeProvider = FutureProvider<UserType?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return null;
  return ref.watch(authServiceProvider).getUserType(user.uid);
});

final isEmailVerifiedProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).value?.emailVerified ?? false;
});

final isProfileCompleteProvider = Provider<bool>((ref) {
  return ref.watch(currentUserDocProvider).value?.profileCompleted ?? false;
});

final workProviderNeedsReviewProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserDocProvider).value;
  if (user is! WorkProviderModel) {
    return false;
  }

  return user.verificationStatus == VerificationStatus.pending.name ||
      user.verificationStatus == VerificationStatus.rejected.name;
});
