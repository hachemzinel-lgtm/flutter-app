import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../auth/providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Account Settings'), elevation: 0),
      body: ListView(
        padding: AppSpacing.pagePadding,
        children: [
          _buildProfileHeader(context, user),
          const SizedBox(height: AppSpacing.xl),
          
          _buildSectionTitle('ACCOUNT'),
          _settingsTile(Icons.person_outline, 'Edit Profile', () => context.push('/edit-profile')),
          _settingsTile(Icons.notifications_none, 'Notifications', () => context.push('/notifications')),
          _settingsTile(Icons.favorite_border, 'Favorites', () => context.push('/favorites')),
          
          const SizedBox(height: AppSpacing.l),
          _buildSectionTitle('PREFERENCES'),
          _settingsTile(Icons.language, 'Language', () => context.push('/language')),
          _settingsTile(Icons.dark_mode_outlined, 'Dark Mode', () {}, trailing: Switch(value: false, onChanged: (v) {})),
          
          const SizedBox(height: AppSpacing.l),
          _buildSectionTitle('HELP & SUPPORT'),
          _settingsTile(Icons.help_outline, 'Help Center', () {}),
          _settingsTile(Icons.privacy_tip_outlined, 'Privacy Policy', () {}),
          
          const SizedBox(height: AppSpacing.xl),
          TextButton(
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
              context.go('/login');
            },
            child: Text(
              'Sign Out',
              style: AppTextStyles.bodyLarge.copyWith(color: AppColors.errorRed, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, dynamic user) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: AppColors.accentBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: AppColors.softGray.withValues(alpha: 0.1),
            backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
            child: user?.photoURL == null ? const Icon(Icons.person, size: 35, color: AppColors.softGray) : null,
          ),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user?.displayName ?? 'Guest User', style: AppTextStyles.headingSmall),
                Text(user?.email ?? 'No email', style: AppTextStyles.caption),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.accentBlue),
            onPressed: () => context.push('/edit-profile'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s, left: AppSpacing.s),
      child: Text(
        title,
        style: AppTextStyles.labelSmall.copyWith(
          letterSpacing: 1.2,
          fontWeight: FontWeight.w800,
          color: AppColors.textLight.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  Widget _settingsTile(IconData icon, String title, VoidCallback onTap, {Widget? trailing}) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppColors.textDark, size: 22),
      title: Text(title, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w500)),
      trailing: trailing ?? const Icon(Icons.chevron_right, size: 20, color: AppColors.softGray),
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.s),
    );
  }
}
