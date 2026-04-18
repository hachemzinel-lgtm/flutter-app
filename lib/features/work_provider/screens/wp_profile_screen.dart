import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/providers/user_profile_provider.dart';

class WpProfileScreen extends ConsumerWidget {
  const WpProfileScreen({super.key});

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
        title: Text('Provider Profile', style: AppTextStyles.headingSmall),
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
          final whatsapp = data['whatsappNumber'];
          final profession = data['profession'] ?? data['category'] ?? 'Professional';
          final yearsExp = data['yearsExperience'] ?? 0;
          final bio = data['bio'] ?? 'No bio provided.';
          final location = data['locationName'] ?? data['location'] ?? 'Unknown location';
          final radius = data['serviceRadiusKm'] ?? data['serviceRadius'] ?? 10;
          final photoUrl = data['profileImageUrl'] ?? data['photoUrl'];
          final isVerified = data['isVerified'] ?? false;
          final isAvailable = data['isAvailable'] ?? false;
          final averageRating = (data['averageRating'] as num?)?.toDouble() ?? 0.0;
          final reviewCount = (data['reviewCount'] as num?)?.toInt() ?? 0;
          final verificationStatus = data['verificationStatus'];

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            children: [
              // Avatar & Name Header
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(name.isEmpty ? 'Provider' : name, style: AppTextStyles.headingMedium),
                        if (isVerified) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.verified, color: AppColors.starGold, size: 24),
                        ]
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(profession, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.accentBlue)),
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
                  _statItem(Icons.work_history, AppColors.accentBlue, '$yearsExp yrs', 'Experience'),
                  Container(width: 1, height: 40, color: AppColors.borderLight),
                  _statItem(Icons.location_on, AppColors.accentOrange, '${radius}km', 'Radius'),
                ],
              ),
              const SizedBox(height: 32),

              // Availability Toggle
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
                        Text('Availability Status', style: AppTextStyles.headingSmall),
                        Text(isAvailable ? 'Clients can book you' : 'You are currently hidden', style: AppTextStyles.caption),
                      ],
                    ),
                    Switch(
                      value: isAvailable,
                      activeThumbColor: AppColors.successGreen,
                      onChanged: (value) {
                        FirebaseFirestore.instance.collection('users').doc(uid).update({'isAvailable': value});
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Bio
              Text('About Me', style: AppTextStyles.headingSmall),
              const SizedBox(height: 8),
              Text(bio, style: AppTextStyles.bodyMedium),
              const SizedBox(height: 24),

              // Contact Info
              Text('Contact Info', style: AppTextStyles.headingSmall),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.phone, size: 16, color: AppColors.softGray),
                  const SizedBox(width: 8),
                  Text(phone, style: AppTextStyles.bodyMedium),
                ],
              ),
              if (whatsapp != null && whatsapp.toString().isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.chat, size: 16, color: AppColors.successGreen),
                    const SizedBox(width: 8),
                    Text(whatsapp, style: AppTextStyles.bodyMedium),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_city, size: 16, color: AppColors.softGray),
                  const SizedBox(width: 8),
                  Text(location, style: AppTextStyles.bodyMedium),
                ],
              ),
              const SizedBox(height: 32),

              // Verification Section
              if (!isVerified)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.accentBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.shield_outlined, color: AppColors.accentBlue),
                          const SizedBox(width: 8),
                          Text('Optional: Get Verified', style: AppTextStyles.headingMedium.copyWith(color: AppColors.accentBlue, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        verificationStatus == 'pending' 
                            ? 'Your ID is currently under review by our team.'
                            : 'Upload your ID and professional documents to earn a verified badge and attract more clients.',
                        style: AppTextStyles.bodyMedium,
                      ),
                      if (verificationStatus != 'pending') ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              // Simulate upload -> sets to pending
                              FirebaseFirestore.instance.collection('users').doc(uid).update({'verificationStatus': 'pending'});
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accentBlue,
                              foregroundColor: AppColors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Start Verification'),
                          ),
                        ),
                      ]
                    ],
                  ),
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
