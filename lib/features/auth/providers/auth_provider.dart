import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
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
    final type = UserModel.parseUserType(data['accountType'] ?? data['userType'] ?? 'client');
    switch (type) {
      case UserType.workProvider:
        return _parseWorkProvider(doc.id, data);
      case UserType.marketplace:
        return _parseMarketplace(doc.id, data);
      default:
        return UserModel.fromMap(doc.id, data);
    }
  });
});

UserModel _parseWorkProvider(String id, Map<String, dynamic> data) {
  // Import lazily to avoid circular deps - use raw UserModel with workProvider type for routing
  return UserModel.fromMap(id, data);
}

UserModel _parseMarketplace(String id, Map<String, dynamic> data) {
  return UserModel.fromMap(id, data);
}

final userAccountTypeProvider = FutureProvider<UserType?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return null;
  return ref.watch(authServiceProvider).getUserType(user.uid);
});

/// Watches the custom 'verifications' collection for manual email verification
final isEmailVerifiedProvider = StreamProvider<bool>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null || user.email == null) return Stream.value(false);

  return FirebaseFirestore.instance
      .collection('verifications')
      .doc(user.email)
      .snapshots()
      .map((doc) => doc.exists && (doc.data()?['verified'] ?? false));
});
