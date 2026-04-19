import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/services/location_service.dart';
import '../../../core/widgets/primary_button.dart';
import '../providers/profile_provider.dart';
import '../../auth/providers/auth_provider.dart';

class ProviderSetupScreen extends ConsumerStatefulWidget {
  const ProviderSetupScreen({super.key});

  @override
  ConsumerState<ProviderSetupScreen> createState() =>
      _ProviderSetupScreenState();
}

class _ProviderSetupScreenState extends ConsumerState<ProviderSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _professionController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _experienceController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  String _selectedCategory = 'Plumber';

  GeoPoint? _workZone;
  bool _locating = false;
  bool _saving = false;

  @override
  void dispose() {
    _professionController.dispose();
    _descriptionController.dispose();
    _experienceController.dispose();
    _hourlyRateController.dispose();
    super.dispose();
  }

  Future<void> _captureLocation() async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      final pos = await LocationService().getCurrentLocation();
      if (!mounted) return;
      if (pos == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not get your location. Please enable location services and try again.',
            ),
          ),
        );
        return;
      }
      setState(() => _workZone = GeoPoint(pos.latitude, pos.longitude));
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _handleSave() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;
    if (_workZone == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Please capture your work zone location before continuing.'),
        ),
      );
      return;
    }

    final uid = ref.read(authStateProvider).value?.uid;
    if (uid == null) return;

    setState(() => _saving = true);
    try {
      final rateText = _hourlyRateController.text.trim();
      await ref.read(profileServiceProvider).setupProviderProfile(
            uid: uid,
            profession: _professionController.text.trim(),
            category: _selectedCategory,
            description: _descriptionController.text.trim(),
            experience: int.tryParse(_experienceController.text.trim()) ?? 0,
            hourlyRate: rateText.isEmpty ? null : double.tryParse(rateText),
            workZone: _workZone!,
          );
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not save profile. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: const Text('Complete Provider Profile'), elevation: 0),
      body: AbsorbPointer(
        absorbing: _saving,
        child: SingleChildScrollView(
          padding: AppSpacing.pagePadding,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tell us about your services',
                    style: AppTextStyles.bodyMedium),
                const SizedBox(height: AppSpacing.xxl),

                _buildLabel('PROFESSION'),
                TextFormField(
                  controller: _professionController,
                  decoration: _inputDecoration('e.g. Master Electrician'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: AppSpacing.l),

                _buildLabel('CATEGORY'),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  items: const ['Plumber', 'Electrician', 'Painter', 'Carpenter']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _selectedCategory = v ?? _selectedCategory),
                  decoration: _inputDecoration(''),
                ),
                const SizedBox(height: AppSpacing.l),

                _buildLabel('EXPERIENCE (YEARS)'),
                TextFormField(
                  controller: _experienceController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration('e.g. 5'),
                  validator: (v) {
                    final t = (v ?? '').trim();
                    if (t.isEmpty) return 'Required';
                    final n = int.tryParse(t);
                    if (n == null || n < 0 || n > 80) {
                      return 'Enter a valid number of years';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.l),

                _buildLabel('HOURLY RATE (optional)'),
                TextFormField(
                  controller: _hourlyRateController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: _inputDecoration('e.g. 35'),
                ),
                const SizedBox(height: AppSpacing.l),

                _buildLabel('DESCRIPTION'),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: _inputDecoration('Describe your services...'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: AppSpacing.l),

                _buildLabel('WORK ZONE'),
                _buildLocationPicker(),
                const SizedBox(height: AppSpacing.xxl),

                PrimaryButton(
                  text: _saving ? 'Saving…' : 'Complete Setup',
                  onPressed: _saving ? null : _handleSave,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationPicker() {
    final hasLocation = _workZone != null;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: AppColors.softGray.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasLocation
              ? AppColors.accentBlue.withValues(alpha: 0.3)
              : AppColors.softGray.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasLocation ? Icons.check_circle : Icons.location_on_outlined,
                color: hasLocation
                    ? AppColors.availableGreen
                    : AppColors.softGray,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hasLocation
                      ? '${_workZone!.latitude.toStringAsFixed(4)}, ${_workZone!.longitude.toStringAsFixed(4)}'
                      : 'No location captured yet',
                  style: AppTextStyles.bodyMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _locating ? null : _captureLocation,
            icon: _locating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location),
            label: Text(hasLocation ? 'Update location' : 'Use my location'),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s),
      child: Text(label,
          style: AppTextStyles.labelSmall
              .copyWith(fontWeight: FontWeight.w700)),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.softGray.withValues(alpha: 0.05),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }
}
