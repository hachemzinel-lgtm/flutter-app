import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../auth/providers/auth_provider.dart';

const _marketplaceCats = [
  'Any', 'Restaurant', 'Bakery', 'Grocery Store', 'Pharmacy',
  'Hardware Store', 'Café', 'Butcher Shop', 'Clothing Store', 'Electronics Store', 'Other',
];

class MarketplaceHomeScreen extends ConsumerStatefulWidget {
  const MarketplaceHomeScreen({super.key});

  @override
  ConsumerState<MarketplaceHomeScreen> createState() => _MarketplaceHomeScreenState();
}

class _MarketplaceHomeScreenState extends ConsumerState<MarketplaceHomeScreen> {
  String _selectedCategory = 'Any';
  double _radiusKm = 10;

  void _search() {
    context.push(
      '/map-results?type=marketplace'
      '&category=${Uri.encodeComponent(_selectedCategory)}'
      '&radius=$_radiusKm',
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserDocProvider).value;
    final data = user?.toJson();
    final businessName = data?['businessName'] as String? ?? user?.name ?? 'Business';
    final category = data?['category'] as String? ?? '';
    final rating = user?.rating ?? 0.0;
    final reviewCount = user?.reviewCount ?? 0;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(AppSpacing.l),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF064E3B), Color(0xFF065F46)],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Store avatar
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: Colors.white.withOpacity(0.15),
                            image: user?.photoUrl != null
                                ? DecorationImage(
                                    image: NetworkImage(user!.photoUrl!),
                                    fit: BoxFit.cover)
                                : null,
                          ),
                          child: user?.photoUrl == null
                              ? const Icon(Icons.storefront_rounded,
                                  color: Colors.white, size: 28)
                              : null,
                        ),
                        const SizedBox(width: AppSpacing.m),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(businessName,
                                  style: AppTextStyles.headingSmall
                                      .copyWith(color: Colors.white)),
                              if (category.isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(category,
                                      style: AppTextStyles.caption
                                          .copyWith(color: Colors.white)),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.l),
                    // Stats
                    Row(
                      children: [
                        _MetricCard(
                            icon: Icons.star_rounded,
                            color: AppColors.starGold,
                            label: 'Rating',
                            value: rating > 0 ? rating.toStringAsFixed(1) : '--'),
                        const SizedBox(width: AppSpacing.m),
                        _MetricCard(
                            icon: Icons.reviews_outlined,
                            color: AppColors.accentBlue,
                            label: 'Reviews',
                            value: '$reviewCount'),
                        const SizedBox(width: AppSpacing.m),
                        _MetricCard(
                            icon: Icons.location_on_outlined,
                            color: const Color(0xFF10B981),
                            label: 'Area',
                            value: user?.address != null ? 'Set' : 'Needed'),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Search Section ────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(AppSpacing.l),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Discover Other Businesses',
                        style: AppTextStyles.headingSmall),
                    const SizedBox(height: 6),
                    Text('Find marketplaces and network with local businesses',
                        style: AppTextStyles.bodyMedium),
                    const SizedBox(height: AppSpacing.l),
                    _buildLabel('CATEGORY'),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.softGray.withOpacity(0.2)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedCategory,
                          items: _marketplaceCats
                              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                              .toList(),
                          onChanged: (v) => setState(() => _selectedCategory = v!),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.l),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildLabel('RADIUS'),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('${_radiusKm.toInt()} km',
                              style: AppTextStyles.caption.copyWith(
                                  color: const Color(0xFF10B981),
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    Slider(
                      value: _radiusKm,
                      min: 5,
                      max: 50,
                      divisions: 9,
                      activeColor: const Color(0xFF10B981),
                      inactiveColor: AppColors.softGray.withOpacity(0.2),
                      onChanged: (v) => setState(() => _radiusKm = v),
                    ),
                    const SizedBox(height: AppSpacing.m),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _search,
                        icon: const Icon(Icons.map_outlined),
                        label: const Text('Show on Map',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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

  Widget _buildLabel(String label) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label,
          style: AppTextStyles.caption
              .copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.8)));
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  const _MetricCard({required this.icon, required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16)),
            Text(label,
                style: const TextStyle(color: Colors.white60, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
