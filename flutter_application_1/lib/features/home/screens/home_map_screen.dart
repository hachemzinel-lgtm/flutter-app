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
import '../providers/home_provider.dart';
import '../widgets/map_marker_widget.dart';
import '../widgets/provider_popup_card.dart';

class HomeMapScreen extends ConsumerStatefulWidget {
  const HomeMapScreen({super.key});

  @override
  ConsumerState<HomeMapScreen> createState() => _HomeMapScreenState();
}

class _HomeMapScreenState extends ConsumerState<HomeMapScreen> {
  final MapController _mapController = MapController();
  
  LatLng _currentGpsLocation = const LatLng(36.8065, 10.1815); // Default (Tunis)
  LatLng? _selectedLocation;
  bool _useCustomLocation = false;
  
  double _searchRadiusKm = 10.0;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    // Try to get location as soon as possible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _determinePosition();
    });
  }

  LatLng get _activeLocation => _useCustomLocation && _selectedLocation != null 
      ? _selectedLocation! 
      : _currentGpsLocation;

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getLastKnownPosition() ??
          await Geolocator.getCurrentPosition(
            timeLimit: const Duration(seconds: 5),
          );

      if (mounted) {
        setState(() {
          _currentGpsLocation = LatLng(position.latitude, position.longitude);
        });
        
        // Move map only if not using custom location
        if (!_useCustomLocation) {
          try {
            _mapController.move(_currentGpsLocation, 13);
          } catch (e) {
            debugPrint('MapController not ready yet: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
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
                decoration: BoxDecoration(color: AppColors.softGray.withOpacity(0.3), borderRadius: BorderRadius.circular(2)),
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
                decoration: BoxDecoration(color: AppColors.softGray.withOpacity(0.3), borderRadius: BorderRadius.circular(2)),
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
              decoration: BoxDecoration(color: AppColors.accentBlue.withOpacity(0.1), shape: BoxShape.circle),
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
      case 3: context.push('/notifications'); break;
      case 4: context.push('/edit-profile'); break;
    }
  }

  double _distanceKm(double lat, double lng) {
    const distance = Distance();
    return distance.as(LengthUnit.Kilometer, _activeLocation, LatLng(lat, lng));
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
                      color: AppColors.accentBlue.withOpacity(0.15),
                      borderColor: AppColors.accentBlue.withOpacity(0.5),
                      borderStrokeWidth: 2,
                      useRadiusInMeter: true,
                      radius: _searchRadiusKm * 1000, 
                    ),
                  ],
                ),

              // Providers markers
              providersAsync.when(
                data: (allProviders) {
                  final filtered = _selectedCategory == 'All'
                      ? allProviders
                      : allProviders.where((p) => (p['category'] ?? p['profession'] ?? '') == _selectedCategory).toList();

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
                        boxShadow: [BoxShadow(color: AppColors.accentBlue.withOpacity(0.4), blurRadius: 8)],
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
                // Location Mode Indicator
                if (_useCustomLocation)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.my_location, size: 16, color: AppColors.accentBlue),
                        const SizedBox(width: 8),
                        Text('Custom Location', style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _useCustomLocation = false;
                              _selectedLocation = null;
                            });
                            _mapController.move(_currentGpsLocation, 13);
                          },
                          child: const Icon(Icons.close, size: 16, color: AppColors.softGray),
                        ),
                      ],
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
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
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
        onPressed: () {
          setState(() {
            _useCustomLocation = false;
            _selectedLocation = null;
          });
          _determinePosition();
          _mapController.move(_currentGpsLocation, 13);
        },
        backgroundColor: Colors.white,
        child: const Icon(Icons.my_location, color: AppColors.accentBlue),
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
                  boxShadow: isSelected ? [BoxShadow(color: AppColors.accentBlue.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : null,
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.explore, 'EXPLORE', true, 0),
          _navItem(Icons.search, 'SEARCH', false, 1),
          _navItem(Icons.chat_bubble_outline, 'CHAT', false, 2),
          _navItem(Icons.notifications_none, 'ALERTS', false, 3),
          _navItem(Icons.person_outline, 'PROFILE', false, 4),
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
