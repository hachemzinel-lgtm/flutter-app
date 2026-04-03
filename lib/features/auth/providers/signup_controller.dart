import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/router/route_paths.dart';
import 'auth_action_state.dart';
import 'auth_providers.dart';

final signupControllerProvider =
    StateNotifierProvider.autoDispose<SignupController, AuthActionState>((ref) {
      return SignupController(ref);
    });

class SignupController extends StateNotifier<AuthActionState> {
  SignupController(this._ref) : super(const AuthActionState());

  final Ref _ref;

  Future<String?> signUp({
    required String email,
    required String password,
  }) async {
    print('--- [SIGNUP CONTROLLER] Starting signup flow');
    state = const AuthActionState(isLoading: true);

    try {
      final user = await _ref
          .read(authRepositoryProvider)
          .signUpWithEmailPassword(email, password);

      if (user == null) {
        throw Exception('Firebase did not return a valid user account.');
      }

      await _ref.read(userRepositoryProvider).createUserDocument(user.uid, {
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'emailVerified': false,
        'accountType': null,
        'profileComplete': false,
        'profileCompleted': false,
        'notificationsEnabled': true,
      });

      state = const AuthActionState(
        isLoading: false,
        infoMessage:
            'Account created successfully. Verify your email to continue.',
      );
      return AppRoutes.emailVerification;
    } catch (error, stackTrace) {
      print('--- [SIGNUP CONTROLLER] ERROR: $error');
      print('--- [SIGNUP CONTROLLER] Stack trace: $stackTrace');
      state = AuthActionState(isLoading: false, errorMessage: error.toString());
      return null;
    }
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearInfo: true);
  }
}
