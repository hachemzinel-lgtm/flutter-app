import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
// import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/models/user_model.dart';
import '../../../core/models/work_provider_model.dart';
import '../../../core/models/marketplace_model.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/distance_service.dart';
import '../models/discovery_models.dart';
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
  
  final double _searchRadiusKm = 10.0;
  String _selectedCategory = 'All';
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
          // Default logic
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



  double _distanceKm(double lat, double lng) {
    return DistanceService().calculateDistance(lat, lng, _activeLocation.latitude, _activeLocation.longitude);
  }



  @override
  Widget build(BuildContext context) {
    final providersAsync = ref.watch(providersStreamProvider(DiscoverySearchType.workProviders));

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
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: _activeLocation,
                    color: AppColors.accentBlue.withValues(alpha: 0.1),
                    borderColor: AppColors.accentBlue.withValues(alpha: 0.3),
                    borderStrokeWidth: 1,
                    useRadiusInMeter: true,
                    radius: _searchRadiusKm * 1000, 
                  ),
                ],
              ),

              // Providers markers
              providersAsync.when(
                data: (allResults) {
                  final filtered = _selectedCategory == 'All'
                      ? allResults
                      : allResults.where((r) {
                          final user = r.user;
                          final category = user is WorkProviderModel 
                              ? user.profession 
                              : (user is MarketplaceModel ? user.category : '');
                          return category == _selectedCategory;
                        }).toList();

                  return MarkerLayer(
                    markers: filtered.where((r) => r.user.location != null).map((result) {
                      final user = result.user;
                      final lat = user.location!.latitude;
                      final lng = user.location!.longitude;
                      
                      return Marker(
                        point: LatLng(lat, lng),
                        width: 60, height: 60,
                        child: MapMarkerWidget(
                          imageUrl: user.photoUrl,
                          rating: user.rating,
                          category: user is WorkProviderModel ? user.profession ?? '' : '',
                          isVerified: user is WorkProviderModel && user.verificationStatus == VerificationStatus.approved.name,
                          onTap: () => _showProviderPopup(context, user),
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
                // Removed Location Search & Display Banner per requirements

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

                // --- TOP RIGHT ACTIONS ---
                Positioned(
                  top: AppSpacing.m,
                  right: AppSpacing.m,
                  child: Row(
                    children: [
                      _mapActionButton(
                        icon: Icons.tune,
                        onTap: () => context.push('/search-results'), // In real app, this opens filter sheet
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // --- ZOOM CONTROLS ---
          Positioned(
            right: 16,
            bottom: 180,
            child: Column(
              children: [
                _mapActionButton(
                  icon: Icons.add,
                  onTap: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1),
                ),
                const SizedBox(height: 8),
                _mapActionButton(
                  icon: Icons.remove,
                  onTap: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1),
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
      // Using ShellRoute for Navigation, so bottomNavigationBar is removed from here.
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

  Widget _mapActionButton({required IconData icon, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: IconButton(
        icon: Icon(icon, color: AppColors.accentBlue),
        onPressed: onTap,
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


  void _showProviderPopup(BuildContext context, UserModel user) {
    if (user.location == null) return;
    final double lat = user.location!.latitude;
    final double lng = user.location!.longitude;
    final double km = _distanceKm(lat, lng);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ProviderPopupCard(user: user, distanceKm: km),
    );
  }
}
