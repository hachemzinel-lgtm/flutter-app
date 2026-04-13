import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../features/auth/providers/auth_providers.dart';
import '../../data/models/search_params.dart';
import '../controllers/search_results_controller.dart';

class SearchResultsScreen extends ConsumerStatefulWidget {
  const SearchResultsScreen({super.key, required this.params});

  final SearchParams params;

  @override
  ConsumerState<SearchResultsScreen> createState() =>
      _SearchResultsScreenState();
}

class _SearchResultsScreenState extends ConsumerState<SearchResultsScreen> {
  final MapController _mapController = MapController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userData = ref.watch(currentUserDataProvider).value;
    final normalizedRole =
        AppRoutes.normalizeAccountType(userData?['accountType']?.toString()) ??
        'client';
    final effectiveTarget = normalizedRole == 'client'
        ? (AppRoutes.normalizeAccountType(widget.params.targetType) ==
                  'workProvider'
              ? 'workProvider'
              : 'marketplace')
        : 'marketplace';

    final searchAsyncValue = ref.watch(searchResultsProvider(widget.params));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          effectiveTarget == 'workProvider'
              ? 'Work Provider Results'
              : 'Marketplace Results',
        ),
      ),
      body: searchAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (results) {
          if (results.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No results found in this area.'),
                  const Text(
                    'Try expanding your radius or adjusting your filters.',
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.pop(),
                    child: const Text('Adjust Filters'),
                  ),
                ],
              ),
            );
          }

          final initialCenter = LatLng(
            results.first.user.location!.latitude,
            results.first.user.location!.longitude,
          );

          return Column(
            children: [
              Expanded(
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: initialCenter,
                    initialZoom: 13,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    ),
                    MarkerLayer(
                      markers: results.map((result) {
                        final position = LatLng(
                          result.user.location!.latitude,
                          result.user.location!.longitude,
                        );
                        final isWorkProvider =
                            result.user.userType.name == 'workProvider';

                        return Marker(
                          point: position,
                          child: GestureDetector(
                            onTap: () => _mapController.move(position, 15),
                            child: Icon(
                              Icons.location_pin,
                              color: isWorkProvider
                                  ? AppColors.accentBlue
                                  : AppColors.softGray,
                              size: 40,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final item = results[index];
                    final user = item.user;
                    final isWorkProvider = user.userType.name == 'workProvider';

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        leading:
                            user.photoUrl != null && user.photoUrl!.isNotEmpty
                            ? CircleAvatar(
                                backgroundImage: NetworkImage(user.photoUrl!),
                              )
                            : CircleAvatar(
                                child: Icon(
                                  isWorkProvider ? Icons.person : Icons.store,
                                ),
                              ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                user.businessName ?? user.displayName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (isWorkProvider && user.badgeVisible == true)
                              const Icon(
                                Icons.verified,
                                color: Colors.blue,
                                size: 16,
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(user.category ?? 'Uncategorized'),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${user.averageRating.toStringAsFixed(1)} (${user.reviewCount})',
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  '${item.distance.toStringAsFixed(1)} km away',
                                ),
                              ],
                            ),
                            if (isWorkProvider &&
                                user.availabilityToggle == true)
                              const Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Text(
                                  'Available now',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            if (!isWorkProvider && user.openStatus != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  user.openStatus == true
                                      ? 'Open now'
                                      : 'Closed',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                          ],
                        ),
                        onTap: () {
                          if (isWorkProvider) {
                            context.push('/provider-profile/${user.uid}');
                          } else {
                            context.push('/marketplace-profile/${user.uid}');
                          }
                        },
                      ),
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
}
