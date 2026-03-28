import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/geocoding_service.dart';
import '../../../core/services/distance_service.dart';
import '../providers/home_provider.dart';
import '../widgets/map_marker_widget.dart';
import '../widgets/provider_popup_card.dart';

class HomeMapScreen extends ConsumerStatefulWidget {
  const HomeMapScreen({super.key});

  @override
  ConsumerState<HomeMapScreen> createState() => _HomeMapScreenState();
}

class _HomeMapScreenState extends ConsumerState<HomeMapScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  
  LatLng _currentGpsLocation = const LatLng(36.8065, 10.1815); // Default (Tunis)
  LatLng? _selectedLocation;
  bool _useCustomLocation = false;
  
  double _searchRadiusKm = 10.0;
  String _selectedCategory = 'All';
  String _locationDisplayName = 'My Location';
  final TextEditingController _locationSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Try to get location as soon as possible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _determinePosition();
    });
  }

  @override
  void dispose() {
    _locationSearchController.dispose();
    super.dispose();
  }

  LatLng get _activeLocation => _useCustomLocation && _selectedLocation != null 
      ? _selectedLocation! 
      : _currentGpsLocation;

  Future<void> _determinePosition() async {
    final position = await LocationService().getCurrentLocation();
    if (position != null && mounted) {
      setState(() {
        _currentGpsLocation = LatLng(position.latitude, position.longitude);
        if (!_useCustomLocation) {
          _locationDisplayName = 'My Location';
        }
      });
      if (!_useCustomLocation) {
        _animatedMapMove(_currentGpsLocation, 13);
      }
    }
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    final latTween = Tween<double>(begin: _mapController.camera.center.latitude, end: destLocation.latitude);
    final lngTween = Tween<double>(begin: _mapController.camera.center.longitude, end: destLocation.longitude);
    final zoomTween = Tween<double>(begin: _mapController.camera.zoom, end: destZoom);

    final animationController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    final animation = CurvedAnimation(parent: animationController, curve: Curves.fastOutSlowIn);

    animationController.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
        animationController.dispose();
      }
    });

    animationController.forward();
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      _selectedLocation = point;
    });
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.softGray.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            const Icon(Icons.location_on, color: AppColors.accentBlue, size: 48),
            const SizedBox(height: 8),
            Text('Location Selected', style: AppTextStyles.headingSmall),
            const SizedBox(height: 4),
            Text(
              '${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}',
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
                      setState(() => _useCustomLocation = true);
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.softGray.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            Text('What are you looking for?', style: AppTextStyles.headingMedium),
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
                  const SnackBar(content: Text('Marketplace coming soon!')),
                );
              },
            ),
            const SizedBox(height: AppSpacing.l),
          ],
        ),
      ),
    );
  }

  Widget _intentOption({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
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
              decoration: BoxDecoration(color: AppColors.accentBlue.withValues(alpha: 0.1), shape: BoxShape.circle),
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

  void _onBottomNavTapped(int index) {
    if (index == 0) return;
    switch (index) {
      case 1: context.push('/search-results'); break;
      case 2: context.push('/conversations'); break;
      case 3: context.push('/chat-bot'); break; // AI Helper Tab
      case 4: context.push('/notifications'); break;
      case 5: context.push('/edit-profile'); break;
    }
  }

  double _distanceKm(double lat, double lng) {
    return DistanceService().calculateDistance(lat, lng, _activeLocation.latitude, _activeLocation.longitude);
  }

  void _showAddressSearchModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.softGray.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            TextField(
              controller: _locationSearchController,
              decoration: InputDecoration(
                hintText: 'Search location or enter address',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => _locationSearchController.clear(),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onSubmitted: (value) async {
                if (value.isNotEmpty) {
                  final loc = await GeocodingService().geocodeAddress(value);
                  if (loc != null) {
                    setState(() {
                      _selectedLocation = LatLng(loc.latitude, loc.longitude);
                      _useCustomLocation = true;
                      _locationDisplayName = value;
                    });
                    
                    _animatedMapMove(_selectedLocation!, 13);
                    
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('📍 Searching near $value')),
                      );
                      Navigator.pop(ctx);
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Address not found')),
                      );
                    }
                  }
                }
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final providersAsync = ref.watch(providersStreamProvider);

    return Scaffold(
      body: Stack(
        children: [
          // --- CONSOLIDATED MAP (Single instance to avoid controller issues) ---
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
              
              // Radius Circle
              if (_useCustomLocation && _selectedLocation != null)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: _selectedLocation!,
                      color: AppColors.accentBlue.withValues(alpha: 0.15),
                      borderColor: AppColors.accentBlue.withValues(alpha: 0.5),
                      borderStrokeWidth: 2,
                      useRadiusInMeter: true,
                      radius: _searchRadiusKm * 1000, 
                    ),
                  ],
                ),

              // Providers markers
              providersAsync.when(
                data: (allProviders) {
                  List<Map<String, dynamic>> filtered = _selectedCategory == 'All'
                      ? List.from(allProviders)
                      : allProviders.where((p) => (p['category'] ?? p['profession'] ?? '') == _selectedCategory).toList();
                  
                  // Sort by distance
                  filtered = DistanceService().sortWorkersByDistance(filtered, _activeLocation.latitude, _activeLocation.longitude);

                  return MarkerLayer(
                    markers: filtered.where((p) => p['lat'] != null && p['lng'] != null).map((provider) {
                      final double? lat = (provider['lat'] as num?)?.toDouble();
                      final double? lng = (provider['lng'] as num?)?.toDouble();
                      if (lat == null || lng == null) return const Marker(point: LatLng(0,0), width: 0, height: 0, child: SizedBox());
                      
                      return Marker(
                        point: LatLng(lat, lng),
                        width: 60, height: 60,
                        child: MapMarkerWidget(
                          rating: (provider['rating'] as num?)?.toDouble() ?? 4.5,
                          category: provider['profession'] ?? provider['category'] ?? '',
                          onTap: () => _showProviderPopup(context, provider),
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const MarkerLayer(markers: []),
                error: (e, _) => const MarkerLayer(markers: []),
              ),

              // Core Markers (GPS Dot & Selection Pin) are always shown
              MarkerLayer(
                markers: [
                  // GPS Location Dot
                  Marker(
                    point: _currentGpsLocation,
                    width: 20, height: 20,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.accentBlue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [BoxShadow(color: AppColors.accentBlue.withValues(alpha: 0.4), blurRadius: 8)],
                      ),
                    ),
                  ),
                  
                  // Custom Location Pin
                  if (_selectedLocation != null)
                    Marker(
                      point: _selectedLocation!,
                      width: 40, height: 40,
                      alignment: Alignment.topCenter,
                      child: const Icon(Icons.location_on, color: AppColors.accentBlue, size: 40),
                    ),
                ],
              ),
            ],
          ),

          // --- OVERLAYS ---
          SafeArea(
            child: Column(
              children: [
                // Location Search & Display Banner
                GestureDetector(
                  onTap: _showAddressSearchModal,
                  child: Container(
                    margin: const EdgeInsets.only(top: 8, left: 16, right: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: AppColors.accentBlue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _useCustomLocation ? '📍 $_locationDisplayName' : '📍 My Location',
                            style: AppTextStyles.headingSmall.copyWith(fontSize: 14),
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
                            child: const Icon(Icons.close, size: 20, color: AppColors.softGray),
                          ),
                      ],
                    ),
                  ),
                ),

                // --- SEARCH BAR (Read-only Button) ---
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  child: GestureDetector(
                    onTap: _showIntentModal,
                    child: Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search, color: AppColors.softGray),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Search plumbers, electricians...',
                              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.softGray),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: AppColors.backgroundSecondary, borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.tune, size: 20, color: AppColors.accentBlue),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- CATEGORY FILTERS ---
          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: _buildCategoryFilters(),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: FloatingActionButton(
        heroTag: 'my_location',
        onPressed: () {
          setState(() {
            _useCustomLocation = false;
            _selectedLocation = null;
          });
          _determinePosition();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('📍 Centered on your location')),
          );
        },
        backgroundColor: AppColors.accentBlue,
        shape: const CircleBorder(),
        child: const Icon(Icons.my_location, color: Colors.white),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    final categories = ['All', 'Plumber', 'Electrician', 'Mason', 'Painter', 'Carpenter'];
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
              onTap: () {
                if (cat == 'All') {
                  setState(() => _selectedCategory = 'All');
                } else {
                  setState(() => _selectedCategory = cat);
                  context.push('/search-results?category=$cat');
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.accentBlue : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: isSelected ? AppColors.accentBlue : AppColors.borderLight),
                  boxShadow: isSelected ? [BoxShadow(color: AppColors.accentBlue.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))] : null,
                ),
                child: Row(
                  children: [
                    Icon(icons[cat] ?? Icons.category, size: 16, color: isSelected ? Colors.white : AppColors.softGray),
                    const SizedBox(width: 6),
                    Text(
                      cat,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textDark,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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

  Widget _buildBottomNav() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.explore, 'EXPLORE', true, 0),
          _navItem(Icons.search, 'SEARCH', false, 1),
          _navItem(Icons.chat_bubble_outline, 'CHAT', false, 2),
          _navItem(Icons.smart_toy, 'ASK AI', false, 3), // NEW AI Tab
          _navItem(Icons.notifications_none, 'ALERTS', false, 4),
          _navItem(Icons.person_outline, 'PROFILE', false, 5),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool isSelected, int index) {
    return GestureDetector(
      onTap: () => _onBottomNavTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isSelected ? AppColors.accentBlue : AppColors.softGray),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: isSelected ? AppColors.accentBlue : AppColors.softGray,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  void _showProviderPopup(BuildContext context, Map<String, dynamic> provider) {
    final double lat = (provider['lat'] as num?)?.toDouble() ?? _currentGpsLocation.latitude;
    final double lng = (provider['lng'] as num?)?.toDouble() ?? _currentGpsLocation.longitude;
    final double km = _distanceKm(lat, lng);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ProviderPopupCard(provider: provider, distanceKm: km),
    );
  }
}
