import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/user_model.dart';
import '../../../../features/auth/providers/auth_providers.dart';

class MarketplaceHomeScreen extends ConsumerStatefulWidget {
  const MarketplaceHomeScreen({super.key});

  @override
  ConsumerState<MarketplaceHomeScreen> createState() =>
      _MarketplaceHomeScreenState();
}

class _MarketplaceHomeScreenState extends ConsumerState<MarketplaceHomeScreen> {
  bool _openStatusLoading = false;

  Future<void> _toggleOpenStatus(bool newValue, String uid) async {
    setState(() => _openStatusLoading = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'openStatus': newValue,
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update store status: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _openStatusLoading = false);
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
                Text(
                  'Welcome',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black.withValues(alpha: 0.6),
                  ),
                ),
                Text(
                  userDoc.businessName ?? userDoc.displayName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryNavy,
                  ),
                ),
                const SizedBox(height: 20),
                const _SupplierSearchCard(),
                const SizedBox(height: 16),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.storefront_rounded,
                              color: AppColors.accentBlue,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              userDoc.category ?? 'Marketplace',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 28),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Open for orders',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              userDoc.openStatus == true ? 'Open' : 'Closed',
                              style: TextStyle(
                                color: userDoc.openStatus == true
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (_openStatusLoading)
                              const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                ),
                              )
                            else
                              Switch(
                                value: userDoc.openStatus ?? false,
                                onChanged: (value) =>
                                    _toggleOpenStatus(value, userDoc.uid),
                              ),
                          ],
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
                _MarketplacePreviewList(currentUid: userDoc.uid),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SupplierSearchCard extends StatelessWidget {
  const _SupplierSearchCard();

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
          const Text(
            'Search other marketplace suppliers only. Your own listing is excluded automatically.',
          ),
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
  const _MarketplacePreviewList({required this.currentUid});

  final String currentUid;

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('users')
        .where('accountType', isEqualTo: 'marketplace')
        .where('profileComplete', isEqualTo: true)
        .where('reviewCount', isGreaterThanOrEqualTo: 1)
        .orderBy('reviewCount')
        .orderBy('averageRating', descending: true)
        .limit(8)
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final users = snapshot.data!.docs
            .where((doc) => doc.id != currentUid)
            .map(
              (doc) => UserModel.fromJson({
                ...doc.data(),
                'uid': doc.id,
                'id': doc.id,
              }),
            )
            .take(5)
            .toList();

        if (users.isEmpty) {
          return const Text('No other top suppliers found yet.');
        }

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
