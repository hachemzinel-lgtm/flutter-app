import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:flutter_application_1/core/models/user_model.dart';
import 'merchant_profile_screen.dart';
import 'provider_profile_screen.dart';

class PublicProfileScreen extends StatelessWidget {
  const PublicProfileScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data!.data();
        if (data == null) {
          return const Scaffold(
            body: Center(child: Text('Profile not found.')),
          );
        }

        final type = UserModel.parseUserType(
          data['accountType']?.toString() ??
              data['userType']?.toString() ??
              'client',
        );

        switch (type) {
          case UserType.workProvider:
            return ProviderProfileScreen(uid: userId);
          case UserType.marketplace:
            return MerchantProfileScreen(uid: userId);
          case UserType.client:
            return const Scaffold(
              body: Center(
                child: Text(
                  'Client profiles are only available to the account owner.',
                ),
              ),
            );
        }
      },
    );
  }
}
