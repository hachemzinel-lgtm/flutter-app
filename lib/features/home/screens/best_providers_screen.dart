import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/models/user_model.dart';

final _bestProvidersProvider = FutureProvider<List<UserModel>>((ref) async {
  final snap = await FirebaseFirestore.instance
      .collection('users')
      .where('accountType', isEqualTo: 'workProvider')
      .where('verificationStatus', isEqualTo: 'approved')
      .where('isBanned', isEqualTo: false)
      .orderBy('rating', descending: true)
      .limit(20)
      .get();
  return snap.docs
      .map((d) => UserModel.fromMap(d.id, d.data()))
      .toList();
});

class BestProvidersScreen extends ConsumerWidget {
  const BestProvidersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providersAsync = ref.watch(_bestProvidersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Top Rated Providers', style: AppTextStyles.headingSmall),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: providersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accentBlue)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (providers) {
          if (providers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.people_outline, size: 64, color: AppColors.softGray),
                  const SizedBox(height: AppSpacing.l),
                  Text('No providers found', style: AppTextStyles.headingSmall.copyWith(color: AppColors.softGray)),
                  const SizedBox(height: AppSpacing.s),
                  Text('Be the first verified provider in your area!', style: AppTextStyles.bodyMedium),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.l),
            itemCount: providers.length,
            itemBuilder: (context, i) {
              final p = providers[i];
              final data = p.toJson();
              final profession = data['profession'] as String? ?? '';
              final isAvailable = data['isAvailableNow'] as bool? ?? false;
              return _ProviderCard(
                provider: p,
                profession: profession,
                isAvailable: isAvailable,
                rank: i + 1,
                onTap: () => context.push('/provider-profile/${p.id}'),
              );
            },
          );
        },
      ),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  final UserModel provider;
  final String profession;
  final bool isAvailable;
  final int rank;
  final VoidCallback onTap;

  const _ProviderCard({
    required this.provider,
    required this.profession,
    required this.isAvailable,
    required this.rank,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.m),
        padding: const EdgeInsets.all(AppSpacing.l),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            // Rank
            if (rank <= 3)
              Container(
                width: 28,
                height: 28,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: [
                    const Color(0xFFFFD700),
                    const Color(0xFFC0C0C0),
                    const Color(0xFFCD7F32),
                  ][rank - 1].withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text('$rank',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: [
                          const Color(0xFFD4AF37),
                          const Color(0xFF999999),
                          const Color(0xFFCD7F32),
                        ][rank - 1],
                      )),
                ),
              ),
            // Avatar
            Stack(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                  child: ClipOval(
                    child: provider.photoUrl != null
                        ? CachedNetworkImage(imageUrl: provider.photoUrl!, fit: BoxFit.cover)
                        : Container(
                            color: AppColors.accentBlue.withOpacity(0.1),
                            child: Center(
                              child: Text(
                                provider.name.isNotEmpty ? provider.name[0].toUpperCase() : '?',
                                style: const TextStyle(
                                    color: AppColors.accentBlue,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 20),
                              ),
                            ),
                          ),
                  ),
                ),
                // Online dot
                if (isAvailable)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.availableGreen,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                          child: Text(provider.name,
                              style: AppTextStyles.bodyMedium
                                  .copyWith(fontWeight: FontWeight.w700),
                              overflow: TextOverflow.ellipsis)),
                      const Icon(Icons.verified_rounded,
                          color: AppColors.starGold, size: 16),
                    ],
                  ),
                  if (profession.isNotEmpty)
                    Text(profession,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.accentBlue)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          color: AppColors.starGold, size: 14),
                      const SizedBox(width: 2),
                      Text(
                        provider.rating > 0
                            ? '${provider.rating.toStringAsFixed(1)} · ${provider.reviewCount} reviews'
                            : 'New provider',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.softGray),
          ],
        ),
      ),
    );
  }
}
