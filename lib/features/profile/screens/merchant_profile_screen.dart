import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/section_card.dart';
import '../providers/profile_provider.dart';

class MerchantProfileScreen extends ConsumerWidget {
  final String uid;
  const MerchantProfileScreen({super.key, required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final merchantAsync = ref.watch(merchantDataProvider(uid));

    return Scaffold(
      backgroundColor: Colors.white,
      body: merchantAsync.when(
        data: (doc) {
          if (!doc.exists) return const Center(child: Text('Store not found'));
          final data = doc.data() as Map<String, dynamic>;
          
          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(context, data),
              SliverToBoxAdapter(
                child: Padding(
                  padding: AppSpacing.pagePadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['storeName'] ?? 'Merchant Store', style: AppTextStyles.headingLarge),
                      Text(data['category'] ?? 'Category', style: AppTextStyles.bodyMedium),
                      const SizedBox(height: AppSpacing.xl),
                      
                      SectionCard(
                        title: 'Store Details',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _detailRow(Icons.location_on_outlined, data['address'] ?? 'No address'),
                            const SizedBox(height: 12),
                            _detailRow(Icons.access_time, 'Open Now (Closes at 18:00)'),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.l),

                      SectionCard(
                        title: 'About the Store',
                        child: Text(data['description'] ?? 'No description provided.', style: AppTextStyles.bodyMedium),
                      ),
                      const SizedBox(height: AppSpacing.l),

                      SectionCard(
                        title: 'Products & Storefront',
                        actionLabel: 'Browse',
                        onActionTap: () {},
                        child: _buildImageGrid(data['storeImages'] ?? []),
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      PrimaryButton(
                        text: 'Contact Merchant',
                        icon: Icons.storefront,
                        onPressed: () => context.push('/chat/$uid'),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, Map<String, dynamic> data) {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      leading: const BackButton(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (data['storeImages'] != null && data['storeImages'].isNotEmpty)
              CachedNetworkImage(imageUrl: data['storeImages'][0], fit: BoxFit.cover)
            else
              Container(color: AppColors.accentBlue.withOpacity(0.1)),
            Container(color: Colors.black.withOpacity(0.2)),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.accentBlue),
        const SizedBox(width: AppSpacing.s),
        Expanded(child: Text(text, style: AppTextStyles.bodyMedium)),
      ],
    );
  }

  Widget _buildImageGrid(List images) {
    if (images.isEmpty) return const Text('No images available.');
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        itemBuilder: (context, index) => Container(
          width: 150,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(image: CachedNetworkImageProvider(images[index]), fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }
}
