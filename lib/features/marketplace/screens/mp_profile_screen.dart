import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/providers/user_profile_provider.dart';

class MpProfileScreen extends ConsumerWidget {
  const MpProfileScreen({super.key});

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
        title: Text('Store Profile', style: AppTextStyles.headingSmall),
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: profileAsyncValue.when(
        data: (data) {
          if (data.isEmpty) {
            return const Center(child: Text('Profile not found'));
          }

          final shopName = data['shopName'] ?? data['name'] ?? 'My Shop';
          final description = data['description'] ?? 'No description provided.';
          final phone = data['phoneNumber'] ?? data['phone'] ?? 'No phone set';
          final location = data['locationName'] ?? data['location'] ?? 'Unknown location';
          final radius = data['serviceRadiusKm'] ?? data['serviceRadius'] ?? 10;
          final photoUrl = data['profileImageUrl'] ?? data['photoUrl'];
          final isOpen = data['isOpen'] ?? false;
          final averageRating = (data['averageRating'] as num?)?.toDouble() ?? 0.0;
          final reviewCount = (data['reviewCount'] as num?)?.toInt() ?? 0;

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            children: [
              // Shop Header
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.softGray.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                        image: photoUrl != null 
                            ? DecorationImage(image: NetworkImage(photoUrl), fit: BoxFit.cover) 
                            : null,
                      ),
                      child: photoUrl == null 
                          ? const Icon(Icons.storefront, size: 50, color: AppColors.softGray) 
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(shopName, style: AppTextStyles.headingMedium, textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: isOpen ? AppColors.successGreen.withValues(alpha: 0.1) : AppColors.softGray.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        isOpen ? 'Currently Open' : 'Closed',
                        style: AppTextStyles.caption.copyWith(
                          color: isOpen ? AppColors.successGreen : AppColors.softGray,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Stats Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _statItem(Icons.star, AppColors.starGold, averageRating.toStringAsFixed(1), '$reviewCount reviews'),
                  Container(width: 1, height: 40, color: AppColors.borderLight),
                  _statItem(Icons.location_on, AppColors.accentOrange, '${radius}km', 'Delivery Area'),
                ],
              ),
              const SizedBox(height: 32),

              // Open Toggle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Store Status', style: AppTextStyles.headingSmall),
                        Text(isOpen ? 'Accepting new orders' : 'Not accepting orders right now', style: AppTextStyles.caption),
                      ],
                    ),
                    Switch(
                      value: isOpen,
                      activeThumbColor: AppColors.successGreen,
                      onChanged: (value) {
                        FirebaseFirestore.instance.collection('users').doc(uid).update({'isOpen': value});
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Description
              Text('About This Store', style: AppTextStyles.headingSmall),
              const SizedBox(height: 8),
              Text(description, style: AppTextStyles.bodyMedium),
              const SizedBox(height: 24),

              // Contact Info
              Text('Contact & Location', style: AppTextStyles.headingSmall),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.phone, size: 16, color: AppColors.softGray),
                  const SizedBox(width: 8),
                  Text(phone, style: AppTextStyles.bodyMedium),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.store, size: 16, color: AppColors.softGray),
                  const SizedBox(width: 8),
                  Text(location, style: AppTextStyles.bodyMedium),
                ],
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accentBlue)),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _statItem(IconData icon, Color color, String value, String label) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 4),
            Text(value, style: AppTextStyles.headingSmall),
          ],
        ),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}
