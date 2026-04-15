import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_application_1/models/marketplace_model.dart';
import 'package:flutter_application_1/providers/auth_providers.dart';
import 'package:flutter_application_1/providers/chat_provider.dart';
import 'package:flutter_application_1/providers/profile_provider.dart';
import 'package:flutter_application_1/views/reviews_screen.dart';

class MarketplaceProfileScreen extends ConsumerWidget {
  const MarketplaceProfileScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider(id));
    final stats = ref.watch(marketplaceProfileStatsProvider(id));
    final reviews = ref.watch(profileReviewsProvider(id));

    return Scaffold(
      appBar: AppBar(title: const Text('Local Business')),
      body: profile.when(
        data: (user) {
          if (user is! MarketplaceModel) {
            return const Center(child: Text('Could not load profile'));
          }

          return stats.when(
            data: (marketStats) {
              return reviews.when(
                data: (reviewItems) {
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage:
                            user.photoUrl != null && user.photoUrl!.isNotEmpty
                                ? NetworkImage(user.photoUrl!)
                                : null,
                        child:
                            user.photoUrl == null || user.photoUrl!.isEmpty
                                ? Text(
                                  (user.businessName ?? user.name)
                                      .substring(0, 1)
                                      .toUpperCase(),
                                  style: const TextStyle(fontSize: 28),
                                )
                                : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user.businessName ?? user.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        user.category ?? 'Local Business',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              label: 'Rating',
                              value: user.rating.toStringAsFixed(1),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              label: 'Listings',
                              value: marketStats.listings.toString(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.location_on_outlined),
                          title: const Text('Location'),
                          subtitle: Text(user.address ?? 'Location not shared'),
                        ),
                      ),
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.schedule_outlined),
                          title: const Text('Operating Hours'),
                          subtitle: Text(_openingHoursText(user.openingHours)),
                        ),
                      ),
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.inventory_2_outlined),
                          title: const Text('Listings'),
                          subtitle: Text(
                            marketStats.listings == 0
                                ? 'No listings available yet.'
                                : '${marketStats.listings} active listings',
                          ),
                        ),
                      ),
                      if ((user.description ?? '').trim().isNotEmpty)
                        Card(
                          child: ListTile(
                            title: const Text('About'),
                            subtitle: Text(user.description!),
                          ),
                        ),
                      if (user.photos.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Text(
                          'Gallery',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 110,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: user.photos.length,
                            separatorBuilder:
                                (_, _) => const SizedBox(width: 10),
                            itemBuilder: (context, index) {
                              final image = user.photos[index];
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.network(
                                  image,
                                  width: 110,
                                  height: 110,
                                  fit: BoxFit.cover,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed:
                                  () => _messageMarketplace(context, ref, user),
                              icon: const Icon(Icons.chat_bubble_outline),
                              label: const Text('Message'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ReviewsScreen(providerId: id),
                                ),
                              );
                            },
                            child: const Text('Reviews'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (reviewItems.isEmpty)
                        const Text('No reviews yet.')
                      else
                        ...reviewItems.map(
                          (review) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundImage:
                                  review.reviewerPhoto.isNotEmpty
                                      ? NetworkImage(review.reviewerPhoto)
                                      : null,
                              child:
                                  review.reviewerPhoto.isEmpty
                                      ? const Icon(Icons.person)
                                      : null,
                            ),
                            title: Text(review.reviewerName),
                            subtitle: Text(
                              review.text.isEmpty
                                  ? 'No written review.'
                                  : review.text,
                            ),
                            trailing: Text(
                              review.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error:
                    (e, _) =>
                        const Center(child: Text('Could not load profile')),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error:
                (e, _) => const Center(child: Text('Could not load profile')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text('Could not load profile')),
      ),
    );
  }

  Future<void> _messageMarketplace(
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

String _openingHoursText(Map<String, dynamic>? openingHours) {
  if (openingHours == null || openingHours.isEmpty) {
    return 'Hours unavailable';
  }
  if (openingHours['alwaysOpen'] == true) {
    return 'Always open';
  }
  return 'Hours available';
}
