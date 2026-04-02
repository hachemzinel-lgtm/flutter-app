import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/models/work_provider_model.dart';
import '../../../services/review_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../chat/providers/chat_provider.dart';

class ProviderProfileScreen extends ConsumerWidget {
  const ProviderProfileScreen({
    super.key,
    required this.uid,
  });

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('Unable to load profile.')),
          );
        }
        if (!snapshot.hasData || snapshot.data?.data() == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final provider = WorkProviderModel.fromMap(uid, snapshot.data!.data()!);
        final shortLocation = _shortLocation(provider.address);

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
                      if (provider.photoUrl != null)
                        Image.network(provider.photoUrl!, fit: BoxFit.cover)
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
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    provider.name,
                                    style: AppTextStyles.headingLarge.copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                if (provider.verificationStatus == 'approved')
                                  const Icon(
                                    Icons.verified_rounded,
                                    color: AppColors.starGold,
                                    size: 24,
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
                            const SizedBox(height: AppSpacing.m),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                _InfoBadge(
                                  icon: Icons.star_rounded,
                                  label: provider.rating == 0
                                      ? 'New'
                                      : '${provider.rating.toStringAsFixed(1)} (${provider.reviewCount})',
                                  color: AppColors.starGold,
                                ),
                                if (shortLocation.isNotEmpty)
                                  _InfoBadge(
                                    icon: Icons.location_on_outlined,
                                    label: shortLocation,
                                    color: AppColors.accentBlue,
                                  ),
                                if (provider.isAvailableNow)
                                  const _InfoBadge(
                                    icon: Icons.flash_on_rounded,
                                    label: 'Available Now',
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
                              onPressed: () => _startChat(context, ref, provider),
                              icon: const Icon(Icons.chat_bubble_outline_rounded),
                              label: const Text('Message'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accentBlue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.m),
                          OutlinedButton.icon(
                            onPressed: () => _shareProfile(context, provider),
                            icon: const Icon(Icons.share_outlined),
                            label: const Text('Share'),
                          ),
                          const SizedBox(width: AppSpacing.s),
                          OutlinedButton.icon(
                            onPressed: () => _reportProfile(context, ref, provider.id),
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
                              provider.bio?.trim().isNotEmpty == true
                                  ? provider.bio!
                                  : 'No bio shared yet.',
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
                                  label: 'Experience',
                                  value:
                                      '${provider.yearsExperience ?? 0} years',
                                ),
                                _DetailTile(
                                  label: 'Language',
                                  value: _languageName(provider.language),
                                ),
                                _DetailTile(
                                  label: 'Location',
                                  value: shortLocation.isEmpty
                                      ? 'Not shared'
                                      : shortLocation,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.l),
                      _Section(
                        title: 'Pricing',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (provider.hourlyRate != null)
                              _PriceRow(
                                label: 'Hourly rate',
                                value:
                                    provider.hourlyRate!.toStringAsFixed(2),
                              ),
                            if (provider.services.isNotEmpty)
                              ...provider.services.map(
                                (service) => _PriceRow(
                                  label: service.name,
                                  value: service.price.toStringAsFixed(2),
                                ),
                              ),
                            if (provider.customQuoteEnabled)
                              Text(
                                'Custom quote available',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.accentBlue,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            if (provider.hourlyRate == null &&
                                provider.services.isEmpty &&
                                !provider.customQuoteEnabled)
                              Text(
                                'Pricing details are not shared yet.',
                                style: AppTextStyles.bodyMedium,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.l),
                      _Section(
                        title: 'Portfolio',
                        trailing: provider.portfolio.isNotEmpty
                            ? Text(
                                '${provider.portfolio.length} photos',
                                style: AppTextStyles.caption,
                              )
                            : null,
                        child: provider.portfolio.isEmpty
                            ? Text(
                                'No portfolio photos yet.',
                                style: AppTextStyles.bodyMedium,
                              )
                            : GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: provider.portfolio.length,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                ),
                                itemBuilder: (context, index) {
                                  final image = provider.portfolio[index];
                                  return InkWell(
                                    onTap: () => _openGallery(context, image),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: Image.network(image, fit: BoxFit.cover),
                                    ),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: AppSpacing.l),
                      _Section(
                        title: 'Reviews',
                        trailing: TextButton(
                          onPressed: () => context.push('/reviews/${provider.id}'),
                          child: const Text('See all'),
                        ),
                        child: StreamBuilder(
                          stream: ReviewService().getReviews(provider.id),
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
    WorkProviderModel provider,
  ) async {
    final currentUser = ref.read(currentUserDocProvider).value;
    if (currentUser == null) {
      return;
    }
    try {
      final conversation = await ref.read(chatServiceProvider).getOrCreateConversation(
        currentUser: currentUser,
        otherUser: provider,
      );
      if (!context.mounted) {
        return;
      }
      context.push(
        '/messages/${conversation.id}?otherName=${Uri.encodeComponent(provider.name)}',
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
    WorkProviderModel provider,
  ) async {
    final link = 'nearwork://provider/${provider.id}';
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
  const _Section({
    required this.title,
    required this.child,
    this.trailing,
  });

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
              Expanded(
                child: Text(title, style: AppTextStyles.headingSmall),
              ),
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

class _InfoBadge extends StatelessWidget {
  const _InfoBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

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
  const _DetailTile({
    required this.label,
    required this.value,
  });

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

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.m),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.accentBlue,
              fontWeight: FontWeight.w700,
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
                backgroundImage: photoUrl.isEmpty ? null : NetworkImage(photoUrl),
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
              const Icon(Icons.star_rounded, color: AppColors.starGold, size: 16),
              const SizedBox(width: 4),
              Text(rating.toStringAsFixed(1), style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            text.isEmpty ? 'No written review.' : text,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primaryNavy),
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

String _languageName(String? code) {
  switch (code) {
    case 'fr':
      return 'French';
    case 'ar':
      return 'Arabic';
    default:
      return 'English';
  }
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
