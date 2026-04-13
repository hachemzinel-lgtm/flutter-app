import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/user_model.dart';
import '../../../../features/auth/providers/auth_providers.dart';

class ProviderHomeScreen extends ConsumerStatefulWidget {
  const ProviderHomeScreen({super.key});

  @override
  ConsumerState<ProviderHomeScreen> createState() => _ProviderHomeScreenState();
}

class _ProviderHomeScreenState extends ConsumerState<ProviderHomeScreen> {
  bool _availabilityLoading = false;

  Future<void> _toggleAvailability(bool newValue, String uid) async {
    setState(() => _availabilityLoading = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'availabilityToggle': newValue,
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update availability: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _availabilityLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserDocProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (userDoc) {
          if (userDoc == null) {
            return const Center(child: Text('Please log in.'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildVerificationBanner(userDoc),
                Text(
                  'Welcome ${userDoc.displayName}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryNavy,
                  ),
                ),
                const SizedBox(height: 20),
                _SupplierSearchCard(
                  subtitle:
                      'Search marketplace suppliers only. Work-provider search is disabled for this role.',
                ),
                const SizedBox(height: 16),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Available for work',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (_availabilityLoading)
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2.4),
                          )
                        else
                          Switch(
                            value: userDoc.availabilityToggle ?? false,
                            onChanged: (value) =>
                                _toggleAvailability(value, userDoc.uid),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Top Rated Marketplace',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/top-rated'),
                      child: const Text('See all'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const _MarketplacePreviewList(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildVerificationBanner(UserModel userDoc) {
    if (userDoc.verificationStatus == 'unverified' &&
        userDoc.verificationAttempts == 0) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: MaterialBanner(
          backgroundColor: Colors.amber[100],
          content: const Text(
            'Upload your professional documents to unlock the verified badge.',
          ),
          actions: [
            TextButton(
              onPressed: () => context.push('/profile'),
              child: const Text('Upload'),
            ),
          ],
        ),
      );
    }

    if (userDoc.verificationStatus == 'rejected' ||
        (userDoc.verificationStatus == 'unverified' &&
            (userDoc.verificationAttempts ?? 0) > 0)) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: MaterialBanner(
          backgroundColor: Colors.red[50],
          content: const Text(
            'Your verification needs attention. Re-upload your documents to try again.',
          ),
          actions: [
            TextButton(
              onPressed: () => context.push('/profile'),
              child: const Text('Open profile'),
            ),
          ],
        ),
      );
    }

    if (userDoc.verificationStatus == 'approved' ||
        userDoc.verificationStatus == 'ai_verified' ||
        userDoc.verificationStatus == 'admin_verified') {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: MaterialBanner(
          backgroundColor: Colors.green[50],
          content: const Text(
            'Your profile is verified and visible as trusted.',
          ),
          actions: [TextButton(onPressed: () {}, child: const Text('OK'))],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

class _SupplierSearchCard extends StatelessWidget {
  const _SupplierSearchCard({required this.subtitle});

  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Find Suppliers',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(subtitle),
          const SizedBox(height: 14),
          InkWell(
            onTap: () => context.push('/search'),
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.search_rounded, color: AppColors.accentBlue),
                  SizedBox(width: 12),
                  Expanded(child: Text('Search marketplace suppliers')),
                  Icon(Icons.arrow_forward_ios_rounded, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MarketplacePreviewList extends StatelessWidget {
  const _MarketplacePreviewList();

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('users')
        .where('accountType', isEqualTo: 'marketplace')
        .where('profileComplete', isEqualTo: true)
        .where('reviewCount', isGreaterThanOrEqualTo: 1)
        .orderBy('reviewCount')
        .orderBy('averageRating', descending: true)
        .limit(5)
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text('No top suppliers found yet.');
        }

        final users = snapshot.data!.docs
            .map(
              (doc) => UserModel.fromJson({
                ...doc.data(),
                'uid': doc.id,
                'id': doc.id,
              }),
            )
            .toList();

        return Column(
          children: users.map((user) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                onTap: () => context.push('/marketplace-profile/${user.uid}'),
                leading: CircleAvatar(
                  backgroundImage:
                      user.photoUrl != null && user.photoUrl!.isNotEmpty
                      ? NetworkImage(user.photoUrl!)
                      : null,
                  child: user.photoUrl == null || user.photoUrl!.isEmpty
                      ? const Icon(Icons.storefront)
                      : null,
                ),
                title: Text(
                  user.businessName ?? user.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 4),
                    Text(user.averageRating.toStringAsFixed(1)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        user.category ?? 'Uncategorized',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
