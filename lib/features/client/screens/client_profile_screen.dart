import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/providers/user_profile_provider.dart';

class ClientProfileScreen extends ConsumerWidget {
  const ClientProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    final profileAsyncValue = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: Text('My Profile', style: AppTextStyles.headingSmall),
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: profileAsyncValue.when(
        data: (data) {
          if (data.isEmpty) {
            return const Center(child: Text('Profile not found'));
          }

          final firstName = data['firstName'] ?? '';
          final lastName = data['lastName'] ?? '';
          final name = data['name'] ?? '$firstName $lastName'.trim();
          final phone = data['phoneNumber'] ?? data['phone'] ?? 'No phone set';
          final photoUrl = data['profileImageUrl'] ?? data['photoUrl'];
          final double averageRating = (data['averageRating'] as num?)?.toDouble() ?? 0.0;
          final int reviewCount = (data['reviewCount'] as num?)?.toInt() ?? 0;

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            children: [
              // Profile Header
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.softGray.withValues(alpha: 0.2),
                      backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                      child: photoUrl == null ? const Icon(Icons.person, size: 50, color: AppColors.softGray) : null,
                    ),
                    const SizedBox(height: 16),
                    Text(name.isEmpty ? 'User' : name, style: AppTextStyles.headingMedium),
                    const SizedBox(height: 4),
                    Text(phone, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.softGray)),
                    const SizedBox(height: 12),
                    // Show average rating received if available
                    if (reviewCount > 0)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.star, color: AppColors.starGold, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            averageRating.toStringAsFixed(1),
                            style: AppTextStyles.headingSmall,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '($reviewCount ratings)',
                            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.softGray),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              Text('Feedback from Providers', style: AppTextStyles.headingSmall),
              const SizedBox(height: 16),
              _buildReceivedReviews(uid),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accentBlue)),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildReceivedReviews(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('reviews')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.accentBlue));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(Icons.rate_review_outlined, size: 48, color: AppColors.softGray.withValues(alpha: 0.3)),
                const SizedBox(height: 12),
                Text(
                  'No feedback received yet.\nRatings from providers you hire will appear here.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption.copyWith(color: AppColors.softGray),
                ),
              ],
            ),
          );
        }

        return Column(
          children: snapshot.data!.docs.map((doc) {
            final review = doc.data() as Map<String, dynamic>;
            return _reviewTile(review);
          }).toList(),
        );
      },
    );
  }

  Widget _reviewTile(Map<String, dynamic> review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(review['reviewerName'] ?? 'Provider', style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.bold)),
              Text(
                timeago.format((review['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now()),
                style: AppTextStyles.caption,
              ),
            ],
          ),
          const SizedBox(height: 8),
          RatingBarIndicator(
            rating: (review['rating'] ?? 0.0).toDouble(),
            itemBuilder: (context, index) => const Icon(Icons.star, color: AppColors.starGold),
            itemCount: 5,
            itemSize: 14,
          ),
          if (review['comment'] != null && review['comment'].toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(review['comment'], style: AppTextStyles.bodyMedium),
          ],
        ],
      ),
    );
  }
}
