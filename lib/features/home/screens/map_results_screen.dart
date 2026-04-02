import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/models/marketplace_model.dart';
import '../../../core/models/work_provider_model.dart';
import '../models/discovery_models.dart';
import '../providers/home_provider.dart';

class MapResultsScreen extends ConsumerStatefulWidget {
  const MapResultsScreen({
    super.key,
    required this.searchType,
    required this.category,
    required this.radiusKm,
    required this.minimumRating,
    required this.availableOnly,
    required this.originLatitude,
    required this.originLongitude,
    required this.originLabel,
  });

  final String searchType;
  final String category;
  final double radiusKm;
  final double minimumRating;
  final bool availableOnly;
  final double originLatitude;
  final double originLongitude;
  final String originLabel;

  @override
  ConsumerState<MapResultsScreen> createState() => _MapResultsScreenState();
}

class _MapResultsScreenState extends ConsumerState<MapResultsScreen> {
  final MapController _mapController = MapController();
  late DiscoverySearchType _type;
  late String _category;
  late double _radiusKm;
  late double _minimumRating;
  late bool _availableOnly;
  late DiscoverySearchLocation _location;

  @override
  void initState() {
    super.initState();
    _type = DiscoverySearchType.fromQuery(widget.searchType);
    _category = widget.category;
    _radiusKm = widget.radiusKm;
    _minimumRating = widget.minimumRating;
    _availableOnly = widget.availableOnly;
    _location = DiscoverySearchLocation(
      center: LatLng(widget.originLatitude, widget.originLongitude),
      label: widget.originLabel,
    );
  }

  DiscoverySearchRequest get _request => DiscoverySearchRequest(
        type: _type,
        category: _category,
        radiusKm: _radiusKm,
        minimumRating: _minimumRating,
        availableOnly: _availableOnly,
        location: _location,
      );

  Future<void> _openFilterSheet() async {
    double draftRadius = _radiusKm;
    double draftRating = _minimumRating;
    bool draftAvailable = _availableOnly;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.l,
                right: AppSpacing.l,
                top: AppSpacing.l,
                bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.l,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Adjust filters', style: AppTextStyles.headingSmall),
                  const SizedBox(height: AppSpacing.m),
                  Text(
                    'Search radius: ${draftRadius.toInt()} km',
                    style: AppTextStyles.bodyMedium,
                  ),
                  Slider(
                    value: draftRadius,
                    min: 5,
                    max: 50,
                    divisions: 9,
                    onChanged: (value) => setModalState(() => draftRadius = value),
                  ),
                  if (_type == DiscoverySearchType.workProviders) ...[
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Available now only'),
                      value: draftAvailable,
                      onChanged: (value) {
                        setModalState(() => draftAvailable = value);
                      },
                    ),
                    DropdownButtonFormField<double>(
                      initialValue: draftRating,
                      decoration: const InputDecoration(labelText: 'Minimum rating'),
                      items: const [
                        DropdownMenuItem(value: 0, child: Text('Any')),
                        DropdownMenuItem(value: 3, child: Text('3+ stars')),
                        DropdownMenuItem(value: 4, child: Text('4+ stars')),
                        DropdownMenuItem(value: 4.5, child: Text('4.5+ stars')),
                      ],
                      onChanged: (value) {
                        setModalState(() => draftRating = value ?? 0);
                      },
                    ),
                  ],
                  const SizedBox(height: AppSpacing.l),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _radiusKm = draftRadius;
                          _minimumRating = draftRating;
                          _availableOnly = draftAvailable;
                        });
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentBlue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Apply filters'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final resultsAsync = ref.watch(searchResultsProvider(_request));

    return Scaffold(
      body: Stack(
        children: [
          resultsAsync.when(
            loading: () => FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _location.center,
                initialZoom: 12.5,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.nearwork.app',
                ),
              ],
            ),
            error: (error, _) => Center(
              child: Padding(
                padding: AppSpacing.pagePadding,
                child: Text(
                  error.toString(),
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.errorRed),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            data: (results) {
              final markers = results
                  .map(
                    (result) => Marker(
                      point: LatLng(
                        result.user.location!.latitude,
                        result.user.location!.longitude,
                      ),
                      width: 64,
                      height: 64,
                      child: GestureDetector(
                        onTap: () {
                          if (_type == DiscoverySearchType.workProviders) {
                            context.push('/provider-profile/${result.user.id}');
                          } else {
                            context.push('/merchant-profile/${result.user.id}');
                          }
                        },
                        child: _MarkerAvatar(result: result),
                      ),
                    ),
                  )
                  .toList();

              return FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _location.center,
                  initialZoom: 12.5,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.nearwork.app',
                  ),
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: _location.center,
                        radius: _radiusKm * 1000,
                        useRadiusInMeter: true,
                        color: AppColors.accentBlue.withValues(alpha: 0.08),
                        borderColor: AppColors.accentBlue.withValues(alpha: 0.45),
                        borderStrokeWidth: 2,
                      ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _location.center,
                        width: 30,
                        height: 30,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.accentBlue,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                        ),
                      ),
                      ...markers,
                    ],
                  ),
                ],
              );
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.m),
              child: Column(
                children: [
                  Row(
                    children: [
                      _MapActionButton(
                        icon: Icons.arrow_back_rounded,
                        onTap: () => context.pop(),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _type == DiscoverySearchType.workProviders
                                    ? 'Work Providers'
                                    : 'Marketplaces',
                                style: AppTextStyles.headingSmall,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _location.label,
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _MapActionButton(
                        icon: Icons.tune_rounded,
                        onTap: _openFilterSheet,
                      ),
                    ],
                  ),
                  const Spacer(),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _MapActionButton(
                          icon: Icons.add_rounded,
                          onTap: () {
                            _mapController.move(
                              _mapController.camera.center,
                              _mapController.camera.zoom + 1,
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        _MapActionButton(
                          icon: Icons.remove_rounded,
                          onTap: () {
                            _mapController.move(
                              _mapController.camera.center,
                              _mapController.camera.zoom - 1,
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        _MapActionButton(
                          icon: Icons.my_location_rounded,
                          onTap: () => _mapController.move(_location.center, 12.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  Consumer(
                    builder: (context, ref, _) {
                      final resultsValue = ref.watch(searchResultsProvider(_request));
                      return resultsValue.when(
                        loading: () => const SizedBox(
                          width: double.infinity,
                          child: Card(
                            child: Padding(
                              padding: EdgeInsets.all(AppSpacing.m),
                              child: LinearProgressIndicator(),
                            ),
                          ),
                        ),
                        error: (_, _) => const SizedBox.shrink(),
                        data: (results) {
                          if (results.isEmpty) {
                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.m),
                                child: Text(
                                  'No results matched the current filters.',
                                  style: AppTextStyles.bodyMedium,
                                ),
                              ),
                            );
                          }

                          return Container(
                            width: double.infinity,
                            constraints: const BoxConstraints(maxHeight: 220),
                            padding: const EdgeInsets.all(AppSpacing.m),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${results.length} result${results.length == 1 ? '' : 's'}',
                                  style: AppTextStyles.headingSmall,
                                ),
                                const SizedBox(height: AppSpacing.s),
                                Expanded(
                                  child: ListView.separated(
                                    itemCount: results.length,
                                    separatorBuilder: (_, _) =>
                                        const SizedBox(height: 10),
                                    itemBuilder: (context, index) {
                                      final result = results[index];
                                      final title = _type ==
                                              DiscoverySearchType.workProviders
                                          ? result.user.name
                                          : (result.user is MarketplaceModel
                                              ? (result.user as MarketplaceModel)
                                                      .businessName ??
                                                  result.user.name
                                              : result.user.name);
                                      final subtitle = _type ==
                                              DiscoverySearchType.workProviders
                                          ? (result.user as WorkProviderModel)
                                                  .profession ??
                                              'Work Provider'
                                          : (result.user as MarketplaceModel)
                                                  .category ??
                                              'Marketplace';

                                      return ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        leading: CircleAvatar(
                                          backgroundImage: result.user.photoUrl == null
                                              ? null
                                              : NetworkImage(result.user.photoUrl!),
                                          backgroundColor:
                                              AppColors.accentBlue.withValues(alpha: 0.12),
                                          child: result.user.photoUrl == null
                                              ? Text(
                                                  title.substring(0, 1).toUpperCase(),
                                                  style: AppTextStyles.headingSmall.copyWith(
                                                    color: AppColors.accentBlue,
                                                  ),
                                                )
                                              : null,
                                        ),
                                        title: Text(title),
                                        subtitle: Text(
                                          '$subtitle • ${result.distanceKm.toStringAsFixed(1)} km',
                                        ),
                                        trailing: const Icon(
                                          Icons.chevron_right_rounded,
                                        ),
                                        onTap: () {
                                          if (_type ==
                                              DiscoverySearchType.workProviders) {
                                            context.push('/provider-profile/${result.user.id}');
                                          } else {
                                            context.push('/merchant-profile/${result.user.id}');
                                          }
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapActionButton extends StatelessWidget {
  const _MapActionButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, color: AppColors.primaryNavy),
        ),
      ),
    );
  }
}

class _MarkerAvatar extends StatelessWidget {
  const _MarkerAvatar({required this.result});

  final DiscoverySearchResult result;

  @override
  Widget build(BuildContext context) {
    final child = result.user.photoUrl == null
        ? Text(
            result.user.name.substring(0, 1).toUpperCase(),
            style: AppTextStyles.headingSmall.copyWith(
              color: AppColors.accentBlue,
            ),
          )
        : null;

    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(
              color: result.isVerified ? AppColors.starGold : AppColors.accentBlue,
              width: 3,
            ),
            image: result.user.photoUrl == null
                ? null
                : DecorationImage(
                    image: NetworkImage(result.user.photoUrl!),
                    fit: BoxFit.cover,
                  ),
          ),
          child: child == null ? null : Center(child: child),
        ),
        Container(
          width: 4,
          height: 10,
          decoration: BoxDecoration(
            color: result.isVerified ? AppColors.starGold : AppColors.accentBlue,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
      ],
    );
  }
}
