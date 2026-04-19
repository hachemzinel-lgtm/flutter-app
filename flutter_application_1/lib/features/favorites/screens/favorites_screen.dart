import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/profile_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/favorites_service.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please login')));
    }

    final favoritesAsync = ref.watch(favoritesStreamProvider(user.uid));

    return Scaffold(
      appBar: AppBar(title: const Text('My Favorites')),
      body: favoritesAsync.when(
        data: (favs) {
          if (favs.isEmpty) return _buildEmpty(context);
          return ListView.builder(
            padding: AppSpacing.pagePadding,
            itemCount: favs.length,
            itemBuilder: (context, index) {
              final f = favs[index];
              return Dismissible(
                key: Key(f.providerId),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: AppColors.errorRed,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) => ref
                    .read(favoritesServiceProvider)
                    .remove(uid: user.uid, providerId: f.providerId),
                child: ProfileCard(
                  name: f.name,
                  profession: f.profession,
                  photoUrl: f.photoUrl,
                  rating: f.rating,
                  reviewCount: f.reviewCount,
                  isAvailable: f.isAvailable,
                  onTap: () =>
                      context.push('/provider-profile/${f.providerId}'),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Could not load favorites: $e',
              style: AppTextStyles.bodyMedium),
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.pagePadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite_border,
                size: 80, color: AppColors.softGray),
            const SizedBox(height: 16),
            Text('No favorites yet', style: AppTextStyles.headingSmall),
            const SizedBox(height: 8),
            Text(
              'Save providers you like to find them here later.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
