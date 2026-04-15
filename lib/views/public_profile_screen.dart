import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_application_1/models/user_model.dart';
import 'package:flutter_application_1/providers/provider_profile_screen.dart';
import 'package:flutter_application_1/providers/profile_provider.dart';
import 'package:flutter_application_1/views/client_profile_screen.dart';
import 'package:flutter_application_1/views/marketplace_profile_screen.dart';

class PublicProfileScreen extends ConsumerWidget {
  const PublicProfileScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider(userId));

    return profile.when(
      data: (user) {
        switch (user.userType) {
          case UserType.workProvider:
            return ProviderProfileScreen(id: userId);
          case UserType.marketplace:
            return MarketplaceProfileScreen(id: userId);
          case UserType.client:
            return ClientProfileScreen(uid: userId);
        }
      },
      loading:
          () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
      error:
          (e, _) => const Scaffold(
            body: Center(child: Text('Could not load profile')),
          ),
    );
  }
}
