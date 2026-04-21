import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flutter_application_1/views/app_colors.dart';
import 'package:flutter_application_1/views/app_spacing.dart';
import 'package:flutter_application_1/views/app_text_styles.dart';
import 'package:flutter_application_1/views/marketplace_taxonomy.dart';
import 'package:flutter_application_1/models/client_model.dart';
import 'package:flutter_application_1/views/map_preview_widget.dart';
import 'package:flutter_application_1/services/storage_service.dart';
import 'package:flutter_application_1/providers/auth_provider.dart';

class ClientProfileSetupScreen extends ConsumerStatefulWidget {
  const ClientProfileSetupScreen({super.key});

  @override
  ConsumerState<ClientProfileSetupScreen> createState() =>
      _ClientProfileSetupScreenState();
}

class _ClientProfileSetupScreenState
    extends ConsumerState<ClientProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  File? _profileImage;
  GeoPoint? _location;
  String _language = MarketplaceTaxonomy.supportedLanguages.first;
  bool _notificationsEnabled = true;
  bool _detectingLocation = false;
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() => _profileImage = File(picked.path));
    }
  }

  Future<void> _detectLocation() async {
    setState(() => _detectingLocation = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        throw Exception('Location permission is required.');
      }

      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _location = GeoPoint(position.latitude, position.longitude);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: AppColors.errorRed,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _detectingLocation = false);
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _submitting = true);
    try {
      final authService = ref.read(authServiceProvider);
      final uid = authService.currentUser!.uid;
      final email = authService.currentUser!.email!;

      String? photoUrl;
      if (_profileImage != null) {
        photoUrl = await StorageService.uploadProfilePicture(
          uid,
          _profileImage!,
        );
      }

      final client = ClientModel(
        id: uid,
        email: email,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        photoUrl: photoUrl,
        location: _location,
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        language: _language,
        createdAt: DateTime.now(),
        notificationsEnabled: _notificationsEnabled,
      );

      await authService.setupProfile(client);
      if (mounted) {
        context.go('/home');
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: AppColors.errorRed,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.pagePadding,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Set up your client profile',
                  style: AppTextStyles.headingLarge,
                ),
                const SizedBox(height: AppSpacing.s),
                Text(
                  'Add your contact details, language, and saved location.',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xxl),
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.accentBlue.withValues(
                        alpha: 0.12,
                      ),
                      backgroundImage: _profileImage == null
                          ? null
                          : FileImage(_profileImage!),
                      child: _profileImage == null
                          ? const Icon(
                              Icons.person_outline,
                              size: 40,
                              color: AppColors.accentBlue,
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.s),
                Center(
                  child: Text(
                    'Profile picture is optional',
                    style: AppTextStyles.caption,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                _label('FULL NAME'),
                TextFormField(
                  controller: _nameController,
                  validator: _requiredValidator,
                  decoration: _inputDecoration(
                    'Your full name',
                    Icons.person_outline,
                  ),
                ),
                const SizedBox(height: AppSpacing.l),
                _label('PHONE NUMBER'),
                TextFormField(
                  controller: _phoneController,
                  validator: _requiredValidator,
                  keyboardType: TextInputType.phone,
                  decoration: _inputDecoration('+234...', Icons.phone_outlined),
                ),
                const SizedBox(height: AppSpacing.l),
                _label('ADDRESS'),
                TextFormField(
                  controller: _addressController,
                  decoration: _inputDecoration(
                    'Street, city, postal code',
                    Icons.location_on_outlined,
                  ),
                ),
                const SizedBox(height: AppSpacing.m),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _detectingLocation ? null : _detectLocation,
                    icon: _detectingLocation
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location_outlined),
                    label: const Text('Use my current location'),
                  ),
                ),
                if (_location != null) ...[
                  const SizedBox(height: AppSpacing.m),
                  MapPreviewWidget(
                    latitude: _location!.latitude,
                    longitude: _location!.longitude,
                  ),
                ],
                const SizedBox(height: AppSpacing.l),
                _label('PREFERRED LANGUAGE'),
                _languageDropdown(),
                const SizedBox(height: AppSpacing.m),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeTrackColor: AppColors.accentBlue,
                  title: const Text('Enable push notifications'),
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() => _notificationsEnabled = value);
                  },
                ),
                const SizedBox(height: AppSpacing.xxl),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryNavy,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Create account'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _languageDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.softGray.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: _language,
          items: const [
            DropdownMenuItem(value: 'en', child: Text('English')),
            DropdownMenuItem(value: 'fr', child: Text('French')),
            DropdownMenuItem(value: 'ar', child: Text('Arabic')),
          ],
          onChanged: (value) => setState(() => _language = value!),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: AppTextStyles.labelSmall.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.softGray),
      filled: true,
      fillColor: AppColors.softGray.withValues(alpha: 0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
        borderSide: BorderSide.none,
      ),
    );
  }
}
