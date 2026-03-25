import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/primary_button.dart';
import '../providers/profile_provider.dart';

class ProviderProfileScreen extends ConsumerWidget {
  final String uid;
  const ProviderProfileScreen({super.key, required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providerAsync = ref.watch(providerDataProvider(uid));

    return Scaffold(
      backgroundColor: AppColors.primaryBackground, // Use a light gray background for modern look
      body: providerAsync.when(
        data: (doc) {
          if (!doc.exists) return const Center(child: Text('Profile not found'));
          final data = doc.data() as Map<String, dynamic>;
          
          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  _buildSliverAppBar(context, data),
                  
                  // Header content pulled up over the app bar
                  SliverToBoxAdapter(
                    child: Transform.translate(
                      offset: const Offset(0, -40),
                      child: Column(
                        children: [
                          _buildHeaderCard(data),
                          const SizedBox(height: 12),
                          _buildQuickStatsStrip(data),
                          const SizedBox(height: AppSpacing.m),
                          _buildProfessionalInfo(data),
                          const SizedBox(height: AppSpacing.m),
                          _buildServiceArea(data),
                          const SizedBox(height: AppSpacing.m),
                          _buildWorkHours(data),
                          const SizedBox(height: AppSpacing.m),
                          _buildPricing(data),
                          const SizedBox(height: AppSpacing.m),
                          _buildPortfolio(data['portfolioImages'] as List? ?? []),
                          const SizedBox(height: 120), // Padding for sticky bottom nav
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              // Sticky Action Bar
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: _buildStickyActionBar(context, uid),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, Map<String, dynamic> data) {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: AppColors.accentBlue,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          backgroundColor: Colors.black.withOpacity(0.3),
          child: const BackButton(color: Colors.white),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.black.withOpacity(0.3),
            child: IconButton(icon: const Icon(Icons.share_outlined, color: Colors.white, size: 20), onPressed: () {}),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: AppColors.accentBlue),
            // Optional: Background cover image could go here
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(Map<String, dynamic> data) {
    final String name = data['displayName'] ?? data['name'] ?? 'Provider Name';
    final String profession = data['profession'] ?? data['title'] ?? 'Professional';
    final double rating = (data['rating'] as num?)?.toDouble() ?? 5.0;
    final int reviews = data['reviewCount'] ?? 0;
    final bool isVerified = data['isVerified'] ?? true;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          // Large Circular Photo
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.accentBlue.withOpacity(0.1),
              backgroundImage: data['photoUrl'] != null ? NetworkImage(data['photoUrl']) : null,
              child: data['photoUrl'] == null 
                  ? Text(name[0].toUpperCase(), style: AppTextStyles.headingLarge.copyWith(color: AppColors.accentBlue, fontSize: 36))
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          
          // Name and Verification
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(name, style: AppTextStyles.headingLarge.copyWith(fontSize: 22)),
              if (isVerified) ...[
                const SizedBox(width: 8),
                const Icon(Icons.verified, color: AppColors.availableGreen, size: 20),
              ],
            ],
          ),
          const SizedBox(height: 4),
          
          // Profession
          Text(profession, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.accentBlue, fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 12),
          
          // Rating
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, color: AppColors.starGold, size: 18),
              const SizedBox(width: 4),
              Text(rating.toStringAsFixed(1), style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(width: 6),
              Text('($reviews reviews)', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.softGray)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsStrip(Map<String, dynamic> data) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
      child: Row(
        children: [
          _quickStatCard(Icons.location_on, '5 km', 'Distance', Colors.blue),
          _quickStatCard(Icons.attach_money, '${data['hourlyRate'] ?? '--'}/hr', 'Rate', Colors.green),
          _quickStatCard(Icons.workspace_premium, '${data['yearsExp'] ?? '5+'} yrs', 'Experience', Colors.orange),
          _quickStatCard(
            (data['isAvailable'] ?? true) ? Icons.check_circle : Icons.do_not_disturb_on, 
            (data['isAvailable'] ?? true) ? 'Available' : 'Busy', 
            'Status', 
            (data['isAvailable'] ?? true) ? AppColors.availableGreen : AppColors.softGray,
          ),
        ],
      ),
    );
  }

  Widget _quickStatCard(IconData icon, String value, String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 13)),
              const SizedBox(height: 2),
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.softGray, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalInfo(Map<String, dynamic> data) {
    final List skills = data['skills'] ?? ['General Service'];
    final List languages = data['languages'] ?? ['English'];

    return _sectionCard(
      title: 'Professional Info',
      icon: Icons.work_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (data['businessName'] != null && data['businessName'] != '') ...[
            _infoRow(Icons.business, 'Business', data['businessName']),
            const SizedBox(height: 12),
          ] else ...[
            _infoRow(Icons.person_outline, 'Business', 'Independent / Self-employed'),
            const SizedBox(height: 12),
          ],
          
          if (data['certifications'] != null && data['certifications'] != '') ...[
            _infoRow(Icons.verified_outlined, 'Certifications', data['certifications']),
            const SizedBox(height: 16),
          ],
          
          Text('Specializations', style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: skills.map((s) => _tag(s.toString(), AppColors.accentBlue.withOpacity(0.1), AppColors.accentBlue)).toList(),
          ),
          const SizedBox(height: 16),

          Text('Languages', style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: languages.map((l) => _tag(l.toString(), AppColors.backgroundSecondary, AppColors.textDark)).toList(),
          ),
          
          if (data['bio'] != null && data['bio'] != '') ...[
            const SizedBox(height: 16),
            const Divider(color: AppColors.borderLight),
            const SizedBox(height: 12),
            Text('About', style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(data['bio'], style: AppTextStyles.bodyMedium.copyWith(height: 1.5, fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }

  Widget _buildServiceArea(Map<String, dynamic> data) {
    return _sectionCard(
      title: 'Location & Service Area',
      icon: Icons.location_on_outlined,
      child: Column(
        children: [
          _infoRow(Icons.location_city_outlined, 'Base City', data['city'] ?? 'Not specified'),
          const SizedBox(height: 12),
          _infoRow(Icons.radar_outlined, 'Service Radius', '${data['serviceRadius'] ?? 25} km'),
        ],
      ),
    );
  }

  Widget _buildWorkHours(Map<String, dynamic> data) {
    return _sectionCard(
      title: 'Hours & Availability',
      icon: Icons.schedule,
      child: Theme(
        data: ThemeData(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: Text('Mon-Fri: 8am - 6pm • Sat: 9am - 2pm', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
          children: [
            _hourRow('Monday', '8:00 AM - 6:00 PM', true),
            _hourRow('Tuesday', '8:00 AM - 6:00 PM', true),
            _hourRow('Wednesday', '8:00 AM - 6:00 PM', true),
            _hourRow('Thursday', '8:00 AM - 6:00 PM', true),
            _hourRow('Friday', '8:00 AM - 6:00 PM', true),
            _hourRow('Saturday', '9:00 AM - 2:00 PM', true),
            _hourRow('Sunday', 'Closed', false),
            
            if (data['emergencyAvailable'] == true) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.errorRed.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppColors.errorRed, size: 18),
                    const SizedBox(width: 8),
                    Text('Available for 24/7 emergencies', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.errorRed, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _hourRow(String day, String hours, bool isOpen) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(day, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.softGray)),
          Row(
            children: [
              Text(hours, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: isOpen ? AppColors.textDark : AppColors.errorRed)),
              const SizedBox(width: 8),
              Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: isOpen ? AppColors.availableGreen : AppColors.errorRed)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPricing(Map<String, dynamic> data) {
    return _sectionCard(
      title: 'Pricing Details',
      icon: Icons.payments_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('${data['hourlyRate'] ?? 0} DT', style: AppTextStyles.headingLarge.copyWith(color: AppColors.accentBlue)),
              Text(' / hour', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.softGray)),
            ],
          ),
          if (data['minPrice'] != null) ...[
            const SizedBox(height: 8),
            _infoRow(Icons.flag_outlined, 'Minimum Job Price', '${data['minPrice']} DT'),
          ],
          if (data['pricingNotes'] != null && data['pricingNotes'] != '') ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.backgroundSecondary, borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: AppColors.softGray),
                  const SizedBox(width: 8),
                  Expanded(child: Text(data['pricingNotes'], style: AppTextStyles.caption.copyWith(color: AppColors.textDark))),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPortfolio(List images) {
    if (images.isEmpty) return const SizedBox.shrink();
    return _sectionCard(
      title: 'Portfolio',
      icon: Icons.photo_library_outlined,
      child: Column(
        children: [
          GridView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8,
            ),
            itemCount: images.length.clamp(0, 3),
            itemBuilder: (context, index) => ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(imageUrl: images[index], fit: BoxFit.cover),
            ),
          ),
          if (images.length > 3) ...[
            const SizedBox(height: 12),
            TextButton(onPressed: () {}, child: const Text('View All Photos')),
          ]
        ],
      ),
    );
  }

  Widget _buildStickyActionBar(BuildContext context, String uid) {
    return Container(
      padding: EdgeInsets.fromLTRB(AppSpacing.m, AppSpacing.m, AppSpacing.m, MediaQuery.of(context).padding.bottom + AppSpacing.m),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Row(
        children: [
          // Save Button
          Container(
            height: 50, width: 50,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.borderLight),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.favorite_border, color: AppColors.accentBlue),
          ),
          const SizedBox(width: 12),
          
          // Call Button
          Container(
            height: 50, width: 50,
            decoration: BoxDecoration(color: AppColors.availableGreen.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.call, color: AppColors.availableGreen),
          ),
          const SizedBox(width: 12),
          
          // Message / Book Button
          Expanded(
            child: PrimaryButton(
              text: 'Message',
              icon: Icons.chat_bubble_outline,
              onPressed: () => context.push('/chat/$uid'),
            ),
          ),
        ],
      ),
    );
  }

  // Helpers
  Widget _sectionCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.accentBlue, size: 20),
              const SizedBox(width: 8),
              Text(title, style: AppTextStyles.headingSmall.copyWith(fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.softGray),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.softGray)),
            const SizedBox(height: 2),
            Text(value, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500, color: AppColors.textDark)),
          ],
        ),
      ],
    );
  }

  Widget _tag(String text, Color bg, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(color: textCol, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
