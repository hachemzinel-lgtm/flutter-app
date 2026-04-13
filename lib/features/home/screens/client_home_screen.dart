import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/user_model.dart';
import '../../../../features/auth/providers/auth_providers.dart';

class ClientHomeScreen extends ConsumerStatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  ConsumerState<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends ConsumerState<ClientHomeScreen> {
  String _selectedSearchTarget = 'workProvider';
  String _selectedTopRatedTarget = 'workProvider';

  @override
  Widget build(BuildContext context) {
    final userDoc = ref.watch(currentUserDocProvider).value;
    final firstName = userDoc?.displayName.split(' ').first ?? 'there';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Hello, $firstName',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryNavy,
                ),
              ),
              const SizedBox(height: 24),
              _SearchCard(
                selectedTarget: _selectedSearchTarget,
                onTargetChanged: (value) {
                  setState(() => _selectedSearchTarget = value);
                },
              ),
              const SizedBox(height: 20),
              Card(
                color: AppColors.primaryNavy,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: InkWell(
                  onTap: () => context.push('/ai-chat/session'),
                  borderRadius: BorderRadius.circular(18),
                  child: const Padding(
                    padding: EdgeInsets.all(18),
                    child: Row(
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          color: Colors.amber,
                          size: 40,
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AI Chatbot',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Describe what you need and we will help you find the right local service.',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Top Rated',
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
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('WP'),
                      selected: _selectedTopRatedTarget == 'workProvider',
                      onSelected: (selected) {
                        if (selected) {
                          setState(
                            () => _selectedTopRatedTarget = 'workProvider',
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('MP'),
                      selected: _selectedTopRatedTarget == 'marketplace',
                      onSelected: (selected) {
                        if (selected) {
                          setState(
                            () => _selectedTopRatedTarget = 'marketplace',
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _TopRatedPreviewList(targetType: _selectedTopRatedTarget),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchCard extends StatelessWidget {
  const _SearchCard({
    required this.selectedTarget,
    required this.onTargetChanged,
  });

  final String selectedTarget;
  final ValueChanged<String> onTargetChanged;

  @override
  Widget build(BuildContext context) {
    final isProviderSearch = selectedTarget == 'workProvider';

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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Find services near you',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Text('WP'),
                  selected: isProviderSearch,
                  onSelected: (selected) {
                    if (selected) {
                      onTargetChanged('workProvider');
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const Text('MP'),
                  selected: !isProviderSearch,
                  onSelected: (selected) {
                    if (selected) {
                      onTargetChanged('marketplace');
                    }
                  },
                ),
              ),
            ],
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
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: AppColors.accentBlue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isProviderSearch
                          ? 'Search work providers'
                          : 'Search marketplaces',
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopRatedPreviewList extends StatelessWidget {
  const _TopRatedPreviewList({required this.targetType});

  final String targetType;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _buildQuery(targetType).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text('No top rated listings found yet.');
        }

        final users = snapshot.data!.docs
            .map(_userFromSnapshot)
            .whereType<UserModel>()
            .take(5)
            .toList();

        return Column(
          children: users.map((user) {
            final isProvider = user.userType == UserType.workProvider;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                onTap: () => context.push(
                  isProvider
                      ? '/provider-profile/${user.uid}'
                      : '/marketplace-profile/${user.uid}',
                ),
                leading: CircleAvatar(
                  backgroundImage:
                      user.photoUrl != null && user.photoUrl!.isNotEmpty
                      ? NetworkImage(user.photoUrl!)
                      : null,
                  child: user.photoUrl == null || user.photoUrl!.isEmpty
                      ? Icon(isProvider ? Icons.handyman : Icons.storefront)
                      : null,
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        user.businessName ?? user.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (isProvider && user.badgeVisible == true)
                      const Padding(
                        padding: EdgeInsetsDirectional.only(start: 6),
                        child: Icon(
                          Icons.verified_rounded,
                          size: 18,
                          color: AppColors.accentBlue,
                        ),
                      ),
                  ],
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

  Query<Map<String, dynamic>> _buildQuery(String targetType) {
    final collection = FirebaseFirestore.instance.collection('users');
    if (targetType == 'workProvider') {
      return collection
          .where('accountType', whereIn: ['workProvider', 'work_provider'])
          .where('profileComplete', isEqualTo: true)
          .where('reviewCount', isGreaterThanOrEqualTo: 1)
          .orderBy('reviewCount')
          .orderBy('averageRating', descending: true)
          .limit(5);
    }

    return collection
        .where('accountType', isEqualTo: 'marketplace')
        .where('profileComplete', isEqualTo: true)
        .where('reviewCount', isGreaterThanOrEqualTo: 1)
        .orderBy('reviewCount')
        .orderBy('averageRating', descending: true)
        .limit(5);
  }

  static UserModel _userFromSnapshot(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = <String, dynamic>{...doc.data(), 'uid': doc.id, 'id': doc.id};
    return UserModel.fromJson(data);
  }
}
