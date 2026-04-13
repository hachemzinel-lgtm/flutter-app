import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../features/auth/providers/auth_providers.dart';
import '../../data/models/search_params.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  int _selectedTab = 0;
  double _radius = 10;
  final List<String> _selectedCategories = [];
  double _minRating = 0.0;
  bool _verifiedOnly = false;
  bool _availableOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String accountType, String uid) {
    final normalizedRole =
        AppRoutes.normalizeAccountType(accountType) ?? 'client';

    late final String targetType;
    late final String? excludeUid;

    if (normalizedRole == 'client') {
      targetType = _selectedTab == 0 ? 'workProvider' : 'marketplace';
      excludeUid = null;
    } else if (normalizedRole == 'marketplace') {
      targetType = 'marketplace';
      excludeUid = uid;
    } else {
      targetType = 'marketplace';
      excludeUid = null;
    }

    final params = SearchParams(
      targetType: targetType,
      searchQuery: _searchController.text.isEmpty
          ? null
          : _searchController.text.trim(),
      radius: _radius.toInt(),
      categories: _selectedCategories,
      minRating: _minRating,
      verifiedOnly: normalizedRole == 'client' && _selectedTab == 0
          ? _verifiedOnly
          : false,
      availableOnly: _availableOnly,
      excludeUid: excludeUid,
    );

    context.push('/search-results', extra: params);
  }

  void _toggleCategory(String category) {
    setState(() {
      if (_selectedCategories.contains(category)) {
        _selectedCategories.remove(category);
      } else {
        _selectedCategories.add(category);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userDocValue = ref.watch(currentUserDocProvider);
    final userData = ref.watch(currentUserDataProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: userDocValue.when(
        data: (userDoc) {
          if (userDoc == null || userData == null) {
            return const Center(child: Text('Authentication required'));
          }

          final normalizedRole =
              AppRoutes.normalizeAccountType(
                userData['accountType']?.toString(),
              ) ??
              'client';
          final isClient = normalizedRole == 'client';
          final effectiveTab = isClient ? _selectedTab : 1;
          final isProviderSearch = isClient && effectiveTab == 0;

          final currentCategories = isProviderSearch
              ? AppConstants.providerCategories
              : AppConstants.marketplaceCategories;

          final title = switch (normalizedRole) {
            'workProvider' => 'Find Suppliers',
            'marketplace' => 'Find Suppliers',
            _ => 'Search Near You',
          };

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: title,
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (isClient) ...[
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Work Providers'),
                          selected: _selectedTab == 0,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedTab = 0;
                                _selectedCategories.clear();
                                _verifiedOnly = false;
                                _availableOnly = false;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Marketplace'),
                          selected: _selectedTab == 1,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedTab = 1;
                                _selectedCategories.clear();
                                _verifiedOnly = false;
                                _availableOnly = false;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ] else
                  Text(
                    normalizedRole == 'marketplace'
                        ? 'Search other marketplace suppliers only.'
                        : 'Search marketplace suppliers only.',
                  ),
                const SizedBox(height: 16),
                const Text(
                  'Search Radius',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: _radius,
                        min: 1,
                        max: 50,
                        divisions: 49,
                        onChanged: (value) => setState(() => _radius = value),
                      ),
                    ),
                    Text('${_radius.toInt()} km'),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Categories',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Wrap(
                  spacing: 8,
                  children: currentCategories.map((category) {
                    final selected = _selectedCategories.contains(category);
                    return FilterChip(
                      label: Text(category),
                      selected: selected,
                      onSelected: (_) => _toggleCategory(category),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Minimum Rating',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(6, (index) {
                    final rating = index.toDouble();
                    return GestureDetector(
                      onTap: () => setState(() => _minRating = rating),
                      child: Column(
                        children: [
                          Icon(
                            rating == 0 ? Icons.star_border : Icons.star,
                            color: _minRating >= rating
                                ? Colors.amber
                                : Colors.grey,
                            size: 32,
                          ),
                          Text(rating == 0 ? 'Any' : '$rating+'),
                        ],
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                if (isProviderSearch) ...[
                  SwitchListTile(
                    title: const Text('Verified Only'),
                    value: _verifiedOnly,
                    onChanged: (value) => setState(() => _verifiedOnly = value),
                    contentPadding: EdgeInsets.zero,
                  ),
                  SwitchListTile(
                    title: const Text('Available Now'),
                    value: _availableOnly,
                    onChanged: (value) =>
                        setState(() => _availableOnly = value),
                    contentPadding: EdgeInsets.zero,
                  ),
                ] else ...[
                  SwitchListTile(
                    title: Text(
                      normalizedRole == 'marketplace' ? 'Open Now' : 'Open Now',
                    ),
                    value: _availableOnly,
                    onChanged: (value) =>
                        setState(() => _availableOnly = value),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => _onSearch(
                    userData['accountType']?.toString() ?? 'client',
                    userDoc.uid,
                  ),
                  child: const Text('Search'),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
