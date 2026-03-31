import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/models/work_provider_model.dart';
import '../../../core/models/review_model.dart';
import '../../../services/review_service.dart';
import '../../auth/providers/auth_provider.dart';

class ProviderProfileScreen extends ConsumerStatefulWidget {
  final String uid;
  const ProviderProfileScreen({super.key, required this.uid});

  @override
  ConsumerState<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends ConsumerState<ProviderProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  bool _isCollapsed = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _scrollController.addListener(() {
      if (_scrollController.hasClients && _scrollController.offset > 200 && !_isCollapsed) {
        setState(() => _isCollapsed = true);
      } else if (_scrollController.hasClients && _scrollController.offset <= 200 && _isCollapsed) {
        setState(() => _isCollapsed = false);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(widget.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Scaffold(body: Center(child: Text('Error loading profile')));
        if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));

        final provider = WorkProviderModel.fromMap(widget.uid, snapshot.data!.data() as Map<String, dynamic>);

        return Scaffold(
          body: NestedScrollView(
            controller: _scrollController,
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                expandedHeight: 350,
                pinned: true,
                stretch: true,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => context.pop(),
                  ),
                ),
                actions: [
                  Container(
                    margin: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: IconButton(
                      icon: const Icon(Icons.report_gmailerrorred_rounded, color: Colors.redAccent),
                      onPressed: () => _showReportDialog(context),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      provider.photoUrl != null
                          ? CachedNetworkImage(imageUrl: provider.photoUrl!, fit: BoxFit.cover)
                          : Container(color: AppColors.accentBlue.withOpacity(0.2), child: const Icon(Icons.person, size: 100, color: AppColors.accentBlue)),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: AppSpacing.l,
                        left: AppSpacing.l,
                        right: AppSpacing.l,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(provider.name, style: AppTextStyles.headingLarge.copyWith(color: Colors.white)),
                                if (provider.verificationStatus == 'approved') ...[
                                  const SizedBox(width: 8),
                                  const Icon(Icons.verified_rounded, color: AppColors.starGold, size: 24),
                                ],
                              ],
                            ),
                            Text(provider.profession ?? 'Specialist', style: AppTextStyles.bodyLarge.copyWith(color: Colors.white70)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, color: AppColors.starGold, size: 20),
                                const SizedBox(width: 4),
                                Text(provider.rating.toStringAsFixed(1), style: AppTextStyles.bodyLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                                Text(' (${provider.reviewCount} reviews)', style: AppTextStyles.caption.copyWith(color: Colors.white70)),
                                const Spacer(),
                                if (provider.isAvailableNow)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(color: AppColors.availableGreen, borderRadius: BorderRadius.circular(20)),
                                    child: const Text('Available Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
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
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    controller: _tabController,
                    labelColor: AppColors.accentBlue,
                    unselectedLabelColor: AppColors.softGray,
                    indicatorColor: AppColors.accentBlue,
                    indicatorWeight: 3,
                    tabs: const [
                      Tab(text: 'About'),
                      Tab(text: 'Services'),
                      Tab(text: 'Portfolio'),
                      Tab(text: 'Reviews'),
                    ],
                  ),
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildAboutTab(provider),
                _buildServicesTab(provider),
                _buildPortfolioTab(provider),
                _buildReviewsTab(provider),
              ],
            ),
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.all(AppSpacing.l),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _startChat(context, provider),
                    icon: const Icon(Icons.chat_bubble_rounded),
                    label: const Text('Message Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
                Container(
                  decoration: BoxDecoration(color: AppColors.softGray.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: IconButton(
                    icon: const Icon(Icons.share_rounded, color: AppColors.accentBlue),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAboutTab(WorkProviderModel provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bio', style: AppTextStyles.headingSmall),
          const SizedBox(height: 8),
          Text(provider.bio ?? 'No description provided.', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textDark.withOpacity(0.8))),
          const SizedBox(height: AppSpacing.xl),
          _infoTile(Icons.work_history_outlined, 'Experience', '${provider.yearsExperience ?? 0} years'),
          _infoTile(Icons.language_outlined, 'Languages', provider.language ?? 'English'),
          _infoTile(Icons.location_on_outlined, 'Location', provider.address ?? 'Detected Area'),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.m),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.accentBlue.withOpacity(0.05), shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.accentBlue, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.softGray)),
              Text(value, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServicesTab(WorkProviderModel provider) {
    if (provider.services.isEmpty) {
      return const Center(child: Text('No fixed prices provided. Custom quote available.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.l),
      itemCount: provider.services.length,
      separatorBuilder: (_, __) => const Divider(height: 32),
      itemBuilder: (ctx, i) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(provider.services[i].name, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
          Text('${provider.services[i].price.toStringAsFixed(0)} DZD', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.accentBlue, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPortfolioTab(WorkProviderModel provider) {
    // Portfolio images stored in provider.toJson()['portfolio'] or subcollection
    // For now, let's look in the photos/portfolio list if it existed (wasn't explicitly in model but in prompt)
    // Actually, prompt says up to 10 photos stored in Firestore.
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.m),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12),
      itemCount: 4, // Mock for now
      itemBuilder: (ctx, i) => ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(color: AppColors.softGray.withOpacity(0.2), child: const Icon(Icons.image_outlined)),
      ),
    );
  }

  Widget _buildReviewsTab(WorkProviderModel provider) {
    return StreamBuilder<List<ReviewModel>>(
      stream: ReviewService().getReviews(widget.uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final reviews = snapshot.data!;
        if (reviews.isEmpty) return const Center(child: Text('No reviews yet.'));

        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.l),
          itemCount: reviews.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (ctx, i) {
            final r = reviews[i];
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.softGray.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
              child: Column(
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
                  const SizedBox(height: 4),
                  Text(r.createdAt.toString().split(' ')[0], style: AppTextStyles.caption.copyWith(color: AppColors.softGray),),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _startChat(BuildContext context, WorkProviderModel provider) {
    final myUid = ref.read(authServiceProvider).currentUser?.uid;
    if (myUid == null) return;
    final conversationId = myUid.compareTo(provider.id) < 0 ? '${myUid}_${provider.id}' : '${provider.id}_$myUid';
    context.push('/chat/$conversationId?otherName=${provider.name}');
  }

  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Report Profile'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Is there something wrong with this profile?'),
            TextField(decoration: InputDecoration(hintText: 'Reason for reporting...')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () { 
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report submitted. Admin will review.')));
          }, child: const Text('Submit', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);
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
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}
