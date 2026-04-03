import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/marketplace_taxonomy.dart';
import '../../../core/models/marketplace_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/home_provider.dart';

class MarketplaceHomeScreen extends ConsumerStatefulWidget {
  const MarketplaceHomeScreen({super.key});

  @override
  ConsumerState<MarketplaceHomeScreen> createState() =>
      _MarketplaceHomeScreenState();
}

class _MarketplaceHomeScreenState extends ConsumerState<MarketplaceHomeScreen> {
  final _manualAddressController = TextEditingController();
  String _category = 'Any';
  double _radiusKm = 10;
  bool _useCurrentLocation = true;
  bool _loadingSearch = false;

  @override
  void dispose() {
    _manualAddressController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final user = ref.read(currentUserDocProvider).value;
    setState(() => _loadingSearch = true);
    try {
      final location = await ref
          .read(discoveryServiceProvider)
          .resolveSearchLocation(
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
        '?type=marketplace'
        '&category=${Uri.encodeComponent(_category)}'
        '&radius=$_radiusKm'
        '&minRating=0'
        '&availableOnly=false'
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
        setState(() => _loadingSearch = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserDocProvider).value;
    final marketplace = user is MarketplaceModel ? user : null;

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
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      marketplace?.businessName ?? 'Marketplace',
                      style: AppTextStyles.headingLarge.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s),
                    Text(
                      marketplace?.category ?? 'Local business',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.accentBlue,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.m),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _MetricPill(
                          label: 'Rating',
                          value: marketplace == null || marketplace.rating == 0
                              ? '--'
                              : marketplace.rating.toStringAsFixed(1),
                        ),
                        _MetricPill(
                          label: 'Reviews',
                          value: '${marketplace?.reviewCount ?? 0}',
                        ),
                        _MetricPill(
                          label: 'Location',
                          value: marketplace?.address?.isNotEmpty == true
                              ? 'Saved'
                              : 'Needed',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.l),
              TextField(
                readOnly: true,
                decoration: InputDecoration(
                  hintText: 'Find other marketplaces',
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
              Container(
                padding: const EdgeInsets.all(AppSpacing.l),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Search local businesses',
                      style: AppTextStyles.headingSmall,
                    ),
                    const SizedBox(height: AppSpacing.m),
                    DropdownButtonFormField<String>(
                      initialValue: _category,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items:
                          ['Any', ...MarketplaceTaxonomy.marketplaceCategories]
                              .map(
                                (item) => DropdownMenuItem(
                                  value: item,
                                  child: Text(item),
                                ),
                              )
                              .toList(),
                      onChanged: (value) =>
                          setState(() => _category = value ?? 'Any'),
                    ),
                    const SizedBox(height: AppSpacing.l),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Use my current location'),
                          selected: _useCurrentLocation,
                          onSelected: (_) =>
                              setState(() => _useCurrentLocation = true),
                        ),
                        ChoiceChip(
                          label: const Text('Use saved profile location'),
                          selected:
                              !_useCurrentLocation &&
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
                      decoration: const InputDecoration(
                        labelText: 'Or set location manually',
                        prefixIcon: Icon(Icons.edit_location_alt_outlined),
                      ),
                      onChanged: (_) {
                        if (_manualAddressController.text.trim().isNotEmpty) {
                          setState(() => _useCurrentLocation = false);
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.l),
                    Text('Distance radius', style: AppTextStyles.labelSmall),
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
                              onSelected: (_) =>
                                  setState(() => _radiusKm = radius),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: AppSpacing.l),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loadingSearch ? null : _search,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                        ),
                        child: _loadingSearch
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
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppTextStyles.headingSmall.copyWith(color: Colors.white),
          ),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
