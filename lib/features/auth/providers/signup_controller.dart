import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/router/route_paths.dart';
import 'auth_providers.dart';

class SignupState {
  const SignupState({
    this.isLoading = false,
    this.errorMessage,
    this.successRoute,
  });

  final bool isLoading;
  final String? errorMessage;
  final String? successRoute;

  SignupState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    String? successRoute,
    bool clearRoute = false,
  }) {
    return SignupState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successRoute: clearRoute ? null : (successRoute ?? this.successRoute),
    );
  }
}

class SignupController extends StateNotifier<SignupState> {
  SignupController(this._ref) : super(const SignupState());

  final Ref _ref;

  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    state = const SignupState(isLoading: true);

    try {
      final user = await _ref
          .read(authRepositoryProvider)
          .signUpWithEmailPassword(email.trim(), password.trim());

      if (user == null) {
        throw Exception('Unable to create your account. Please try again.');
      }

      final userRepository = _ref.read(userRepositoryProvider);
      final userExists = await userRepository.userDocumentExists(user.uid);

      if (!userExists) {
        await userRepository.createUserDocument(user.uid, {
          'uid': user.uid,
          'email': email.trim(),
          'name': '',
          'phone': '',
          'emailVerified': false,
          'accountType': null,
          'profileComplete': false,
          'profileCompleted': false,
          'notificationsEnabled': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await userRepository.updateUserDocument(user.uid, {
          'email': email.trim(),
          'emailVerified': false,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      state = const SignupState(
        isLoading: false,
        successRoute: AppRoutes.emailVerification,
      );
    } catch (error) {
      state = SignupState(isLoading: false, errorMessage: error.toString());
    }
  }

  Future<String?> signUpWithGoogle() async {
    state = const SignupState(isLoading: true);

    try {
      final user = await _ref.read(authRepositoryProvider).signInWithGoogle();
      if (user == null) {
        state = const SignupState(isLoading: false);
        return null;
      }

      final userData = await _ref
          .read(userRepositoryProvider)
          .getUserDocument(user.uid);
      final route = resolveAuthenticatedRoute(userData);

      state = SignupState(isLoading: false, successRoute: route);
      return route;
    } catch (error) {
      state = SignupState(isLoading: false, errorMessage: error.toString());
      return null;
    }
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearRoute: true);
  }
}

final signupControllerProvider =
    StateNotifierProvider<SignupController, SignupState>((ref) {
      return SignupController(ref);
    });
