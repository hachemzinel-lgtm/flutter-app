import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/location_service.dart';

class WpSearchScreen extends ConsumerStatefulWidget {
  const WpSearchScreen({super.key});

  @override
  ConsumerState<WpSearchScreen> createState() => _WpSearchScreenState();
}

class _WpSearchScreenState extends ConsumerState<WpSearchScreen> {
  final MapController _mapController = MapController();
  LatLng _currentLocation = const LatLng(36.8065, 10.1815);
  String _locationName = 'Loading location...';
  final double _radiusKm = 10.0;
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _marketplaceCategories = [
    {'label': 'Supplies', 'icon': Icons.inventory},
    {'label': 'Tools', 'icon': Icons.handyman},
    {'label': 'Hardware', 'icon': Icons.hardware},
    {'label': 'Parts', 'icon': Icons.build_circle},
  ];

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    final pos = await LocationService().getCurrentLocation();
    if (pos != null && mounted) {
      setState(() {
        _currentLocation = LatLng(pos.latitude, pos.longitude);
        _locationName = 'Current Location';
      });
      _mapController.move(_currentLocation, 13);
    }
  }

  void _onSearch() {
    final query = _searchController.text.trim();
    context.push('/search-results?query=$query&target=marketplace');
  }

  void _onCategorySearch(String cat) {
    context.push('/search-results?category=$cat&target=marketplace');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: Text('Search Marketplace', style: AppTextStyles.headingLarge),
        backgroundColor: AppColors.cardSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
          color: AppColors.textDark,
        ),
      ),
      body: Stack(
        children: [
          // 1. Map View
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: 13,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.nearwork.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentLocation,
                    width: 20, height: 20,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.accentBlue,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentBlue.withValues(alpha: 0.3),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // 2. Overlay UI
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  // Location Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: AppColors.accentBlue, size: 20),
                        const SizedBox(width: 8),
                        Text(_locationName, style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.bold)),
                        const Spacer(),
                        Text('${_radiusKm.toInt()} km radius', style: AppTextStyles.caption.copyWith(color: AppColors.accentBlue)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Search Bar locked to marketplace
                  _buildSearchBar(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.search, color: AppColors.softGray),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onSubmitted: (_) => _onSearch(),
                  style: AppTextStyles.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'Search products and shops...',
                    hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.softGray),
                    border: InputBorder.none,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _onSearch,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accentBlue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.arrow_forward, size: 20, color: AppColors.white),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _marketplaceCategories.length,
            itemBuilder: (context, index) {
              final cat = _marketplaceCategories[index];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  avatar: Icon(cat['icon'], size: 16, color: AppColors.accentBlue),
                  label: Text(cat['label'], style: AppTextStyles.labelSmall),
                  backgroundColor: AppColors.white,
                  side: BorderSide(color: AppColors.softGray.withValues(alpha: 0.2)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  onPressed: () => _onCategorySearch(cat['label']),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
