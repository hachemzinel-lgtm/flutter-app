import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/providers/availability_provider.dart';

const _marketplaceCats = [
  'Any', 'Restaurant', 'Bakery', 'Grocery Store', 'Pharmacy',
  'Hardware Store', 'Café', 'Butcher Shop', 'Clothing Store', 'Electronics Store', 'Other',
];

class ProviderHomeScreen extends ConsumerStatefulWidget {
  const ProviderHomeScreen({super.key});

  @override
  ConsumerState<ProviderHomeScreen> createState() => _ProviderHomeScreenState();
}

class _ProviderHomeScreenState extends ConsumerState<ProviderHomeScreen> {
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
    final firstName = user?.name.split(' ').first ?? 'there';
    final providerData = user?.toJson();
    final isAvailable = providerData?['isAvailableNow'] as bool? ?? false;
    final profession = providerData?['profession'] as String? ?? '';
    final rating = user?.rating ?? 0.0;

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
                    colors: [Color(0xFF1A1F3A), Color(0xFF0D1B2A)],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: AppColors.accentBlue.withOpacity(0.2),
                          backgroundImage: user?.photoUrl != null
                              ? NetworkImage(user!.photoUrl!)
                              : null,
                          child: user?.photoUrl == null
                              ? Text(firstName[0].toUpperCase(),
                                  style: const TextStyle(
                                      color: AppColors.accentBlue,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 20))
                              : null,
                        ),
                        const SizedBox(width: AppSpacing.m),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Welcome back,',
                                  style: AppTextStyles.caption
                                      .copyWith(color: Colors.white60)),
                              Text(firstName,
                                  style: AppTextStyles.headingSmall
                                      .copyWith(color: Colors.white)),
                              if (profession.isNotEmpty)
                                Text(profession,
                                    style: AppTextStyles.caption.copyWith(
                                        color: AppColors.accentBlue)),
                            ],
                          ),
                        ),
                        // Verified badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.starGold.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppColors.starGold.withOpacity(0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.verified_rounded,
                                  color: AppColors.starGold, size: 14),
                              const SizedBox(width: 4),
                              Text('Verified',
                                  style: AppTextStyles.caption.copyWith(
                                      color: AppColors.starGold,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.l),
                    // Availability toggle
                    Consumer(builder: (ctx, r, _) {
                      return Container(
                        padding: const EdgeInsets.all(AppSpacing.m),
                        decoration: BoxDecoration(
                          color: (isAvailable
                                  ? AppColors.availableGreen
                                  : AppColors.softGray)
                              .withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: (isAvailable
                                    ? AppColors.availableGreen
                                    : AppColors.softGray)
                                .withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isAvailable
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                              color: isAvailable
                                  ? AppColors.availableGreen
                                  : AppColors.softGray,
                              size: 20,
                            ),
                            const SizedBox(width: AppSpacing.m),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isAvailable
                                        ? 'Available Now'
                                        : 'Currently Offline',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    isAvailable
                                        ? 'Clients can find and contact you'
                                        : 'You\'re hidden from search results',
                                    style: AppTextStyles.caption
                                        .copyWith(color: Colors.white60),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: isAvailable,
                              onChanged: (v) => ref
                                  .read(availabilityProvider.notifier)
                                  .toggle(v),
                              activeColor: AppColors.availableGreen,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: AppSpacing.m),
                    // Stats row
                    Row(
                      children: [
                        _StatChip(
                            label: 'Rating',
                            value: rating > 0
                                ? '${rating.toStringAsFixed(1)} ⭐'
                                : 'No ratings'),
                        const SizedBox(width: AppSpacing.m),
                        _StatChip(
                            label: 'Reviews', value: '${user?.reviewCount ?? 0}'),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Marketplace Search ────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(AppSpacing.l),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Find Marketplaces Near You',
                        style: AppTextStyles.headingSmall),
                    const SizedBox(height: AppSpacing.m),
                    Text('Category', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
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
                    const SizedBox(height: AppSpacing.m),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Distance: ${_radiusKm.toInt()} km',
                            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accentBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('${_radiusKm.toInt()} km',
                              style: AppTextStyles.caption.copyWith(
                                  color: AppColors.accentBlue,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    Slider(
                      value: _radiusKm,
                      min: 5,
                      max: 50,
                      divisions: 9,
                      activeColor: AppColors.accentBlue,
                      inactiveColor: AppColors.softGray.withOpacity(0.2),
                      onChanged: (v) => setState(() => _radiusKm = v),
                    ),
                    const SizedBox(height: AppSpacing.m),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentBlue,
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
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14)),
          Text(label,
              style: const TextStyle(color: Colors.white60, fontSize: 11)),
        ],
      ),
    );
  }
}
