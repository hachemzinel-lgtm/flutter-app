import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/models/marketplace_model.dart';
import '../../../core/models/review_model.dart';
import '../../../services/review_service.dart';
import '../../auth/providers/auth_provider.dart';

class MerchantProfileScreen extends ConsumerStatefulWidget {
  final String uid;
  const MerchantProfileScreen({super.key, required this.uid});

  @override
  ConsumerState<MerchantProfileScreen> createState() => _MerchantProfileScreenState();
}

class _MerchantProfileScreenState extends ConsumerState<MerchantProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(widget.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Scaffold(body: Center(child: Text('Error loading business profile')));
        if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));

        final merchant = MarketplaceModel.fromMap(widget.uid, snapshot.data!.data() as Map<String, dynamic>);

        return Scaffold(
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => context.pop(),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      merchant.photoUrl != null
                          ? CachedNetworkImage(imageUrl: merchant.photoUrl!, fit: BoxFit.cover)
                          : Container(color: Colors.green.withOpacity(0.1), child: const Icon(Icons.storefront, size: 80, color: Colors.green)),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(merchant.businessName ?? 'Local Business', style: AppTextStyles.headingLarge.copyWith(color: Colors.white)),
                            const SizedBox(height: 4),
                            Text(merchant.category ?? 'Marketplace', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, color: AppColors.starGold, size: 18),
                                const SizedBox(width: 4),
                                Text(merchant.rating.toStringAsFixed(1), style: AppTextStyles.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                                  child: const Text('Open Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _TabDelegate(
                  TabBar(
                    controller: _tabController,
                    labelColor: Colors.green,
                    indicatorColor: Colors.green,
                    unselectedLabelColor: AppColors.softGray,
                    tabs: const [
                      Tab(text: 'About'),
                      Tab(text: 'Photos'),
                      Tab(text: 'Reviews'),
                    ],
                  ),
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildAboutTab(merchant),
                _buildPhotosTab(merchant),
                _buildReviewsTab(merchant),
              ],
            ),
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.all(AppSpacing.l),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
            ),
            child: ElevatedButton.icon(
              onPressed: () => _startChat(context, merchant),
              icon: const Icon(Icons.chat_bubble_rounded),
              label: const Text('Message Store'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAboutTab(MarketplaceModel merchant) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Business Description', style: AppTextStyles.headingSmall),
          const SizedBox(height: 8),
          Text(merchant.description ?? 'No description provided.', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textDark.withOpacity(0.8))),
          const SizedBox(height: AppSpacing.xl),
          _infoLine(Icons.location_on_outlined, 'Address', merchant.address ?? 'Detected Area'),
          _infoLine(Icons.access_time_outlined, 'Hours', 'Mon - Sat: 9 AM - 6 PM'),
          _infoLine(Icons.phone_outlined, 'Phone', merchant.phone),
        ],
      ),
    );
  }

  Widget _infoLine(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.green, size: 20),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.softGray)),
            Text(value, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
          ]),
        ],
      ),
    );
  }

  Widget _buildPhotosTab(MarketplaceModel merchant) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.m),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
      itemCount: 6, // Mock for now
      itemBuilder: (ctx, i) => ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(color: Colors.green.withOpacity(0.05), child: const Icon(Icons.image_outlined, color: Colors.green)),
      ),
    );
  }

  Widget _buildReviewsTab(MarketplaceModel merchant) {
    return StreamBuilder<List<ReviewModel>>(
      stream: ReviewService().getReviews(widget.uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final reviews = snapshot.data!;
        if (reviews.isEmpty) return const Center(child: Text('No reviews yet.'));

        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.l),
          itemCount: reviews.length,
          separatorBuilder: (_, __) => const Divider(height: 32),
          itemBuilder: (ctx, i) {
            final r = reviews[i];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(radius: 12, backgroundImage: r.reviewerPhoto.isNotEmpty ? NetworkImage(r.reviewerPhoto) : null),
                    const SizedBox(width: 8),
                    Text(r.reviewerName, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    const Icon(Icons.star_rounded, color: AppColors.starGold, size: 14),
                    Text(r.rating.toString(), style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(r.text, style: AppTextStyles.bodyMedium),
              ],
            );
          },
        );
      },
    );
  }

  void _startChat(BuildContext context, MarketplaceModel merchant) {
    final myUid = ref.read(authServiceProvider).currentUser?.uid;
    if (myUid == null) return;
    final conversationId = myUid.compareTo(merchant.id) < 0 ? '${myUid}_${merchant.id}' : '${merchant.id}_$myUid';
    context.push('/chat/$conversationId?otherName=${merchant.businessName ?? merchant.name}');
  }
}

class _TabDelegate extends SliverPersistentHeaderDelegate {
  _TabDelegate(this._tabBar);
  final TabBar _tabBar;
  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: Colors.white, child: _tabBar);
  }
  @override
  bool shouldRebuild(_TabDelegate oldDelegate) => false;
}
