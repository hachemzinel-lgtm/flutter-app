import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/admin_service.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key, this.initialSection = 0});

  final int initialSection;

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  late int _selectedIndex;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialSection;
  }

  @override
  Widget build(BuildContext context) {
    final authUser = ref.watch(authStateProvider).value;
    final isAdminAsync = ref.watch(isAdminProvider);

    return isAdminAsync.when(
      data: (isAdmin) {
        if (!isAdmin) {
          return Scaffold(
            appBar: AppBar(title: const Text('Admin')),
            body: const Center(
              child: Text('You do not have access to the admin dashboard.'),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('NearWork Admin'),
            actions: [
              if (authUser?.email != null)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.m),
                  child: Center(
                    child: Text(authUser!.email!, style: AppTextStyles.caption),
                  ),
                ),
            ],
          ),
          body: Row(
            children: [
              NavigationRail(
                selectedIndex: _selectedIndex,
                onDestinationSelected: (value) {
                  setState(() => _selectedIndex = value);
                },
                labelType: NavigationRailLabelType.all,
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    selectedIcon: Icon(Icons.dashboard_rounded),
                    label: Text('Stats'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.people_outline_rounded),
                    selectedIcon: Icon(Icons.people_rounded),
                    label: Text('Users'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.verified_user_outlined),
                    selectedIcon: Icon(Icons.verified_user_rounded),
                    label: Text('Verifications'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.report_outlined),
                    selectedIcon: Icon(Icons.report_rounded),
                    label: Text('Reports'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.reviews_outlined),
                    selectedIcon: Icon(Icons.reviews_rounded),
                    label: Text('Reviews'),
                  ),
                ],
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.l),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildToolbar(),
                      const SizedBox(height: AppSpacing.l),
                      Expanded(child: _buildSection()),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Admin')),
        body: Center(child: Text('Unable to open admin tools.\n$error')),
      ),
    );
  }

  Widget _buildToolbar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            onChanged: (value) =>
                setState(() => _searchQuery = value.trim().toLowerCase()),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded),
              hintText: _selectedIndex == 0
                  ? 'Search disabled in stats'
                  : 'Search by name, email, category, or report reason',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection() {
    switch (_selectedIndex) {
      case 0:
        return _StatsSection(service: ref.read(adminServiceProvider));
      case 1:
        return _UsersSection(
          service: ref.read(adminServiceProvider),
          searchQuery: _searchQuery,
        );
      case 2:
        return _VerificationsSection(service: ref.read(adminServiceProvider));
      case 3:
        return _ReportsSection(
          service: ref.read(adminServiceProvider),
          searchQuery: _searchQuery,
        );
      case 4:
        return _ReviewsSection(
          service: ref.read(adminServiceProvider),
          searchQuery: _searchQuery,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _StatsSection extends StatelessWidget {
  const _StatsSection({required this.service});

  final AdminService service;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: service.getPlatformStats(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final stats = snapshot.data!;
        final averageRating = ((stats['averageRatingX100'] as int? ?? 0) / 100)
            .toStringAsFixed(2);

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Platform overview', style: AppTextStyles.headingMedium),
              const SizedBox(height: AppSpacing.l),
              Wrap(
                spacing: AppSpacing.l,
                runSpacing: AppSpacing.l,
                children: [
                  _StatCard(
                    label: 'Total users',
                    value: '${stats['totalUsers']}',
                    icon: Icons.people_rounded,
                  ),
                  _StatCard(
                    label: 'Clients',
                    value: '${stats['clients']}',
                    icon: Icons.person_search_rounded,
                  ),
                  _StatCard(
                    label: 'Providers',
                    value: '${stats['providers']}',
                    icon: Icons.handyman_rounded,
                  ),
                  _StatCard(
                    label: 'Marketplaces',
                    value: '${stats['marketplaces']}',
                    icon: Icons.storefront_rounded,
                  ),
                  _StatCard(
                    label: 'Pending verifications',
                    value: '${stats['pendingVerifications']}',
                    icon: Icons.verified_user_rounded,
                  ),
                  _StatCard(
                    label: 'Open reports',
                    value: '${stats['totalReports']}',
                    icon: Icons.flag_rounded,
                  ),
                  _StatCard(
                    label: 'Messages sent',
                    value: '${stats['totalMessages']}',
                    icon: Icons.chat_rounded,
                  ),
                  _StatCard(
                    label: 'Average rating',
                    value: averageRating,
                    icon: Icons.star_rounded,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.l),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Most active profession',
                      style: AppTextStyles.headingSmall,
                    ),
                    const SizedBox(height: AppSpacing.s),
                    Text(
                      '${stats['topProfession'] ?? 'N/A'} (${stats['topProfessionCount'] ?? 0})',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.accentBlue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s),
                    Text(
                      'Banned accounts: ${stats['bannedUsers']}',
                      style: AppTextStyles.bodyMedium,
                    ),
                    Text(
                      'Published reviews: ${stats['totalReviews']}',
                      style: AppTextStyles.bodyMedium,
                    ),
                    Text(
                      'Active conversations: ${stats['totalConversations']}',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _UsersSection extends StatelessWidget {
  const _UsersSection({required this.service, required this.searchQuery});

  final AdminService service;
  final String searchQuery;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: service.watchUsers(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data!.docs.where((doc) {
          if (searchQuery.isEmpty) {
            return true;
          }
          final data = doc.data();
          final haystack = [
            data['name'],
            data['email'],
            data['accountType'],
            data['businessName'],
            data['profession'],
          ].whereType<String>().join(' ').toLowerCase();
          return haystack.contains(searchQuery);
        }).toList();

        if (users.isEmpty) {
          return const Center(child: Text('No users match your search.'));
        }

        return ListView.separated(
          itemCount: users.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s),
          itemBuilder: (context, index) {
            final user = users[index];
            final data = user.data();
            final isBanned = data['isBanned'] == true;
            final displayName =
                data['businessName']?.toString().trim().isNotEmpty == true
                ? data['businessName'].toString()
                : data['name']?.toString() ?? 'Unknown';

            return Container(
              padding: const EdgeInsets.all(AppSpacing.m),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: AppTextStyles.headingSmall,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              data['email']?.toString() ?? 'No email',
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ),
                      Chip(
                        label: Text(
                          data['accountType']?.toString() ?? 'client',
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s),
                      if (isBanned)
                        const Chip(
                          backgroundColor: Color(0xFFFFE4E1),
                          label: Text('Banned'),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s),
                  Text(
                    'Phone: ${data['phone']?.toString() ?? 'N/A'}',
                    style: AppTextStyles.bodyMedium,
                  ),
                  Text(
                    'Rating: ${((data['rating'] as num?)?.toDouble() ?? 0).toStringAsFixed(1)} (${data['reviewCount'] ?? 0})',
                    style: AppTextStyles.bodyMedium,
                  ),
                  if (data['verificationStatus'] != null)
                    Text(
                      'Verification: ${data['verificationStatus']}',
                      style: AppTextStyles.bodyMedium,
                    ),
                  const SizedBox(height: AppSpacing.m),
                  Wrap(
                    spacing: AppSpacing.s,
                    runSpacing: AppSpacing.s,
                    children: [
                      OutlinedButton(
                        onPressed: () => _showBanDialog(
                          context: context,
                          service: service,
                          userId: user.id,
                          isBanned: isBanned,
                        ),
                        child: Text(isBanned ? 'Unban' : 'Suspend'),
                      ),
                      OutlinedButton(
                        onPressed: () => _showDeleteDialog(
                          context: context,
                          service: service,
                          userId: user.id,
                          displayName: displayName,
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.errorRed,
                        ),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showBanDialog({
    required BuildContext context,
    required AdminService service,
    required String userId,
    required bool isBanned,
  }) async {
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(isBanned ? 'Restore account' : 'Suspend account'),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: isBanned
                  ? 'Optional note for restoration'
                  : 'Reason for suspension',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await service.setUserBanState(
                  userId: userId,
                  isBanned: !isBanned,
                  reason: controller.text.trim(),
                );
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
              child: Text(isBanned ? 'Restore' : 'Suspend'),
            ),
          ],
        );
      },
    );
    controller.dispose();
  }

  Future<void> _showDeleteDialog({
    required BuildContext context,
    required AdminService service,
    required String userId,
    required String displayName,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete user'),
          content: Text('Delete $displayName from Firestore?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await service.deleteUserProfile(userId);
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.errorRed,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}

class _VerificationsSection extends StatelessWidget {
  const _VerificationsSection({required this.service});

  final AdminService service;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: service.watchPendingVerifications(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data!.docs;
        if (users.isEmpty) {
          return const Center(
            child: Text('No pending provider verifications.'),
          );
        }

        return ListView.separated(
          itemCount: users.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s),
          itemBuilder: (context, index) {
            final doc = users[index];
            final data = doc.data();
            final documents = Map<String, dynamic>.from(
              data['documents'] ?? const {},
            );
            return Container(
              padding: const EdgeInsets.all(AppSpacing.m),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['name']?.toString() ?? 'Unnamed provider',
                    style: AppTextStyles.headingSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${data['profession'] ?? 'Work provider'} - ${data['email'] ?? 'No email'}',
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: AppSpacing.s),
                  Text(
                    'AI reason: ${data['verificationReason'] ?? 'Awaiting manual review.'}',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.s),
                  if (documents.isNotEmpty)
                    Text(
                      'Documents: ${(documents['diplomaURL'] ?? 'N/A')} | ${(documents['idURL'] ?? 'N/A')}',
                      style: AppTextStyles.caption,
                    ),
                  const SizedBox(height: AppSpacing.m),
                  Wrap(
                    spacing: AppSpacing.s,
                    runSpacing: AppSpacing.s,
                    children: [
                      ElevatedButton(
                        onPressed: () =>
                            _reviewVerification(context, service, doc.id, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.availableGreen,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Approve'),
                      ),
                      OutlinedButton(
                        onPressed: () => _reviewVerification(
                          context,
                          service,
                          doc.id,
                          false,
                        ),
                        child: const Text('Reject'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _reviewVerification(
    BuildContext context,
    AdminService service,
    String userId,
    bool approved,
  ) async {
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            approved ? 'Approve verification' : 'Reject verification',
          ),
          content: TextField(
            controller: controller,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: approved
                  ? 'Optional admin note'
                  : 'Reason for rejection',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await service.reviewVerification(
                  userId: userId,
                  approved: approved,
                  reason: controller.text.trim(),
                );
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
              child: Text(approved ? 'Approve' : 'Reject'),
            ),
          ],
        );
      },
    );
    controller.dispose();
  }
}

class _ReportsSection extends StatelessWidget {
  const _ReportsSection({required this.service, required this.searchQuery});

  final AdminService service;
  final String searchQuery;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: service.watchReports(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final reports = snapshot.data!.docs.where((doc) {
          if (searchQuery.isEmpty) {
            return true;
          }
          final data = doc.data();
          final haystack = [
            data['reason'],
            data['status'],
            data['adminAction'],
          ].whereType<String>().join(' ').toLowerCase();
          return haystack.contains(searchQuery);
        }).toList();

        if (reports.isEmpty) {
          return const Center(child: Text('No reports found.'));
        }

        return ListView.separated(
          itemCount: reports.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s),
          itemBuilder: (context, index) {
            final report = reports[index];
            final data = report.data();
            return Container(
              padding: const EdgeInsets.all(AppSpacing.m),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Report ${report.id.substring(0, 6)}',
                    style: AppTextStyles.headingSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Reporter: ${data['reporterId']}',
                    style: AppTextStyles.caption,
                  ),
                  Text(
                    'Reported user: ${data['reportedUserId']}',
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: AppSpacing.s),
                  Text(
                    data['reason']?.toString().trim().isNotEmpty == true
                        ? data['reason'].toString()
                        : 'No reason provided.',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.s),
                  Text(
                    'Status: ${data['status'] ?? 'pending'}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.accentBlue,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  Wrap(
                    spacing: AppSpacing.s,
                    runSpacing: AppSpacing.s,
                    children: [
                      OutlinedButton(
                        onPressed: () => service.resolveReport(
                          reportId: report.id,
                          status: 'resolved',
                          adminAction: 'warning',
                        ),
                        child: const Text('Warning'),
                      ),
                      OutlinedButton(
                        onPressed: () async {
                          await service.setUserBanState(
                            userId: data['reportedUserId'].toString(),
                            isBanned: true,
                            reason:
                                data['reason']?.toString() ?? 'Report action',
                          );
                          await service.resolveReport(
                            reportId: report.id,
                            status: 'resolved',
                            adminAction: 'suspend',
                          );
                        },
                        child: const Text('Suspend'),
                      ),
                      OutlinedButton(
                        onPressed: () async {
                          await service.setUserBanState(
                            userId: data['reportedUserId'].toString(),
                            isBanned: true,
                            reason:
                                'Permanent moderation action: ${data['reason'] ?? 'Report'}',
                          );
                          await service.resolveReport(
                            reportId: report.id,
                            status: 'resolved',
                            adminAction: 'ban',
                          );
                        },
                        child: const Text('Ban'),
                      ),
                      OutlinedButton(
                        onPressed: () => service.resolveReport(
                          reportId: report.id,
                          status: 'dismissed',
                          adminAction: 'dismissed',
                        ),
                        child: const Text('Dismiss'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ReviewsSection extends StatelessWidget {
  const _ReviewsSection({required this.service, required this.searchQuery});

  final AdminService service;
  final String searchQuery;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: service.watchReviews(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final reviews = snapshot.data!.docs.where((doc) {
          if (searchQuery.isEmpty) {
            return true;
          }
          final data = doc.data();
          final haystack = [
            data['reviewerName'],
            data['text'],
            data['response'],
          ].whereType<String>().join(' ').toLowerCase();
          return haystack.contains(searchQuery);
        }).toList();

        if (reviews.isEmpty) {
          return const Center(child: Text('No reviews found.'));
        }

        return ListView.separated(
          itemCount: reviews.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s),
          itemBuilder: (context, index) {
            final review = reviews[index];
            final data = review.data();
            final parentPath =
                review.reference.parent.parent?.path ?? 'unknown';
            return Container(
              padding: const EdgeInsets.all(AppSpacing.m),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['reviewerName']?.toString() ?? 'Anonymous',
                    style: AppTextStyles.headingSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rating: ${((data['rating'] as num?)?.toDouble() ?? 0).toStringAsFixed(1)}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.starGold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s),
                  Text(
                    data['text']?.toString().trim().isNotEmpty == true
                        ? data['text'].toString()
                        : 'No review text.',
                    style: AppTextStyles.bodyMedium,
                  ),
                  if (data['response']?.toString().trim().isNotEmpty ==
                      true) ...[
                    const SizedBox(height: AppSpacing.s),
                    Text(
                      'Response: ${data['response']}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.accentBlue,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.s),
                  Text(
                    'Target path: $parentPath',
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: AppSpacing.m),
                  OutlinedButton(
                    onPressed: () =>
                        service.deleteReview(review.reference.path),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.errorRed,
                    ),
                    child: const Text('Delete review'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.accentBlue),
          const SizedBox(height: AppSpacing.m),
          Text(value, style: AppTextStyles.headingLarge),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}
