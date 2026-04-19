import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/primary_button.dart';
import '../providers/profile_provider.dart';
import '../../auth/providers/auth_provider.dart';

class MerchantSetupScreen extends ConsumerStatefulWidget {
  const MerchantSetupScreen({super.key});

  @override
  ConsumerState<MerchantSetupScreen> createState() => _MerchantSetupScreenState();
}

class _MerchantSetupScreenState extends ConsumerState<MerchantSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _addressController = TextEditingController();
  String _category = 'Home Decor';

  Future<void> _handleSave() async {
    if (_formKey.currentState!.validate()) {
      final uid = ref.read(authStateProvider).value?.uid;
      if (uid == null) return;

      try {
        await ref.read(profileServiceProvider).setupMerchantProfile(
          uid: uid,
          storeName: _nameController.text,
          category: _category,
          description: _descController.text,
          address: _addressController.text,
          openingHours: {'Mon-Fri': '09:00 - 18:00', 'Sat': '10:00 - 15:00'},
        );
        if (mounted) context.go('/home');
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Setup Your Store'), elevation: 0),
      body: SingleChildScrollView(
        padding: AppSpacing.pagePadding,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Start selling on NearWork', style: AppTextStyles.bodyMedium),
              const SizedBox(height: AppSpacing.xxl),
              
              _buildLabel('STORE NAME'),
              TextFormField(
                controller: _nameController,
                decoration: _inputDecoration('e.g. Sterling Hardware'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: AppSpacing.l),
              
              _buildLabel('CATEGORY'),
              DropdownButtonFormField<String>(
                value: _category,
                items: ['Home Decor', 'Hardware', 'Gardening', 'Tools']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v!),
                decoration: _inputDecoration(''),
              ),
              const SizedBox(height: AppSpacing.l),

              _buildLabel('BUSINESS ADDRESS'),
              TextFormField(
                controller: _addressController,
                decoration: _inputDecoration('e.g. 123 Main St, Tunis'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: AppSpacing.l),

              _buildLabel('STORE DESCRIPTION'),
              TextFormField(
                controller: _descController,
                maxLines: 4,
                decoration: _inputDecoration('Tell customers about your products...'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: AppSpacing.xxl),

              PrimaryButton(text: 'Launch Store', onPressed: _handleSave),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s),
      child: Text(label, style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w700)),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.softGray.withValues(alpha: 0.05),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }
}
