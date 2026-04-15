import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_application_1/models/work_provider_model.dart';
import 'package:flutter_application_1/providers/auth_providers.dart';
import 'package:flutter_application_1/providers/chat_provider.dart';
import 'package:flutter_application_1/providers/profile_provider.dart';
import 'package:flutter_application_1/views/app_colors.dart';
import 'package:flutter_application_1/views/reviews_screen.dart';

class ProviderProfileScreen extends ConsumerWidget {
  const ProviderProfileScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider(id));
    final stats = ref.watch(workProviderProfileStatsProvider(id));
    final reviews = ref.watch(profileReviewsProvider(id));
    final currentUser = ref.watch(currentUserDocProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Work Provider')),
      body: profile.when(
        data: (user) {
          if (user is! WorkProviderModel) {
            return const Center(child: Text('Could not load profile'));
          }

          return stats.when(
            data: (providerStats) {
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
                                  user.name.substring(0, 1).toUpperCase(),
                                  style: const TextStyle(fontSize: 28),
                                )
                                : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              user.name,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (user.verificationStatus == 'approved') ...[
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.verified_rounded,
                              color: AppColors.accentBlue,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        user.profession ?? 'Work Provider',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.softGray),
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
                              label: 'Completed Jobs',
                              value: providerStats.completedJobs.toString(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              label: 'Portfolio',
                              value: user.portfolio.length.toString(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        value: user.isAvailableNow,
                        onChanged: null,
                        title: const Text('Available Now'),
                      ),
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.location_on_outlined),
                          title: const Text('Location'),
                          subtitle: Text(user.address ?? 'Location not shared'),
                        ),
                      ),
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.handyman_outlined),
                          title: const Text('Skills'),
                          subtitle: Text(user.profession ?? 'No skills listed'),
                        ),
                      ),
                      if ((user.bio ?? '').trim().isNotEmpty)
                        Card(
                          child: ListTile(
                            title: const Text('Bio'),
                            subtitle: Text(user.bio!),
                          ),
                        ),
                      if (user.portfolio.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Text(
                          'Portfolio',
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
                            itemCount: user.portfolio.length,
                            separatorBuilder:
                                (_, _) => const SizedBox(width: 10),
                            itemBuilder: (context, index) {
                              final image = user.portfolio[index];
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
                                  currentUser == null
                                      ? null
                                      : () =>
                                          _messageProvider(context, ref, user),
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

  Future<void> _messageProvider(
    BuildContext context,
    WidgetRef ref,
    WorkProviderModel provider,
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
