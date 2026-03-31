import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/models/client_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../services/storage_service.dart';
import '../../../core/widgets/map_preview_widget.dart';

class ClientProfileSetupScreen extends ConsumerStatefulWidget {
  const ClientProfileSetupScreen({super.key});

  @override
  ConsumerState<ClientProfileSetupScreen> createState() => _ClientProfileSetupScreenState();
}

class _ClientProfileSetupScreenState extends ConsumerState<ClientProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  File? _profileImage;
  GeoPoint? _location;
  String _selectedLanguage = 'en';
  bool _isLoading = false;
  bool _isLoadingLocation = false;
  bool _notificationsEnabled = true;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() => _profileImage = File(picked.path));
    }
  }

  Future<void> _detectLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Location services are disabled.');
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions denied.');
        }
      }
      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        _location = GeoPoint(pos.latitude, pos.longitude);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location detected!'), backgroundColor: AppColors.availableGreen),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final authService = ref.read(authServiceProvider);
      final uid = authService.currentUser!.uid;
      final email = authService.currentUser!.email!;

      String? photoUrl;
      if (_profileImage != null) {
        photoUrl = await StorageService.uploadProfilePicture(uid, _profileImage!);
      }

      final client = ClientModel(
        id: uid,
        email: email,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        photoUrl: photoUrl,
        location: _location,
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        language: _selectedLanguage,
        createdAt: DateTime.now(),
      );

      await authService.setupProfile(client);
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: AppSpacing.pagePadding,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.l),
                  // Progress indicator
                  _buildProgress(3, 3),
                  const SizedBox(height: AppSpacing.xl),
                  Text('Set Up Your Profile', style: AppTextStyles.headingLarge.copyWith(fontSize: 28)),
                  const SizedBox(height: AppSpacing.s),
                  Text('As a Client', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.accentBlue, fontWeight: FontWeight.w600)),
                  const SizedBox(height: AppSpacing.xxl),

                  // Profile photo
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.accentBlue.withOpacity(0.08),
                              border: Border.all(color: AppColors.accentBlue.withOpacity(0.3), width: 2),
                              image: _profileImage != null
                                  ? DecorationImage(image: FileImage(_profileImage!), fit: BoxFit.cover)
                                  : null,
                            ),
                            child: _profileImage == null
                                ? const Icon(Icons.person_outline, size: 40, color: AppColors.accentBlue)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: AppColors.accentBlue,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(child: Text('Optional', style: AppTextStyles.caption.copyWith(color: AppColors.softGray))),
                  const SizedBox(height: AppSpacing.xxl),

                  _buildLabel('FULL NAME *'),
                  TextFormField(
                    controller: _nameController,
                    decoration: _inputDecoration('Your full name', Icons.person_outline),
                    validator: (v) => v == null || v.isEmpty ? 'Name is required' : null,
                  ),
                  const SizedBox(height: AppSpacing.l),

                  _buildLabel('PHONE NUMBER *'),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: _inputDecoration('+213 --- --- ---', Icons.phone_outlined),
                    validator: (v) => v == null || v.isEmpty ? 'Phone is required' : null,
                  ),
                  const SizedBox(height: AppSpacing.l),

                  _buildLabel('LOCATION'),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _addressController,
                          decoration: _inputDecoration('Enter your address', Icons.location_on_outlined),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _isLoadingLocation
                          ? const SizedBox(width: 56, height: 56, child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
                          : Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: _location != null ? AppColors.availableGreen.withOpacity(0.1) : AppColors.accentBlue.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _location != null ? AppColors.availableGreen : AppColors.accentBlue.withOpacity(0.3),
                                ),
                              ),
                              child: IconButton(
                                icon: Icon(
                                  _location != null ? Icons.my_location_rounded : Icons.gps_fixed_rounded,
                                  color: _location != null ? AppColors.availableGreen : AppColors.accentBlue,
                                ),
                                onPressed: _detectLocation,
                              ),
                            ),
                    ],
                  ),
                  if (_location != null) ...[
                    const SizedBox(height: AppSpacing.m),
                    MapPreviewWidget(
                      latitude: _location!.latitude,
                      longitude: _location!.longitude,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: AppColors.availableGreen, size: 14),
                          const SizedBox(width: 4),
                          Text('Location confirmed', style: AppTextStyles.caption.copyWith(color: AppColors.availableGreen)),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.l),

                  _buildLabel('PREFERRED LANGUAGE'),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.softGray.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedLanguage,
                        items: const [
                          DropdownMenuItem(value: 'en', child: Text('English')),
                          DropdownMenuItem(value: 'fr', child: Text('Français')),
                          DropdownMenuItem(value: 'ar', child: Text('العربية')),
                        ],
                        onChanged: (v) => setState(() => _selectedLanguage = v!),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.l),

                  // Notifications
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.softGray.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SwitchListTile(
                      title: Text('Enable Push Notifications', style: AppTextStyles.bodyMedium),
                      value: _notificationsEnabled,
                      onChanged: (v) => setState(() => _notificationsEnabled = v),
                      activeColor: AppColors.accentBlue,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
                        ),
                      ),
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                          : const Text('Create Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgress(int current, int total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Step $current of $total', style: AppTextStyles.caption),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: current / total,
            backgroundColor: AppColors.softGray.withOpacity(0.15),
            valueColor: const AlwaysStoppedAnimation(AppColors.accentBlue),
            minHeight: 4,
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.8)),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.softGray, size: 20),
      filled: true,
      fillColor: AppColors.softGray.withOpacity(0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
    );
  }
}
