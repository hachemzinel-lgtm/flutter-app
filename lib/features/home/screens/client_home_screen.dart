import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/provider_feature_card.dart';

const _professions = [
  'Any', 'Plumber', 'Electrician', 'Cleaner', 'Carpenter',
  'Painter', 'Gardener', 'Mechanic', 'Tutor', 'Photographer', 'Other',
];

const _marketplaceCats = [
  'Any', 'Restaurant', 'Bakery', 'Grocery Store', 'Pharmacy',
  'Hardware Store', 'Café', 'Butcher Shop', 'Clothing Store', 'Electronics Store', 'Other',
];

class ClientHomeScreen extends ConsumerStatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  ConsumerState<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends ConsumerState<ClientHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedProviderCategory = 'Any';
  String _selectedMarketCategory = 'Any';
  double _radiusKm = 10;
  double _minRating = 0;
  bool _availableOnly = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _search() {
    final isProvider = _tabController.index == 0;
    final category = isProvider ? _selectedProviderCategory : _selectedMarketCategory;
    context.push(
      '/map-results?type=${isProvider ? 'provider' : 'marketplace'}'
      '&category=${Uri.encodeComponent(category)}'
      '&radius=$_radiusKm'
      '&minRating=$_minRating'
      '&availableOnly=$_availableOnly',
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserDocProvider).value;
    final firstName = user?.name.split(' ').first ?? 'there';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.l, AppSpacing.l, AppSpacing.l, AppSpacing.xl),
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Hello, $firstName 👋',
                                style: AppTextStyles.headingLarge.copyWith(
                                    color: Colors.white, fontSize: 24)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on,
                                    color: AppColors.accentBlue, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  user?.address ?? 'Tap to set location',
                                  style: AppTextStyles.caption
                                      .copyWith(color: Colors.white70),
                                ),
                              ],
                            ),
                          ],
                        ),
                        // Avatar
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.accentBlue.withOpacity(0.2),
                          backgroundImage: user?.photoUrl != null
                              ? NetworkImage(user!.photoUrl!)
                              : null,
                          child: user?.photoUrl == null
                              ? Text(firstName[0].toUpperCase(),
                                  style: const TextStyle(
                                      color: AppColors.accentBlue,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 18))
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    // Tab switcher
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          color: AppColors.accentBlue,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white60,
                        labelStyle: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14),
                        tabs: const [
                          Tab(text: '🔧  Work Providers'),
                          Tab(text: '🏪  Marketplaces'),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.l),
                    // Category picker
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _tabController.index == 0
                          ? _CategoryPicker(
                              key: const ValueKey('provider'),
                              categories: _professions,
                              selected: _selectedProviderCategory,
                              onSelected: (v) =>
                                  setState(() => _selectedProviderCategory = v),
                            )
                          : _CategoryPicker(
                              key: const ValueKey('market'),
                              categories: _marketplaceCats,
                              selected: _selectedMarketCategory,
                              onSelected: (v) =>
                                  setState(() => _selectedMarketCategory = v),
                            ),
                    ),
                  ],
                ),
              ),

              // ── Filters ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(AppSpacing.l),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Search Radius',
                            style: AppTextStyles.bodyMedium
                                .copyWith(fontWeight: FontWeight.w600)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
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
                    Row(children: [
                      ...[5, 10, 20, 50].map((km) => Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: GestureDetector(
                              onTap: () => setState(() => _radiusKm = km.toDouble()),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _radiusKm == km
                                      ? AppColors.accentBlue
                                      : AppColors.softGray.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text('${km}km',
                                    style: AppTextStyles.caption.copyWith(
                                        color: _radiusKm == km
                                            ? Colors.white
                                            : AppColors.textLight,
                                        fontWeight: FontWeight.w600)),
                              ),
                            ),
                          )),
                    ]),
                    const SizedBox(height: AppSpacing.m),
                    if (_tabController.index == 0) ...[
                      Row(
                        children: [
                          Expanded(
                            child: _FilterChipTile(
                              label: 'Available Now',
                              isSelected: _availableOnly,
                              onTap: () =>
                                  setState(() => _availableOnly = !_availableOnly),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.m),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Min Rating',
                                    style: AppTextStyles.caption
                                        .copyWith(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                DropdownButton<double>(
                                  isExpanded: true,
                                  value: _minRating,
                                  underline: const SizedBox(),
                                  items: const [
                                    DropdownMenuItem(
                                        value: 0, child: Text('Any')),
                                    DropdownMenuItem(
                                        value: 3, child: Text('3+ ⭐')),
                                    DropdownMenuItem(
                                        value: 4, child: Text('4+ ⭐')),
                                    DropdownMenuItem(
                                        value: 4.5, child: Text('4.5+ ⭐')),
                                  ],
                                  onChanged: (v) =>
                                      setState(() => _minRating = v!),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppSpacing.l),
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
                        icon: const Icon(Icons.search_rounded),
                        label: Text(
                          _tabController.index == 0
                              ? 'Find Work Providers'
                              : 'Find Marketplaces',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Top Rated Near You ─────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.l, 0, AppSpacing.l, AppSpacing.m),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Top Rated Near You',
                        style: AppTextStyles.headingSmall),
                    TextButton(
                      onPressed: () => context.go('/best-providers'),
                      child: Text('See All',
                          style: AppTextStyles.caption.copyWith(
                              color: AppColors.accentBlue,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                  itemCount: 4,
                  itemBuilder: (_, i) => ProviderFeatureCard(
                    name: i == 0 ? 'Mohamed A.' : i == 1 ? 'Lamine P.' : i == 2 ? 'Sarah K.' : 'Ahmed T.',
                    profession: i == 0 ? 'Électricien' : i == 1 ? 'Plombier' : i == 2 ? 'Nettoyeuse' : 'Menuisier',
                    rating: 4.8,
                    distance: '${2 + i}km',
                    isVerified: i % 2 == 0,
                    isAvailable: i < 2,
                    onTap: () => context.push('/profile/provider-$i'),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Reusable components ──────────────────────────────────────────────────────

class _CategoryPicker extends StatelessWidget {
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;

  const _CategoryPicker({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final cat = categories[i];
          final isSelected = cat == selected;
          return GestureDetector(
            onTap: () => onSelected(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.accentBlue
                    : Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppColors.accentBlue
                      : Colors.white.withOpacity(0.2),
                ),
              ),
              child: Text(cat,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                    fontSize: 13,
                  )),
            ),
          );
        },
      ),
    );
  }
}

class _FilterChipTile extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChipTile({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.availableGreen.withOpacity(0.1)
              : AppColors.softGray.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppColors.availableGreen
                : AppColors.softGray.withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
              size: 16,
              color: isSelected ? AppColors.availableGreen : AppColors.softGray,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(label,
                  style: AppTextStyles.caption.copyWith(
                    color: isSelected ? AppColors.availableGreen : AppColors.textLight,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                  )),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProviderCardSkeleton extends StatelessWidget {
  const _ProviderCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.softGray.withOpacity(0.15),
            ),
          ),
          const SizedBox(height: 8),
          Container(height: 12, width: 100, color: AppColors.softGray.withOpacity(0.15)),
          const SizedBox(height: 6),
          Container(height: 10, width: 70, color: AppColors.softGray.withOpacity(0.1)),
          const SizedBox(height: 8),
          Container(height: 10, width: 80, color: AppColors.softGray.withOpacity(0.1)),
        ],
      ),
    );
  }
}
