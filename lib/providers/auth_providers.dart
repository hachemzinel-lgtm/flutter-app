import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'package:flutter_application_1/models/client_model.dart';
import 'package:flutter_application_1/models/marketplace_model.dart';
import 'package:flutter_application_1/models/user_model.dart';
import 'package:flutter_application_1/models/work_provider_model.dart';
import 'package:flutter_application_1/services/services_google_auth_service.dart';
import 'package:flutter_application_1/services/auth_repository_impl.dart';
import 'package:flutter_application_1/services/user_repository_impl.dart';
import 'package:flutter_application_1/services/auth_repository.dart';
import 'package:flutter_application_1/services/user_repository.dart';
import 'package:flutter_application_1/services/auth_service.dart';

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

class AuthController extends StateNotifier<AsyncValue<User?>> {
  AuthController(this._auth) : super(AsyncData(_auth.currentUser)) {
    _subscription = _auth.userChanges().listen(
      (user) {
        state = AsyncData(user);
      },
      onError: (Object error, StackTrace stackTrace) {
        state = AsyncError<User?>(error, stackTrace);
      },
    );
  }

  final FirebaseAuth _auth;
  late final StreamSubscription<User?> _subscription;

  Future<User?> refreshAuthState() async {
    state = const AsyncLoading<User?>();
    try {
      await _auth.currentUser?.reload();
      final refreshedUser = _auth.currentUser;
      state = AsyncData(refreshedUser);
      return refreshedUser;
    } catch (error, stackTrace) {
      state = AsyncError<User?>(error, stackTrace);
      return null;
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final authProvider = StateNotifierProvider<AuthController, AsyncValue<User?>>((
  ref,
) {
  return AuthController(ref.read(firebaseAuthProvider));
});

final authStateProvider = Provider<AsyncValue<User?>>((ref) {
  return ref.watch(authProvider);
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authProvider);
  return authState.asData?.value ?? ref.watch(firebaseAuthProvider).currentUser;
});

final currentUserDataProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return Stream.value(null);
  }

  final snapshots =
      ref
          .watch(firestoreProvider)
          .collection('users')
          .doc(user.uid)
          .snapshots();

  return (() async* {
    try {
      await for (final doc in snapshots) {
        yield doc.data();
      }
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(error, stackTrace);
    }
  })();
});

final currentUserDocProvider = StreamProvider<UserModel?>((ref) {
  final user = ref.watch(currentUserProvider);
  final userDataState = ref.watch(currentUserDataProvider);

  if (userDataState.hasError) {
    final error = userDataState.asError!;
    Error.throwWithStackTrace(error.error, error.stackTrace);
  }

  final userData = userDataState.asData?.value;

  if (user == null || userData == null) {
    return Stream.value(null);
  }

  final rawType = userData['accountType']?.toString();
  if (rawType == null || rawType.isEmpty) {
    return Stream.value(null);
  }

  final type = UserModel.parseUserType(rawType);
  switch (type) {
    case UserType.workProvider:
      return Stream.value(WorkProviderModel.fromMap(user.uid, userData));
    case UserType.marketplace:
      return Stream.value(MarketplaceModel.fromMap(user.uid, userData));
    case UserType.client:
      return Stream.value(ClientModel.fromMap(user.uid, userData));
  }
});

final isEmailVerifiedProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider)?.emailVerified ?? false;
});

final isProfileCompleteProvider = Provider<bool>((ref) {
  final userData = ref.watch(currentUserDataProvider).value;
  return userData?['profileComplete'] == true;
});

final userAccountTypeProvider = FutureProvider<UserType?>((ref) async {
  try {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return null;
    }
    return ref.watch(authServiceProvider).getUserType(user.uid);
  } catch (error, stackTrace) {
    Error.throwWithStackTrace(error, stackTrace);
  }
});

final workProviderNeedsReviewProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserDocProvider).value;
  if (user is! WorkProviderModel) {
    return false;
  }

  return user.verificationStatus == VerificationStatus.pending.name ||
      user.verificationStatus == VerificationStatus.rejected.name;
});
