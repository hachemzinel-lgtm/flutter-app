import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:flutter_riverpod/legacy.dart';

import 'package:flutter_application_1/routes/route_paths.dart';
import 'package:flutter_application_1/services/services_notification_service.dart';
import 'package:flutter_application_1/views/auth_action_state.dart';
import 'package:flutter_application_1/providers/auth_providers.dart';

final loginControllerProvider =
    StateNotifierProvider.autoDispose<LoginController, AuthActionState>((ref) {
      return LoginController(ref);
    });

class LoginController extends StateNotifier<AuthActionState> {
  LoginController(this._ref) : super(const AuthActionState());

  final Ref _ref;

  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    print('--- [LOGIN CONTROLLER] Starting email/password login');
    state = const AuthActionState(isLoading: true);

    try {
      final user = await _ref
          .read(authRepositoryProvider)
          .signInWithEmailPassword(email, password);
      if (user == null) {
        throw Exception('Login failed. Please try again.');
      }

      if (!user.emailVerified) {
        state = const AuthActionState(isLoading: false);
        return AppRoutes.emailVerification;
      }

      final userData = await _ref
          .read(userRepositoryProvider)
          .getUserDocument(user.uid);
      final nextRoute = resolveAuthenticatedRoute(userData);
      await NotificationService.initialize();
      state = const AuthActionState(isLoading: false);
      return nextRoute;
    } catch (error, stackTrace) {
      print('--- [LOGIN CONTROLLER] ERROR: $error');
      print('--- [LOGIN CONTROLLER] Stack trace: $stackTrace');
      state = AuthActionState(isLoading: false, errorMessage: error.toString());
      return null;
    }
  }

  Future<String?> signInWithGoogle() async {
    print('--- [LOGIN CONTROLLER] Starting Google sign-in');
    state = const AuthActionState(isLoading: true);

    try {
      final user = await _ref.read(authRepositoryProvider).signInWithGoogle();
      if (user == null) {
        state = const AuthActionState(
          isLoading: false,
          infoMessage: 'Google sign-in cancelled.',
        );
        return null;
      }

      final userData = await _ref
          .read(userRepositoryProvider)
          .getUserDocument(user.uid);
      final nextRoute = resolveAuthenticatedRoute(userData);
      await NotificationService.initialize();
      state = const AuthActionState(isLoading: false);
      return nextRoute;
    } catch (error, stackTrace) {
      print('--- [LOGIN CONTROLLER] GOOGLE ERROR: $error');
      print('--- [LOGIN CONTROLLER] Stack trace: $stackTrace');
      state = AuthActionState(isLoading: false, errorMessage: error.toString());
      return null;
    }
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearInfo: true);
  }
}
