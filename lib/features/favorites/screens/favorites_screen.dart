import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/profile_card.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Favorites')),
      body: ListView.builder(
        padding: AppSpacing.pagePadding,
        itemCount: 3, // Mock data
        itemBuilder: (context, index) => ProfileCard(
          name: 'Alexander Sterling',
          profession: 'Master Electrician',
          rating: 4.9,
          reviewCount: 128,
          isAvailable: true,
          onTap: () => context.push('/provider-profile/mock_fav_$index'),
        ),
      ),
    );
  }
}
