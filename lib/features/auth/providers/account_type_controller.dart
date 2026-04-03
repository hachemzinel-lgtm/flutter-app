import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/router/route_paths.dart';
import 'auth_action_state.dart';
import 'auth_providers.dart';

final accountTypeControllerProvider =
    StateNotifierProvider.autoDispose<AccountTypeController, AuthActionState>((
      ref,
    ) {
      return AccountTypeController(ref);
    });

class AccountTypeController extends StateNotifier<AuthActionState> {
  AccountTypeController(this._ref) : super(const AuthActionState());

  final Ref _ref;

  Future<String?> saveSelection(String accountType) async {
    print('--- [ACCOUNT TYPE] Saving account type: $accountType');
    state = const AuthActionState(isLoading: true);

    try {
      final user = _ref.read(currentUserProvider);
      if (user == null) {
        throw Exception('You must be signed in to choose an account type.');
      }

      await _ref.read(userRepositoryProvider).updateUserDocument(user.uid, {
        'accountType': accountType,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      state = const AuthActionState(isLoading: false);
      return AppRoutes.setupForAccountType(accountType);
    } catch (error, stackTrace) {
      print('--- [ACCOUNT TYPE] ERROR: $error');
      print('--- [ACCOUNT TYPE] Stack trace: $stackTrace');
      state = AuthActionState(isLoading: false, errorMessage: error.toString());
      return null;
    }
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearInfo: true);
  }
}
