import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_application_1/views/app_colors.dart';
import 'package:flutter_application_1/models/client_model.dart';
import 'package:flutter_application_1/models/marketplace_model.dart';
import 'package:flutter_application_1/models/work_provider_model.dart';
import 'package:flutter_application_1/providers/profile_provider.dart';
import 'package:flutter_application_1/views/client_edit_profile_screen.dart';
import 'package:flutter_application_1/providers/provider_edit_profile_screen.dart';
import 'package:flutter_application_1/views/marketplace_edit_profile_screen.dart';

class EditProfileScreen extends ConsumerWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);

    return Scaffold(
      body: profileAsync.when(
        data: (user) {
          ref.watch(editProfileProvider(user));

          if (user is ClientModel) {
            return ClientEditProfileScreen(initialUser: user);
          }
          if (user is WorkProviderModel) {
            return ProviderEditProfileScreen(initialUser: user);
          }
          if (user is MarketplaceModel) {
            return MarketplaceEditProfileScreen(initialUser: user);
          }
          return const Center(child: Text('Unknown account type'));
        },
        loading:
            () => const Center(
              child: CircularProgressIndicator(color: AppColors.accentBlue),
            ),
        error: (e, st) => const Center(child: Text('Could not load profile')),
      ),
    );
  }
}
