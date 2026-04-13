import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/router/route_paths.dart';
import 'auth_action_state.dart';
import 'auth_providers.dart';

final emailVerificationControllerProvider =
    StateNotifierProvider.autoDispose<
      EmailVerificationController,
      AuthActionState
    >((ref) {
      return EmailVerificationController(ref);
    });

class EmailVerificationController extends StateNotifier<AuthActionState> {
  EmailVerificationController(this._ref) : super(const AuthActionState());

  final Ref _ref;

  Future<void> resendEmail() async {
    state = const AuthActionState(isLoading: true);

    try {
      await _ref.read(authRepositoryProvider).sendEmailVerification();
      state = const AuthActionState(
        isLoading: false,
        infoMessage: 'Verification email sent!',
      );
    } catch (error) {
      state = AuthActionState(isLoading: false, errorMessage: error.toString());
    }
  }

  Future<String?> confirmVerification() async {
    state = const AuthActionState(isLoading: true);

    try {
      final authRepository = _ref.read(authRepositoryProvider);
      final userRepository = _ref.read(userRepositoryProvider);
      final user = authRepository.currentUser;

      if (user == null) {
        throw Exception('No authenticated user found.');
      }

      await authRepository.reloadUser();
      final isVerified = await authRepository.isEmailVerified();

      if (!isVerified) {
        state = const AuthActionState(
          isLoading: false,
          errorMessage: 'Email not verified yet. Please check your inbox.',
        );
        return null;
      }

      await userRepository.updateUserDocument(user.uid, {
        'emailVerified': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      state = const AuthActionState(isLoading: false);
      return AppRoutes.accountType;
    } catch (error) {
      state = AuthActionState(isLoading: false, errorMessage: error.toString());
      return null;
    }
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearInfo: true);
  }
}
