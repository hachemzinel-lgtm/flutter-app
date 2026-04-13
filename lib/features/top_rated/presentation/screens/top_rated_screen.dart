import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../features/auth/providers/auth_providers.dart';

class TopRatedScreen extends ConsumerStatefulWidget {
  const TopRatedScreen({super.key});

  @override
  ConsumerState<TopRatedScreen> createState() => _TopRatedScreenState();
}

class _TopRatedScreenState extends ConsumerState<TopRatedScreen> {
  String _selectedTarget = 'workProvider';
  String _selectedCategory = 'All';

  double _haversineDistance(GeoPoint a, GeoPoint b) {
    const earthRadiusKm = 6371.0;
    final lat1 = a.latitude * pi / 180;
    final lat2 = b.latitude * pi / 180;
    final deltaLat = (b.latitude - a.latitude) * pi / 180;
    final deltaLon = (b.longitude - a.longitude) * pi / 180;
    final haversine =
        sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1) * cos(lat2) * sin(deltaLon / 2) * sin(deltaLon / 2);
    final arc = 2 * atan2(sqrt(haversine), sqrt(1 - haversine));
    return earthRadiusKm * arc;
  }

  @override
  Widget build(BuildContext context) {
    final userDocAsync = ref.watch(currentUserDocProvider);
    final userData = ref.watch(currentUserDataProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Top Rated')),
      body: userDocAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (currentUser) {
          if (currentUser == null || userData == null) {
            return const Center(child: Text('Please log in.'));
          }

          final currentRole =
              AppRoutes.normalizeAccountType(
                userData['accountType']?.toString(),
              ) ??
              'client';
          final canBrowseProviders = currentRole == 'client';
          final effectiveTarget = canBrowseProviders
              ? _selectedTarget
              : 'marketplace';

          if (!canBrowseProviders && _selectedTarget != 'marketplace') {
            _selectedTarget = 'marketplace';
            _selectedCategory = 'All';
          }

          final categories = [
            'All',
            ...(effectiveTarget == 'workProvider'
                ? AppConstants.providerCategories
                : AppConstants.marketplaceCategories),
          ];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    if (canBrowseProviders) ...[
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('WP Tab'),
                          selected: effectiveTarget == 'workProvider',
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedTarget = 'workProvider';
                                _selectedCategory = 'All';
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('MP Tab'),
                        selected: effectiveTarget == 'marketplace',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedTarget = 'marketplace';
                              _selectedCategory = 'All';
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  effectiveTarget == 'workProvider'
                      ? 'Browse top rated work providers.'
                      : currentRole == 'marketplace'
                      ? 'Browse top rated marketplace suppliers, excluding your own listing.'
                      : 'Browse top rated marketplace suppliers.',
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: categories.map((category) {
                    return Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      child: FilterChip(
                        label: Text(category),
                        selected: _selectedCategory == category,
                        onSelected: (_) {
                          setState(() => _selectedCategory = category);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _buildQuery(
                    targetType: effectiveTarget,
                    category: _selectedCategory,
                  ).snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text('No top-rated users found.'),
                      );
                    }

                    final results =
                        snapshot.data!.docs
                            .map(
                              (doc) => UserModel.fromJson({
                                ...doc.data(),
                                'uid': doc.id,
                                'id': doc.id,
                              }),
                            )
                            .where((user) {
                              if (effectiveTarget != 'marketplace') {
                                return true;
                              }
                              if (currentRole != 'marketplace') {
                                return true;
                              }
                              return user.uid != currentUser.uid;
                            })
                            .map((user) {
                              final weightedScore =
                                  (user.averageRating * 0.7) +
                                  (log(user.reviewCount + 1) * 0.3 * 5);
                              final distance =
                                  currentUser.location != null &&
                                      user.location != null
                                  ? _haversineDistance(
                                      currentUser.location!,
                                      user.location!,
                                    )
                                  : null;

                              return _TopRatedItem(
                                user: user,
                                score: weightedScore,
                                distanceKm: distance,
                              );
                            })
                            .toList()
                          ..sort(
                            (left, right) => right.score.compareTo(left.score),
                          );

                    if (results.isEmpty) {
                      return const Center(
                        child: Text(
                          'No eligible listings found for this role.',
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: min(results.length, 20),
                      itemBuilder: (context, index) {
                        final item = results[index];
                        final user = item.user;
                        final isProvider =
                            user.userType == UserType.workProvider;
                        final rankColor = switch (index) {
                          0 => Colors.amber,
                          1 => Colors.grey,
                          2 => Colors.brown,
                          _ => Colors.blueGrey.shade100,
                        };

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: ListTile(
                            onTap: () => context.push(
                              isProvider
                                  ? '/provider-profile/${user.uid}'
                                  : '/marketplace-profile/${user.uid}',
                            ),
                            leading: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  backgroundColor: rankColor,
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                CircleAvatar(
                                  backgroundImage:
                                      user.photoUrl != null &&
                                          user.photoUrl!.isNotEmpty
                                      ? NetworkImage(user.photoUrl!)
                                      : null,
                                  child:
                                      user.photoUrl == null ||
                                          user.photoUrl!.isEmpty
                                      ? Icon(
                                          isProvider
                                              ? Icons.handyman
                                              : Icons.storefront,
                                        )
                                      : null,
                                ),
                              ],
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    user.businessName ?? user.displayName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (isProvider && user.badgeVisible == true)
                                  const Icon(
                                    Icons.verified_rounded,
                                    size: 18,
                                    color: AppColors.accentBlue,
                                  ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user.category ?? 'Uncategorized'),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      color: Colors.amber,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${user.averageRating.toStringAsFixed(1)} (${user.reviewCount})',
                                    ),
                                    if (item.distanceKm != null) ...[
                                      const SizedBox(width: 12),
                                      Text(
                                        '${item.distanceKm!.toStringAsFixed(1)} km away',
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Query<Map<String, dynamic>> _buildQuery({
    required String targetType,
    required String category,
  }) {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('users')
        .where('profileComplete', isEqualTo: true)
        .where('reviewCount', isGreaterThanOrEqualTo: 1)
        .orderBy('reviewCount')
        .orderBy('averageRating', descending: true)
        .limit(50);

    if (targetType == 'workProvider') {
      query = query.where(
        'accountType',
        whereIn: ['workProvider', 'work_provider'],
      );
    } else {
      query = query.where('accountType', isEqualTo: 'marketplace');
    }

    if (category != 'All') {
      query = query.where('category', isEqualTo: category);
    }

    return query;
  }
}

class _TopRatedItem {
  const _TopRatedItem({
    required this.user,
    required this.score,
    required this.distanceKm,
  });

  final UserModel user;
  final double score;
  final double? distanceKm;
}
