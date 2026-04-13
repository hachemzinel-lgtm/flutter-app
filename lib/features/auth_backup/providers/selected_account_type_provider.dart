import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_application_1/core/models/user_model.dart';

// Stores the user's selected account type during onboarding
class SelectedAccountType extends Notifier<UserType> {
  @override
  UserType build() => UserType.client;

  void set(UserType type) => state = type;
}

final selectedAccountTypeProvider =
    NotifierProvider<SelectedAccountType, UserType>(SelectedAccountType.new);
