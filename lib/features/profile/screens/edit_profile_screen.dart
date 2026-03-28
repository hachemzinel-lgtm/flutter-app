import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import 'client_edit_profile_screen.dart';
import 'provider_edit_profile_screen.dart';
import 'marketplace_edit_profile_screen.dart';

class EditProfileScreen extends ConsumerWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userTypeAsync = ref.watch(userAccountTypeProvider);
    
    return Scaffold(
      body: userTypeAsync.when(
        data: (userType) {
          if (userType == UserType.client) {
            return const ClientEditProfileScreen();
          } else if (userType == UserType.serviceProvider) {
            return const BuilderEditProfileScreen();
          } else if (userType == UserType.marketplace) {
            return const MarketplaceEditProfileScreen();
          }
          return const Center(child: Text("Unknown account type"));
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accentBlue)),
        error: (e, st) => Center(child: Text('Error resolving profile type: $e')),
      ),
    );
  }
}
