import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/marketplace_taxonomy.dart';
import '../../../core/models/work_provider_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/discovery_models.dart';
import '../providers/home_provider.dart';
import '../widgets/provider_feature_card.dart';

class ClientHomeScreen extends ConsumerStatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  ConsumerState<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends ConsumerState<ClientHomeScreen> {
  final _manualAddressController = TextEditingController();
  DiscoverySearchType _searchType = DiscoverySearchType.workProviders;
  String _providerCategory = 'Any';
  String _marketplaceCategory = 'Any';
  double _radiusKm = 10;
  double _minimumRating = 0;
  bool _availableOnly = false;
  bool _useCurrentLocation = true;
  bool _isResolvingLocation = false;

  @override
  void dispose() {
    _manualAddressController.dispose();
    super.dispose();
  }

  Future<void> _startSearch() async {
    final user = ref.read(currentUserDocProvider).value;
    setState(() => _isResolvingLocation = true);
    try {
      final location = await ref.read(discoveryServiceProvider).resolveSearchLocation(
            useCurrentLocation: _useCurrentLocation,
            savedLocation: user?.location,
            savedAddress: user?.address,
            manualAddress: _manualAddressController.text,
          );

      if (!mounted) {
        return;
      }

      context.push(
        '/search-results'
        '?type=${_searchType.queryValue}'
        '&category=${Uri.encodeComponent(_selectedCategory)}'
        '&radius=$_radiusKm'
        '&minRating=$_minimumRating'
        '&availableOnly=$_availableOnly'
        '&lat=${location.center.latitude}'
        '&lng=${location.center.longitude}'
        '&label=${Uri.encodeComponent(location.label)}',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: AppColors.errorRed,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isResolvingLocation = false);
      }
    }
  }

  String get _selectedCategory {
    return _searchType == DiscoverySearchType.workProviders
        ? _providerCategory
        : _marketplaceCategory;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserDocProvider).value;
    final firstName = user?.name.split(' ').first ?? 'there';
    final topRatedAsync = ref.watch(topRatedProvidersProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.l),
                decoration: BoxDecoration(
                  color: AppColors.primaryNavy,
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryNavy,
                      AppColors.primaryNavy.withValues(alpha: 0.88),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, $firstName',
                      style: AppTextStyles.headingLarge.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s),
                    InkWell(
                      onTap: () => _manualAddressController.selection =
                          TextSelection.collapsed(
                        offset: _manualAddressController.text.length,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              color: AppColors.accentBlue,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                user?.address?.isNotEmpty == true
                                    ? user!.address!
                                    : 'No saved location yet',
                                style: AppTextStyles.caption.copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.l),
              TextField(
                readOnly: true,
                decoration: InputDecoration(
                  hintText: 'What are you looking for?',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.l),
              SegmentedButton<DiscoverySearchType>(
                segments: const [
                  ButtonSegment(
                    value: DiscoverySearchType.workProviders,
                    label: Text('Work Providers'),
                    icon: Icon(Icons.handyman_outlined),
                  ),
                  ButtonSegment(
                    value: DiscoverySearchType.marketplaces,
                    label: Text('Marketplaces'),
                    icon: Icon(Icons.storefront_outlined),
                  ),
                ],
                selected: {_searchType},
                onSelectionChanged: (value) {
                  setState(() => _searchType = value.first);
                },
              ),
              const SizedBox(height: AppSpacing.l),
              _SectionCard(
                title: _searchType == DiscoverySearchType.workProviders
                    ? 'Search for work providers'
                    : 'Search for marketplaces',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('CATEGORY'),
                    _CategoryDropdown(
                      items: [
                        'Any',
                        ...(_searchType == DiscoverySearchType.workProviders
                            ? MarketplaceTaxonomy.workProviderCategories
                            : MarketplaceTaxonomy.marketplaceCategories),
                      ],
                      value: _selectedCategory,
                      onChanged: (value) {
                        setState(() {
                          if (_searchType == DiscoverySearchType.workProviders) {
                            _providerCategory = value!;
                          } else {
                            _marketplaceCategory = value!;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: AppSpacing.l),
                    _label('LOCATION'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Use my current location'),
                          selected: _useCurrentLocation,
                          onSelected: (_) => setState(() => _useCurrentLocation = true),
                        ),
                        ChoiceChip(
                          label: const Text('Use saved profile location'),
                          selected: !_useCurrentLocation &&
                              _manualAddressController.text.trim().isEmpty,
                          onSelected: (_) {
                            setState(() {
                              _useCurrentLocation = false;
                              _manualAddressController.clear();
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.m),
                    TextField(
                      controller: _manualAddressController,
                      decoration: InputDecoration(
                        hintText: 'Or set location manually',
                        prefixIcon: const Icon(Icons.edit_location_alt_outlined),
                        filled: true,
                        fillColor: AppColors.backgroundSecondary,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (_) {
                        if (_manualAddressController.text.trim().isNotEmpty) {
                          setState(() => _useCurrentLocation = false);
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.l),
                    _label('DISTANCE RADIUS'),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${_radiusKm.toInt()} km', style: AppTextStyles.headingSmall),
                        Text(
                          'Search range',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                    Slider(
                      value: _radiusKm,
                      min: 5,
                      max: 50,
                      divisions: 9,
                      onChanged: (value) => setState(() => _radiusKm = value),
                    ),
                    Wrap(
                      spacing: 8,
                      children: MarketplaceTaxonomy.searchRadiusOptionsKm
                          .map(
                            (radius) => ChoiceChip(
                              label: Text('${radius.toInt()}km'),
                              selected: _radiusKm == radius,
                              onSelected: (_) => setState(() => _radiusKm = radius),
                            ),
                          )
                          .toList(),
                    ),
                    if (_searchType == DiscoverySearchType.workProviders) ...[
                      const SizedBox(height: AppSpacing.l),
                      _label('FILTERS'),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Available now only'),
                        value: _availableOnly,
                        onChanged: (value) {
                          setState(() => _availableOnly = value);
                        },
                      ),
                      DropdownButtonFormField<double>(
                        initialValue: _minimumRating,
                        decoration: const InputDecoration(
                          labelText: 'Minimum rating',
                        ),
                        items: const [
                          DropdownMenuItem(value: 0, child: Text('Any')),
                          DropdownMenuItem(value: 3, child: Text('3+ stars')),
                          DropdownMenuItem(value: 4, child: Text('4+ stars')),
                          DropdownMenuItem(value: 4.5, child: Text('4.5+ stars')),
                        ],
                        onChanged: (value) {
                          setState(() => _minimumRating = value ?? 0);
                        },
                      ),
                    ],
                    const SizedBox(height: AppSpacing.l),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isResolvingLocation ? null : _startSearch,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                        ),
                        child: _isResolvingLocation
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Search'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Top Rated Near You', style: AppTextStyles.headingSmall),
                  TextButton(
                    onPressed: () => context.go('/best-providers'),
                    child: const Text('See All'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.m),
              topRatedAsync.when(
                loading: () => const SizedBox(
                  height: 180,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => Text(
                  error.toString(),
                  style: AppTextStyles.caption.copyWith(color: AppColors.errorRed),
                ),
                data: (results) {
                  if (results.isEmpty) {
                    return _SectionCard(
                      title: 'No nearby providers yet',
                      child: Text(
                        'Verified work providers will appear here once they are close to your saved location.',
                        style: AppTextStyles.bodyMedium,
                      ),
                    );
                  }

                  return SizedBox(
                    height: 220,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: results.take(10).length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final result = results[index];
                        final provider = result.user as WorkProviderModel;
                        return ProviderFeatureCard(
                          name: result.user.name,
                          profession: provider.profession ?? '',
                          rating: result.user.rating,
                          distance: '${result.distanceKm.toStringAsFixed(1)} km',
                          photoUrl: result.user.photoUrl,
                          isVerified: result.isVerified,
                          isAvailable: provider.isAvailableNow,
                          onTap: () {
                            context.push('/provider-profile/${result.user.id}');
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: AppTextStyles.labelSmall.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.headingSmall),
          const SizedBox(height: AppSpacing.m),
          child,
        ],
      ),
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  const _CategoryDropdown({
    required this.items,
    required this.value,
    required this.onChanged,
  });

  final List<String> items;
  final String value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
      ),
    );
  }
}
