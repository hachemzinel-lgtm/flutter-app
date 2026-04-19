import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/distance_service.dart';
import '../../../core/services/geocoding_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/widgets/primary_button.dart';
import '../providers/home_provider.dart';
import '../widgets/map_marker_widget.dart';
import '../widgets/provider_popup_card.dart';

/// Explore tab — OSM map with nearby service-provider markers.
///
/// Bottom-nav is owned by `MainScaffold`; this screen is the body of the
/// Explore tab only, so it does NOT render its own bottom nav bar.
class HomeMapScreen extends ConsumerStatefulWidget {
  const HomeMapScreen({super.key});

  @override
  ConsumerState<HomeMapScreen> createState() => _HomeMapScreenState();
}

class _HomeMapScreenState extends ConsumerState<HomeMapScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final TextEditingController _locationSearchController =
      TextEditingController();

  // Tunis as a sane default until GPS resolves.
  LatLng _currentGpsLocation = const LatLng(36.8065, 10.1815);
  LatLng? _selectedLocation;
  bool _useCustomLocation = false;

  double _searchRadiusKm = 10.0;
  String _selectedCategory = 'All';
  String _locationDisplayName = 'My Location';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _determinePosition());
  }

  @override
  void dispose() {
    _locationSearchController.dispose();
    super.dispose();
  }

  LatLng get _activeLocation =>
      _useCustomLocation && _selectedLocation != null
          ? _selectedLocation!
          : _currentGpsLocation;

  Future<void> _determinePosition() async {
    final position = await LocationService().getCurrentLocation();
    if (position == null || !mounted) return;
    setState(() {
      _currentGpsLocation = LatLng(position.latitude, position.longitude);
      if (!_useCustomLocation) _locationDisplayName = 'My Location';
    });
    if (!_useCustomLocation) _animatedMapMove(_currentGpsLocation, 13);
  }

  void _animatedMapMove(LatLng dest, double destZoom) {
    final latTween = Tween<double>(
        begin: _mapController.camera.center.latitude, end: dest.latitude);
    final lngTween = Tween<double>(
        begin: _mapController.camera.center.longitude, end: dest.longitude);
    final zoomTween =
        Tween<double>(begin: _mapController.camera.zoom, end: destZoom);

    final controller = AnimationController(
        duration: const Duration(milliseconds: 300), vsync: this);
    final curve =
        CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn);
    controller.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(curve), lngTween.evaluate(curve)),
        zoomTween.evaluate(curve),
      );
    });
    curve.addStatusListener((s) {
      if (s == AnimationStatus.completed || s == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });
    controller.forward();
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    setState(() => _selectedLocation = point);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _grabHandle(),
            const SizedBox(height: AppSpacing.l),
            const Icon(Icons.location_on,
                color: AppColors.accentBlue, size: 48),
            const SizedBox(height: 8),
            Text('Location Selected', style: AppTextStyles.headingSmall),
            const SizedBox(height: 4),
            Text(
              '${point.latitude.toStringAsFixed(4)}, '
              '${point.longitude.toStringAsFixed(4)}',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _selectedLocation = null;
                        _useCustomLocation = false;
                      });
                      Navigator.pop(ctx);
                    },
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: PrimaryButton(
                    text: 'Confirm',
                    onPressed: () {
                      setState(() {
                        _useCustomLocation = true;
                        _locationDisplayName = 'Pinned location';
                      });
                      Navigator.pop(ctx);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.m),
          ],
        ),
      ),
    );
  }

  void _showIntentModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _grabHandle(),
            const SizedBox(height: AppSpacing.l),
            Text('What are you looking for?',
                style: AppTextStyles.headingMedium),
            const SizedBox(height: AppSpacing.l),
            _intentOption(
              icon: Icons.handyman_outlined,
              title: 'Find a Service Provider',
              subtitle: 'Search for plumbers, electricians, etc.',
              onTap: () {
                Navigator.pop(ctx);
                context.push('/search-results');
              },
            ),
            const SizedBox(height: AppSpacing.m),
            _intentOption(
              icon: Icons.storefront_outlined,
              title: 'Search Marketplace',
              subtitle: 'Browse products and supplies',
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Marketplace coming soon!')));
              },
            ),
            const SizedBox(height: AppSpacing.l),
          ],
        ),
      ),
    );
  }

  Widget _intentOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.m),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderLight),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: AppColors.accentBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle),
              child: Icon(icon, color: AppColors.accentBlue, size: 28),
            ),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.headingSmall),
                  const SizedBox(height: 4),
                  Text(subtitle, style: AppTextStyles.bodyMedium),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.softGray),
          ],
        ),
      ),
    );
  }

  double _distanceKm(double lat, double lng) {
    return DistanceService().calculateDistance(
        lat, lng, _activeLocation.latitude, _activeLocation.longitude);
  }

  void _showAddressSearchModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: AppSpacing.l,
          right: AppSpacing.l,
          top: AppSpacing.l,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _grabHandle(),
            const SizedBox(height: AppSpacing.l),
            TextField(
              controller: _locationSearchController,
              decoration: InputDecoration(
                hintText: 'Search location or enter address',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: _locationSearchController.clear,
                ),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onSubmitted: (value) async {
                if (value.trim().isEmpty) return;
                final loc =
                    await GeocodingService().geocodeAddress(value.trim());
                if (!mounted) return;
                if (loc == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Address not found')));
                  return;
                }
                setState(() {
                  _selectedLocation = LatLng(loc.latitude, loc.longitude);
                  _useCustomLocation = true;
                  _locationDisplayName = value.trim();
                });
                _animatedMapMove(_selectedLocation!, 13);
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('📍 Searching near $value')));
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _grabHandle() => Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.softGray.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final providersAsync = ref.watch(providersStreamProvider);

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentGpsLocation,
              initialZoom: 13,
              onTap: _onMapTap,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.nearwork',
              ),

              // Radius circle drawn around the ACTIVE location (GPS or
              // pinned) so users always see the search area, not only
              // when they pinned manually.
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: _activeLocation,
                    color: AppColors.accentBlue.withValues(alpha: 0.10),
                    borderColor:
                        AppColors.accentBlue.withValues(alpha: 0.45),
                    borderStrokeWidth: 2,
                    useRadiusInMeter: true,
                    radius: _searchRadiusKm * 1000,
                  ),
                ],
              ),

              providersAsync.when(
                data: (allProviders) {
                  final filtered = _applyFilters(allProviders);
                  return MarkerLayer(
                    markers: filtered.map((p) {
                      final lat = (p['lat'] as num).toDouble();
                      final lng = (p['lng'] as num).toDouble();
                      return Marker(
                        point: LatLng(lat, lng),
                        width: 60,
                        height: 60,
                        child: MapMarkerWidget(
                          rating: (p['rating'] as num?)?.toDouble() ?? 0,
                          category:
                              p['profession'] ?? p['category'] ?? '',
                          onTap: () => _showProviderPopup(context, p),
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const MarkerLayer(markers: []),
                error: (_, __) => const MarkerLayer(markers: []),
              ),

              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentGpsLocation,
                    width: 20,
                    height: 20,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.accentBlue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                              color: AppColors.accentBlue
                                  .withValues(alpha: 0.4),
                              blurRadius: 8),
                        ],
                      ),
                    ),
                  ),
                  if (_useCustomLocation && _selectedLocation != null)
                    Marker(
                      point: _selectedLocation!,
                      width: 40,
                      height: 40,
                      alignment: Alignment.topCenter,
                      child: const Icon(Icons.location_on,
                          color: AppColors.accentBlue, size: 40),
                    ),
                ],
              ),
            ],
          ),

          SafeArea(
            child: Column(
              children: [
                GestureDetector(
                  onTap: _showAddressSearchModal,
                  child: Container(
                    margin:
                        const EdgeInsets.only(top: 8, left: 16, right: 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10)
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on,
                            color: AppColors.accentBlue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _useCustomLocation
                                ? '📍 $_locationDisplayName'
                                : '📍 My Location',
                            style: AppTextStyles.headingSmall
                                .copyWith(fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_useCustomLocation)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _useCustomLocation = false;
                                _selectedLocation = null;
                                _locationDisplayName = 'My Location';
                              });
                              _animatedMapMove(_currentGpsLocation, 13);
                            },
                            child: const Icon(Icons.close,
                                size: 20, color: AppColors.softGray),
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  child: GestureDetector(
                    onTap: _showIntentModal,
                    child: Container(
                      height: 56,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.borderRadius),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search,
                              color: AppColors.softGray),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Search plumbers, electricians...',
                              style: AppTextStyles.bodyMedium
                                  .copyWith(color: AppColors.softGray),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundSecondary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.tune,
                                size: 20, color: AppColors.accentBlue),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Radius slider pill — tap to expand, drag to change.
          Positioned(
            bottom: 180,
            right: 16,
            child: _RadiusSliderPill(
              radiusKm: _searchRadiusKm,
              onChanged: (v) => setState(() => _searchRadiusKm = v),
            ),
          ),

          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: _buildCategoryFilters(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'my_location',
        onPressed: () {
          setState(() {
            _useCustomLocation = false;
            _selectedLocation = null;
            _locationDisplayName = 'My Location';
          });
          _determinePosition();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('📍 Centered on your location')));
        },
        backgroundColor: AppColors.accentBlue,
        shape: const CircleBorder(),
        child: const Icon(Icons.my_location, color: Colors.white),
      ),
    );
  }

  /// Applies category + radius filters, then sorts by distance.
  ///
  /// Providers without coordinates are silently dropped — they can't be
  /// placed on the map anyway. Providers outside the radius are dropped
  /// so markers stay coherent with the visible search circle.
  List<Map<String, dynamic>> _applyFilters(List<Map<String, dynamic>> all) {
    final byCategory = _selectedCategory == 'All'
        ? all
        : all
            .where((p) =>
                (p['category'] ?? p['profession'] ?? '') ==
                _selectedCategory)
            .toList();

    final withCoords = byCategory.where((p) {
      final lat = (p['lat'] as num?)?.toDouble();
      final lng = (p['lng'] as num?)?.toDouble();
      return lat != null && lng != null;
    }).toList();

    // Enrich with distance and filter by radius.
    for (final p in withCoords) {
      p['_distanceKm'] = _distanceKm(
          (p['lat'] as num).toDouble(), (p['lng'] as num).toDouble());
    }
    withCoords.removeWhere(
        (p) => ((p['_distanceKm'] as num?)?.toDouble() ?? double.infinity) >
            _searchRadiusKm);

    withCoords.sort((a, b) {
      final da = (a['_distanceKm'] as num?)?.toDouble() ?? double.infinity;
      final db = (b['_distanceKm'] as num?)?.toDouble() ?? double.infinity;
      return da.compareTo(db);
    });
    return withCoords;
  }

  Widget _buildCategoryFilters() {
    final categories = [
      'All',
      'Plumber',
      'Electrician',
      'Mason',
      'Painter',
      'Carpenter',
    ];
    final icons = {
      'All': Icons.apps,
      'Plumber': Icons.plumbing,
      'Electrician': Icons.electrical_services,
      'Mason': Icons.architecture,
      'Painter': Icons.format_paint,
      'Carpenter': Icons.handyman,
    };

    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              // Category chips now JUST filter the map markers. The
              // previous behavior pushed the user to /search-results for
              // every non-All tap — it's more useful to narrow the map
              // first and let the search bar handle list navigation.
              onTap: () => setState(() => _selectedCategory = cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.accentBlue : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.accentBlue
                        : AppColors.borderLight,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.accentBlue
                                .withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(icons[cat] ?? Icons.category,
                        size: 16,
                        color: isSelected
                            ? Colors.white
                            : AppColors.softGray),
                    const SizedBox(width: 6),
                    Text(
                      cat,
                      style: TextStyle(
                        color:
                            isSelected ? Colors.white : AppColors.textDark,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showProviderPopup(
      BuildContext context, Map<String, dynamic> provider) {
    final lat = (provider['lat'] as num?)?.toDouble() ??
        _currentGpsLocation.latitude;
    final lng = (provider['lng'] as num?)?.toDouble() ??
        _currentGpsLocation.longitude;
    final km = _distanceKm(lat, lng);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          ProviderPopupCard(provider: provider, distanceKm: km),
    );
  }
}

/// Collapsible radius-slider pill anchored to the right edge of the map.
///
/// Tap to expand/collapse. We keep it as a pill (not an inline slider
/// across the bottom) because the bottom is already crowded with the
/// category-filter row and the FAB.
class _RadiusSliderPill extends StatefulWidget {
  final double radiusKm;
  final ValueChanged<double> onChanged;
  const _RadiusSliderPill({
    required this.radiusKm,
    required this.onChanged,
  });

  @override
  State<_RadiusSliderPill> createState() => _RadiusSliderPillState();
}

class _RadiusSliderPillState extends State<_RadiusSliderPill> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      width: _expanded ? 220 : 64,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _expanded ? _expandedView() : _collapsedView(),
    );
  }

  Widget _collapsedView() {
    return InkWell(
      onTap: () => setState(() => _expanded = true),
      borderRadius: BorderRadius.circular(32),
      child: SizedBox(
        height: 48,
        child: Center(
          child: Text(
            '${widget.radiusKm.toStringAsFixed(0)} km',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.accentBlue,
            ),
          ),
        ),
      ),
    );
  }

  Widget _expandedView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Icon(Icons.radar, color: AppColors.accentBlue, size: 20),
          SizedBox(
            width: 120,
            child: Slider(
              value: widget.radiusKm.clamp(1, 50),
              min: 1,
              max: 50,
              divisions: 49,
              activeColor: AppColors.accentBlue,
              onChanged: widget.onChanged,
            ),
          ),
          Text('${widget.radiusKm.toStringAsFixed(0)}km',
              style: AppTextStyles.caption),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => setState(() => _expanded = false),
          ),
        ],
      ),
    );
  }
}
