import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/models/user_model.dart';

class MapResultsScreen extends ConsumerStatefulWidget {
  final String category;
  final String searchType; // 'provider' or 'marketplace'

  const MapResultsScreen({
    super.key,
    required this.category,
    required this.searchType,
  });

  @override
  ConsumerState<MapResultsScreen> createState() => _MapResultsScreenState();
}

class _MapResultsScreenState extends ConsumerState<MapResultsScreen> {
  final MapController _mapController = MapController();
  LatLng? _userLocation;
  List<UserModel> _results = [];
  bool _isLoading = true;
  UserModel? _selectedUser;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _getLocation();
    await _loadResults();
  }

  Future<void> _getLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition();
      setState(() => _userLocation = LatLng(pos.latitude, pos.longitude));
    } catch (_) {
      // Default to Algiers if location fails
      setState(() => _userLocation = const LatLng(36.7372, 3.0865));
    }
  }

  Future<void> _loadResults() async {
    setState(() => _isLoading = true);
    try {
      final accountType = widget.searchType == 'provider' ? 'workProvider' : 'marketplace';
      Query query = FirebaseFirestore.instance
          .collection('users')
          .where('accountType', isEqualTo: accountType)
          .where('isBanned', isEqualTo: false);

      if (widget.category != 'Any' && widget.category.isNotEmpty) {
        final field = widget.searchType == 'provider' ? 'profession' : 'category';
        query = query.where(field, isEqualTo: widget.category);
      }
      if (widget.searchType == 'provider') {
        query = query.where('verificationStatus', isEqualTo: 'approved');
      }

      final snapshot = await query.limit(50).get();
      final users = snapshot.docs
          .map((doc) => UserModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .where((u) => u.location != null)
          .toList();

      setState(() => _results = users);
    } catch (e) {
      debugPrint('Error loading map results: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _openProfile(UserModel user) {
    setState(() => _selectedUser = user);
  }

  @override
  Widget build(BuildContext context) {
    final isProvider = widget.searchType == 'provider';
    return Scaffold(
      body: Stack(
        children: [
          // ── Map ───────────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _userLocation ?? const LatLng(36.7372, 3.0865),
              initialZoom: 13,
              onTap: (_, __) => setState(() => _selectedUser = null),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.nearwork.app',
              ),
              // User marker
              if (_userLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _userLocation!,
                      width: 24,
                      height: 24,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.accentBlue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                                color: AppColors.accentBlue.withOpacity(0.4),
                                blurRadius: 8)
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              // Result markers
              MarkerLayer(
                markers: _results.map((user) {
                  final loc = user.location!;
                  final isSelected = _selectedUser?.id == user.id;
                  return Marker(
                    point: LatLng(loc.latitude, loc.longitude),
                    width: 56,
                    height: 64,
                    child: GestureDetector(
                      onTap: () => _openProfile(user),
                      child: Column(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: isSelected ? 56 : 48,
                            height: isSelected ? 56 : 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.accentBlue
                                    : Colors.white,
                                width: isSelected ? 3 : 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2))
                              ],
                            ),
                            child: ClipOval(
                              child: user.photoUrl != null
                                  ? CachedNetworkImage(
                                      imageUrl: user.photoUrl!,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) =>
                                          const ColoredBox(color: AppColors.accentBlue),
                                    )
                                  : Container(
                                      color: AppColors.accentBlue.withOpacity(0.2),
                                      child: Center(
                                        child: Text(
                                          user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                                          style: const TextStyle(
                                            color: AppColors.accentBlue,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          // Pin tail
                          Container(
                            width: 2,
                            height: 8,
                            color: isSelected ? AppColors.accentBlue : Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // ── Top Bar ───────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.m),
              child: Row(
                children: [
                  _MapButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => context.pop(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8)
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isProvider ? Icons.handyman_rounded : Icons.storefront_rounded,
                            color: AppColors.accentBlue,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.category == 'Any' || widget.category.isEmpty
                                ? 'All ${isProvider ? 'Providers' : 'Marketplaces'}'
                                : widget.category,
                            style: AppTextStyles.bodyMedium
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
                          const Spacer(),
                          if (_isLoading)
                            const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.accentBlue))
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.accentBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text('${_results.length} found',
                                  style: AppTextStyles.caption.copyWith(
                                      color: AppColors.accentBlue,
                                      fontWeight: FontWeight.w700)),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _MapButton(
                    icon: Icons.my_location_rounded,
                    onTap: () {
                      if (_userLocation != null) {
                        _mapController.move(_userLocation!, 14);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          // ── Loading ───────────────────────────────────────────────
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: AppColors.accentBlue)),

          // ── Selected Profile Sheet ────────────────────────────────
          if (_selectedUser != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _ProfileMiniCard(
                user: _selectedUser!,
                isProvider: isProvider,
                onTap: () {
                  if (isProvider) {
                    context.push('/provider-profile/${_selectedUser!.id}');
                  } else {
                    context.push('/merchant-profile/${_selectedUser!.id}');
                  }
                },
                onClose: () => setState(() => _selectedUser = null),
              ),
            ),
        ],
      ),
    );
  }
}

class _MapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _MapButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)
          ],
        ),
        child: Icon(icon, color: AppColors.textDark, size: 20),
      ),
    );
  }
}

class _ProfileMiniCard extends StatelessWidget {
  final UserModel user;
  final bool isProvider;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _ProfileMiniCard({
    required this.user,
    required this.isProvider,
    required this.onTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final data = user.toJson();
    final subtitle = isProvider
        ? (data['profession'] as String? ?? '')
        : (data['category'] as String? ?? '');
    final isAvailable = data['isAvailableNow'] as bool? ?? false;

    return Container(
      margin: const EdgeInsets.all(AppSpacing.m),
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, -4))
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.accentBlue.withOpacity(0.3)),
            ),
            child: ClipOval(
              child: user.photoUrl != null
                  ? CachedNetworkImage(imageUrl: user.photoUrl!, fit: BoxFit.cover)
                  : Container(
                      color: AppColors.accentBlue.withOpacity(0.1),
                      child: Center(
                        child: Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                          style: const TextStyle(
                              color: AppColors.accentBlue,
                              fontWeight: FontWeight.w700,
                              fontSize: 22),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        isProvider ? user.name : (data['businessName'] as String? ?? user.name),
                        style: AppTextStyles.headingSmall.copyWith(fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isProvider && isAvailable)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                            color: AppColors.availableGreen, shape: BoxShape.circle),
                      ),
                  ],
                ),
                if (subtitle.isNotEmpty)
                  Text(subtitle,
                      style: AppTextStyles.caption.copyWith(color: AppColors.accentBlue)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: AppColors.starGold, size: 14),
                    const SizedBox(width: 2),
                    Text(
                      user.rating > 0
                          ? '${user.rating.toStringAsFixed(1)} (${user.reviewCount})'
                          : 'No reviews yet',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.m),
          Column(
            children: [
              GestureDetector(
                onTap: onClose,
                child: const Icon(Icons.close, color: AppColors.softGray, size: 20),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: onTap,
                child: const Text('View', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
