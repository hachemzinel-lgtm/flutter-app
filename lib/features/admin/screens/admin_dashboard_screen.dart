import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NearWork Admin Panel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Row(
        children: [
          _buildSidebar(),
          const VerticalDivider(width: 1),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return NavigationRail(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (value) => setState(() => _selectedIndex = value),
      labelType: NavigationRailLabelType.all,
      destinations: const [
        NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: Text('Stats')),
        NavigationRailDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: Text('Users')),
        NavigationRailDestination(icon: Icon(Icons.verified_user_outlined), selectedIcon: Icon(Icons.verified_user), label: Text('Verifications')),
        NavigationRailDestination(icon: Icon(Icons.report_outlined), selectedIcon: Icon(Icons.report), label: Text('Reports')),
      ],
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0: return _buildStats();
      case 1: return _buildUsers();
      case 2: return _buildVerifications();
      case 3: return _buildReports();
      default: return const Center(child: Text('Dashboard Content'));
    }
  }

  Widget _buildStats() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Platform Overview', style: AppTextStyles.headingMedium),
          const SizedBox(height: 24),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 3,
            crossAxisSpacing: 24,
            mainAxisSpacing: 24,
            childAspectRatio: 1.5,
            children: [
              _statCard('Total Users', '1,245', Icons.people, Colors.blue),
              _statCard('Active Providers', '156', Icons.handyman, Colors.orange),
              _statCard('Success Rate', '94%', Icons.check_circle, Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.2))),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(value, style: AppTextStyles.headingLarge.copyWith(color: color)),
          Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.softGray)),
        ],
      ),
    );
  }

  Widget _buildUsers() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final users = snapshot.data!.docs;
        return ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: users.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (ctx, i) {
            final data = users[i].data() as Map<String, dynamic>;
            return ListTile(
              title: Text(data['name'] ?? 'No Name'),
              subtitle: Text(data['email'] ?? 'No Email'),
              trailing: Chip(label: Text(data['accountType'] ?? 'client')),
            );
          },
        );
      },
    );
  }

  Widget _buildVerifications() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').where('verificationStatus', isEqualTo: 'pending').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('No pending verifications.'));

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: docs.length,
          itemBuilder: (ctx, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return Card(
              child: ListTile(
                title: Text(data['name']),
                subtitle: const Text('Pending manual review'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(onPressed: () => _verify(docs[i].id, true), child: const Text('Approve', style: TextStyle(color: Colors.green))),
                    TextButton(onPressed: () => _verify(docs[i].id, false), child: const Text('Reject', style: TextStyle(color: Colors.red))),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _verify(String id, bool approved) async {
    await FirebaseFirestore.instance.collection('users').doc(id).update({
      'verificationStatus': approved ? 'approved' : 'rejected',
      'isVerified': approved,
    });
  }

  Widget _buildReports() {
    return const Center(child: Text('Report Moderation Section'));
  }
}
