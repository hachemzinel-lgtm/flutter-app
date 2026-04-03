import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/models/marketplace_model.dart';
import '../../../services/review_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../chat/providers/chat_provider.dart';

class MerchantProfileScreen extends ConsumerWidget {
  const MerchantProfileScreen({super.key, required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('Unable to load marketplace profile.')),
          );
        }
        if (!snapshot.hasData || snapshot.data?.data() == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final marketplace = MarketplaceModel.fromMap(
          uid,
          snapshot.data!.data()!,
        );

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 320,
                pinned: true,
                backgroundColor: AppColors.primaryNavy,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (marketplace.photoUrl != null)
                        Image.network(marketplace.photoUrl!, fit: BoxFit.cover)
                      else
                        Container(color: AppColors.primaryNavy),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              AppColors.primaryNavy.withValues(alpha: 0.82),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.l),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              marketplace.businessName ?? marketplace.name,
                              style: AppTextStyles.headingLarge.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              marketplace.category ?? 'Marketplace',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.accentBlue,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.m),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                _Pill(
                                  icon: Icons.star_rounded,
                                  label: marketplace.rating == 0
                                      ? 'New'
                                      : '${marketplace.rating.toStringAsFixed(1)} (${marketplace.reviewCount})',
                                  color: AppColors.starGold,
                                ),
                                if (_shortLocation(
                                  marketplace.address,
                                ).isNotEmpty)
                                  _Pill(
                                    icon: Icons.location_on_outlined,
                                    label: _shortLocation(marketplace.address),
                                    color: AppColors.accentBlue,
                                  ),
                                _Pill(
                                  icon: Icons.schedule_outlined,
                                  label: _openingStatus(
                                    marketplace.openingHours,
                                  ),
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
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: AppSpacing.pagePadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  _startChat(context, ref, marketplace),
                              icon: const Icon(
                                Icons.chat_bubble_outline_rounded,
                              ),
                              label: const Text('Message'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accentBlue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.m),
                          OutlinedButton.icon(
                            onPressed: () =>
                                _shareProfile(context, marketplace),
                            icon: const Icon(Icons.share_outlined),
                            label: const Text('Share'),
                          ),
                          const SizedBox(width: AppSpacing.s),
                          OutlinedButton.icon(
                            onPressed: () =>
                                _reportProfile(context, ref, marketplace.id),
                            icon: const Icon(Icons.flag_outlined),
                            label: const Text('Report'),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _Section(
                        title: 'About',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              marketplace.description?.trim().isNotEmpty == true
                                  ? marketplace.description!
                                  : 'No business description yet.',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.primaryNavy,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.l),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                _DetailTile(
                                  label: 'Category',
                                  value: marketplace.category ?? 'Marketplace',
                                ),
                                _DetailTile(
                                  label: 'Location',
                                  value:
                                      _shortLocation(
                                        marketplace.address,
                                      ).isEmpty
                                      ? 'Not shared'
                                      : _shortLocation(marketplace.address),
                                ),
                                _DetailTile(
                                  label: 'Hours',
                                  value: _openingStatus(
                                    marketplace.openingHours,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.l),
                      _Section(
                        title: 'Photos',
                        trailing: marketplace.photos.isNotEmpty
                            ? Text(
                                '${marketplace.photos.length} photos',
                                style: AppTextStyles.caption,
                              )
                            : null,
                        child: marketplace.photos.isEmpty
                            ? Text(
                                'No photos uploaded yet.',
                                style: AppTextStyles.bodyMedium,
                              )
                            : GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: marketplace.photos.length,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      crossAxisSpacing: 10,
                                      mainAxisSpacing: 10,
                                    ),
                                itemBuilder: (context, index) {
                                  final image = marketplace.photos[index];
                                  return InkWell(
                                    onTap: () => _openGallery(context, image),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: Image.network(
                                        image,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: AppSpacing.l),
                      _Section(
                        title: 'Reviews',
                        trailing: TextButton(
                          onPressed: () =>
                              context.push('/reviews/${marketplace.id}'),
                          child: const Text('See all'),
                        ),
                        child: StreamBuilder(
                          stream: ReviewService().getReviews(marketplace.id),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            final reviews = snapshot.data!;
                            if (reviews.isEmpty) {
                              return Text(
                                'No reviews yet.',
                                style: AppTextStyles.bodyMedium,
                              );
                            }
                            return Column(
                              children: reviews.take(5).map((review) {
                                return Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppSpacing.m,
                                  ),
                                  child: _ReviewCard(
                                    name: review.reviewerName,
                                    photoUrl: review.reviewerPhoto,
                                    rating: review.rating,
                                    text: review.text,
                                    date: review.createdAt,
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _startChat(
    BuildContext context,
    WidgetRef ref,
    MarketplaceModel marketplace,
  ) async {
    final currentUser = ref.read(currentUserDocProvider).value;
    if (currentUser == null) {
      return;
    }
    try {
      final conversation = await ref
          .read(chatServiceProvider)
          .getOrCreateConversation(
            currentUser: currentUser,
            otherUser: marketplace,
          );
      if (!context.mounted) {
        return;
      }
      final otherName = marketplace.businessName ?? marketplace.name;
      context.push(
        '/messages/${conversation.id}?otherName=${Uri.encodeComponent(otherName)}',
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  Future<void> _shareProfile(
    BuildContext context,
    MarketplaceModel marketplace,
  ) async {
    final link = 'nearwork://marketplace/${marketplace.id}';
    await Clipboard.setData(ClipboardData(text: link));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile link copied to clipboard.'),
          backgroundColor: AppColors.availableGreen,
        ),
      );
    }
  }

  Future<void> _reportProfile(
    BuildContext context,
    WidgetRef ref,
    String reportedUserId,
  ) async {
    final controller = TextEditingController();
    final reporterId = ref.read(authServiceProvider).currentUser?.uid;
    if (reporterId == null) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Report profile'),
          content: TextField(
            controller: controller,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Tell us what is wrong with this profile.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance.collection('reports').add({
                  'reporterId': reporterId,
                  'reportedUserId': reportedUserId,
                  'reason': controller.text.trim(),
                  'status': 'pending',
                  'createdAt': FieldValue.serverTimestamp(),
                });
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );

    controller.dispose();
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: AppTextStyles.headingSmall)),
              ?trailing,
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          child,
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
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

class _DetailTile extends StatelessWidget {
  const _DetailTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.primaryNavy,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.name,
    required this.photoUrl,
    required this.rating,
    required this.text,
    required this.date,
  });

  final String name;
  final String photoUrl;
  final double rating;
  final String text;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.accentBlue.withValues(alpha: 0.12),
                backgroundImage: photoUrl.isEmpty
                    ? null
                    : NetworkImage(photoUrl),
                child: photoUrl.isEmpty
                    ? Text(
                        name.substring(0, 1).toUpperCase(),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.accentBlue,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Text(
                  name,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryNavy,
                  ),
                ),
              ),
              const Icon(
                Icons.star_rounded,
                color: AppColors.starGold,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(rating.toStringAsFixed(1), style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            text.isEmpty ? 'No written review.' : text,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.primaryNavy,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            date.toIso8601String().split('T').first,
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

String _shortLocation(String? address) {
  if (address == null || address.trim().isEmpty) {
    return '';
  }
  return address.split(',').first.trim();
}

String _openingStatus(Map<String, dynamic>? openingHours) {
  if (openingHours == null || openingHours.isEmpty) {
    return 'Hours unavailable';
  }
  if (openingHours['alwaysOpen'] == true) {
    return 'Always Open';
  }
  return 'Hours available';
}

void _openGallery(BuildContext context, String imageUrl) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return Dialog(
        insetPadding: const EdgeInsets.all(AppSpacing.l),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: InteractiveViewer(
            child: Image.network(imageUrl, fit: BoxFit.contain),
          ),
        ),
      );
    },
  );
}
