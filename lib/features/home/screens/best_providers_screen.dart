import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/models/work_provider_model.dart';
import '../providers/home_provider.dart';

class BestProvidersScreen extends ConsumerWidget {
  const BestProvidersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providersAsync = ref.watch(topRatedProvidersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Top Rated Near You', style: AppTextStyles.headingSmall),
      ),
      body: providersAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accentBlue),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: AppSpacing.pagePadding,
            child: Text(
              error.toString(),
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.errorRed),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (results) {
          if (results.isEmpty) {
            return Center(
              child: Padding(
                padding: AppSpacing.pagePadding,
                child: Text(
                  'No verified providers were found near your saved location yet.',
                  style: AppTextStyles.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: AppSpacing.pagePadding,
            itemCount: results.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.m),
            itemBuilder: (context, index) {
              final result = results[index];
              final provider = result.user as WorkProviderModel;
              return InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => context.push('/provider-profile/${provider.id}'),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.l),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: AppColors.accentBlue.withValues(alpha: 0.12),
                        backgroundImage: provider.photoUrl == null
                            ? null
                            : NetworkImage(provider.photoUrl!),
                        child: provider.photoUrl == null
                            ? Text(
                                provider.name.substring(0, 1).toUpperCase(),
                                style: AppTextStyles.headingSmall.copyWith(
                                  color: AppColors.accentBlue,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: AppSpacing.m),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    provider.name,
                                    style: AppTextStyles.headingSmall,
                                  ),
                                ),
                                if (result.isVerified)
                                  const Icon(
                                    Icons.verified_rounded,
                                    color: AppColors.starGold,
                                    size: 18,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              provider.profession ?? 'Work Provider',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.accentBlue,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 10,
                              runSpacing: 8,
                              children: [
                                _MetaPill(
                                  icon: Icons.star_rounded,
                                  text: provider.rating == 0
                                      ? 'New'
                                      : provider.rating.toStringAsFixed(1),
                                  color: AppColors.starGold,
                                ),
                                _MetaPill(
                                  icon: Icons.place_outlined,
                                  text: '${result.distanceKm.toStringAsFixed(1)} km',
                                  color: AppColors.accentBlue,
                                ),
                                if (provider.isAvailableNow)
                                  const _MetaPill(
                                    icon: Icons.flash_on_rounded,
                                    text: 'Available Now',
                                    color: AppColors.availableGreen,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
