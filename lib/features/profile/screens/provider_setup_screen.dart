import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/primary_button.dart';
import '../providers/profile_provider.dart';
import '../../auth/providers/auth_provider.dart';

class ProviderSetupScreen extends ConsumerStatefulWidget {
  const ProviderSetupScreen({super.key});

  @override
  ConsumerState<ProviderSetupScreen> createState() => _ProviderSetupScreenState();
}

class _ProviderSetupScreenState extends ConsumerState<ProviderSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _professionController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _experienceController = TextEditingController();
  String _selectedCategory = 'Plumber';

  Future<void> _handleSave() async {
    if (_formKey.currentState!.validate()) {
      final uid = ref.read(authStateProvider).value?.uid;
      if (uid == null) return;

      try {
        await ref.read(profileServiceProvider).setupProviderProfile(
          uid: uid,
          profession: _professionController.text,
          category: _selectedCategory,
          description: _descriptionController.text,
          experience: int.parse(_experienceController.text),
          workZone: const GeoPoint(36.8065, 10.1815), // Placeholder
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
      appBar: AppBar(title: const Text('Complete Provider Profile'), elevation: 0),
      body: SingleChildScrollView(
        padding: AppSpacing.pagePadding,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tell us about your services', style: AppTextStyles.bodyMedium),
              const SizedBox(height: AppSpacing.xxl),
              
              _buildLabel('PROFESSION'),
              TextFormField(
                controller: _professionController,
                decoration: _inputDecoration('e.g. Master Electrician'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: AppSpacing.l),
              
              _buildLabel('CATEGORY'),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: ['Plumber', 'Electrician', 'Painter', 'Carpenter']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCategory = v!),
                decoration: _inputDecoration(''),
              ),
              const SizedBox(height: AppSpacing.l),

              _buildLabel('EXPERIENCE (YEARS)'),
              TextFormField(
                controller: _experienceController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration('e.g. 5'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: AppSpacing.l),

              _buildLabel('DESCRIPTION'),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: _inputDecoration('Describe your services...'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: AppSpacing.xxl),

              PrimaryButton(text: 'Complete Setup', onPressed: _handleSave),
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
