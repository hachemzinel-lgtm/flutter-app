import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flutter_application_1/views/app_colors.dart';
import 'package:flutter_application_1/views/app_spacing.dart';
import 'package:flutter_application_1/views/app_text_styles.dart';
import 'package:flutter_application_1/routes/route_paths.dart';
import 'package:flutter_application_1/views/map_preview_widget.dart';
import 'package:flutter_application_1/services/location_lookup_service.dart';
import 'package:flutter_application_1/services/services_notification_service.dart';
import 'package:flutter_application_1/services/storage_service.dart';
import 'package:flutter_application_1/providers/auth_providers.dart';

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
  String _language = 'English';
  bool _notificationsEnabled = true;
  bool _isDetectingLocation = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Camera'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Gallery'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) {
      return;
    }

    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() => _profileImage = File(picked.path));
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isDetectingLocation = true);
    try {
      final result = await LocationLookupService.detectCurrentLocation();
      setState(() {
        _location = result.geoPoint;
        _addressController.text = result.address;
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
        setState(() => _isDetectingLocation = false);
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_location == null && _addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please provide your address or use your current location.',
          ),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) {
        throw Exception('You must be signed in to complete profile setup.');
      }

      String? imageUrl;
      if (_profileImage != null) {
        imageUrl = await StorageService.uploadProfilePicture(
          user.uid,
          _profileImage!,
        );
      }

      await ref.read(userRepositoryProvider).updateUserDocument(user.uid, {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'profilePicture': imageUrl,
        'location': _location,
        'address': _addressController.text.trim(),
        'language': _language.toLowerCase(),
        'notificationsEnabled': _notificationsEnabled,
        'profileComplete': true,
        'profileCompleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await NotificationService.initialize();
      if (mounted) {
        context.go(AppRoutes.clientHome);
      }
    } catch (error, stackTrace) {
      print('--- [CLIENT SETUP] ERROR: $error');
      print('--- [CLIENT SETUP] Stack trace: $stackTrace');
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
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Client Profile Setup')),
      body: SingleChildScrollView(
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
                'Tell us how clients and providers can reach you.',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xl),
              Center(
                child: GestureDetector(
                  onTap: _isSubmitting ? null : _pickImage,
                  child: CircleAvatar(
                    radius: 52,
                    backgroundColor: AppColors.backgroundSecondary,
                    backgroundImage: _profileImage == null
                        ? null
                        : FileImage(_profileImage!),
                    child: _profileImage == null
                        ? const Icon(
                            Icons.camera_alt_outlined,
                            size: 28,
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
                  style: AppTextStyles.bodyMedium,
                ),
              ),
              const SizedBox(height: AppSpacing.l),
              _label('Full Name'),
              TextFormField(
                controller: _nameController,
                decoration: _inputDecoration(
                  'Your full name',
                  Icons.person_outline,
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) {
                    return 'Full name is required';
                  }
                  if (text.length < 2 || text.length > 50) {
                    return 'Full name must be between 2 and 50 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.l),
              _label('Phone Number'),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration('+234...', Icons.phone_outlined),
                validator: (value) {
                  final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
                  if (digits.length < 7) {
                    return 'Please enter a valid phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.l),
              _label('Address'),
              TextFormField(
                controller: _addressController,
                decoration: _inputDecoration(
                  'Street, city, state',
                  Icons.location_on_outlined,
                ),
              ),
              const SizedBox(height: AppSpacing.m),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isDetectingLocation || _isSubmitting
                      ? null
                      : _useCurrentLocation,
                  icon: _isDetectingLocation
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location_outlined),
                  label: const Text('Use My Current Location'),
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
              _label('Language'),
              DropdownButtonFormField<String>(
                initialValue: _language,
                decoration: _dropdownDecoration(),
                items: const [
                  DropdownMenuItem(value: 'English', child: Text('English')),
                  DropdownMenuItem(value: 'French', child: Text('French')),
                  DropdownMenuItem(value: 'Arabic', child: Text('Arabic')),
                ],
                onChanged: _isSubmitting
                    ? null
                    : (value) => setState(() => _language = value ?? 'English'),
              ),
              const SizedBox(height: AppSpacing.s),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Enable push notifications'),
                value: _notificationsEnabled,
                activeThumbColor: AppColors.accentBlue,
                onChanged: _isSubmitting
                    ? null
                    : (value) => setState(() => _notificationsEnabled = value),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                height: AppSpacing.buttonHeight,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppSpacing.borderRadius,
                      ),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save & Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s),
      child: Text(
        text,
        style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: AppColors.backgroundSecondary,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
        borderSide: BorderSide.none,
      ),
    );
  }

  InputDecoration _dropdownDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: AppColors.backgroundSecondary,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
        borderSide: BorderSide.none,
      ),
    );
  }
}
