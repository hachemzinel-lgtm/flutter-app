import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flutter_application_1/views/app_colors.dart';
import 'package:flutter_application_1/views/app_spacing.dart';
import 'package:flutter_application_1/views/app_text_styles.dart';
import 'package:flutter_application_1/views/marketplace_taxonomy.dart';
import 'package:flutter_application_1/models/marketplace_model.dart';
import 'package:flutter_application_1/views/map_preview_widget.dart';
import 'package:flutter_application_1/services/location_service.dart';
import 'package:flutter_application_1/services/storage_service.dart';
import 'package:flutter_application_1/providers/auth_provider.dart';

class MarketplaceProfileSetupScreen extends ConsumerStatefulWidget {
  const MarketplaceProfileSetupScreen({super.key});

  @override
  ConsumerState<MarketplaceProfileSetupScreen> createState() =>
      _MarketplaceProfileSetupScreenState();
}

class _MarketplaceProfileSetupScreenState
    extends ConsumerState<MarketplaceProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();

  File? _storefrontImage;
  GeoPoint? _location;
  final List<File> _photos = [];
  String _category = MarketplaceTaxonomy.marketplaceCategories.first;
  String _language = MarketplaceTaxonomy.supportedLanguages.first;
  bool _alwaysOpen = false;
  bool _notificationsEnabled = true;
  bool _detectingLocation = false;
  bool _submitting = false;

  final Map<String, Map<String, dynamic>> _openingHours = {
    'Mon': {'enabled': true, 'open': '09:00', 'close': '18:00'},
    'Tue': {'enabled': true, 'open': '09:00', 'close': '18:00'},
    'Wed': {'enabled': true, 'open': '09:00', 'close': '18:00'},
    'Thu': {'enabled': true, 'open': '09:00', 'close': '18:00'},
    'Fri': {'enabled': true, 'open': '09:00', 'close': '18:00'},
    'Sat': {'enabled': true, 'open': '09:00', 'close': '16:00'},
    'Sun': {'enabled': false, 'open': '00:00', 'close': '00:00'},
  };

  @override
  void dispose() {
    _businessNameController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickStorefrontImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 84,
    );
    if (picked != null) {
      setState(() => _storefrontImage = File(picked.path));
    }
  }

  Future<void> _pickAdditionalPhotos() async {
    final picked = await ImagePicker().pickMultiImage(imageQuality: 78);
    if (picked.isEmpty) {
      return;
    }

    setState(() {
      for (final item in picked) {
        if (_photos.length >= 20) {
          break;
        }
        _photos.add(File(item.path));
      }
    });
  }

  Future<void> _detectLocation() async {
    setState(() => _detectingLocation = true);
    try {
      final position = await LocationService().getCurrentLocation(
        context: context,
        onRetry: _detectLocation,
      );
      if (position == null) {
        return;
      }
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
    if (_storefrontImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Storefront photo is required.'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final authService = ref.read(authServiceProvider);
      final uid = authService.currentUser!.uid;
      final email = authService.currentUser!.email!;

      final storefrontUrl = await StorageService.uploadProfilePicture(
        uid,
        _storefrontImage!,
      );
      final photoUrls = <String>[storefrontUrl];

      for (var index = 0; index < _photos.length; index++) {
        final url = await StorageService.uploadMarketplacePhoto(
          uid,
          _photos[index],
          'marketplace_$index',
        );
        photoUrls.add(url);
      }

      final marketplace = MarketplaceModel(
        id: uid,
        email: email,
        name: _businessNameController.text.trim(),
        phone: _phoneController.text.trim(),
        photoUrl: storefrontUrl,
        location: _location,
        address:
            _addressController.text.trim().isEmpty
                ? null
                : _addressController.text.trim(),
        language: _language,
        createdAt: DateTime.now(),
        notificationsEnabled: _notificationsEnabled,
        businessName: _businessNameController.text.trim(),
        category: _category,
        description: _descriptionController.text.trim(),
        openingHours: _alwaysOpen ? {'alwaysOpen': true} : _openingHours,
        photos: photoUrls,
      );

      await authService.setupProfile(marketplace);
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
                  'Set up your marketplace profile',
                  style: AppTextStyles.headingLarge,
                ),
                const SizedBox(height: AppSpacing.s),
                Text(
                  'Add your storefront, hours, location, and gallery.',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xxl),
                GestureDetector(
                  onTap: _pickStorefrontImage,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: AppColors.softGray.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      image:
                          _storefrontImage == null
                              ? null
                              : DecorationImage(
                                image: FileImage(_storefrontImage!),
                                fit: BoxFit.cover,
                              ),
                    ),
                    child:
                        _storefrontImage == null
                            ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.storefront_outlined,
                                  size: 42,
                                  color: AppColors.accentBlue,
                                ),
                                const SizedBox(height: AppSpacing.s),
                                Text(
                                  'Add storefront photo',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.accentBlue,
                                  ),
                                ),
                              ],
                            )
                            : null,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                _label('BUSINESS NAME'),
                TextFormField(
                  controller: _businessNameController,
                  validator: _requiredValidator,
                  decoration: _inputDecoration(
                    'Your business name',
                    Icons.badge_outlined,
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
                _label('CATEGORY'),
                _categoryDropdown(),
                const SizedBox(height: AppSpacing.l),
                _label('DESCRIPTION'),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  maxLength: 500,
                  validator: _requiredValidator,
                  decoration: _inputDecoration(
                    'Describe your marketplace',
                    Icons.notes_outlined,
                  ),
                ),
                const SizedBox(height: AppSpacing.l),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: AppColors.availableGreen,
                  title: const Text('Always open'),
                  value: _alwaysOpen,
                  onChanged: (value) => setState(() => _alwaysOpen = value),
                ),
                if (!_alwaysOpen) ...[
                  const SizedBox(height: AppSpacing.s),
                  ..._openingHours.entries.map(
                    (entry) => SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(
                        '${entry.key} ${entry.value['open']} - ${entry.value['close']}',
                      ),
                      value: entry.value['enabled'] as bool,
                      onChanged: (value) {
                        setState(() => entry.value['enabled'] = value);
                      },
                    ),
                  ),
                ],
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
                    icon:
                        _detectingLocation
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
                  activeThumbColor: AppColors.accentBlue,
                  title: const Text('Enable push notifications'),
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() => _notificationsEnabled = value);
                  },
                ),
                const SizedBox(height: AppSpacing.l),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Marketplace photos',
                      style: AppTextStyles.headingSmall,
                    ),
                    TextButton.icon(
                      onPressed:
                          _photos.length >= 20 ? null : _pickAdditionalPhotos,
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      label: Text('Add (${_photos.length}/20)'),
                    ),
                  ],
                ),
                if (_photos.isNotEmpty)
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _photos.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                _photos[index],
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 6,
                            right: 6,
                            child: InkWell(
                              onTap:
                                  () => setState(() => _photos.removeAt(index)),
                              child: const CircleAvatar(
                                radius: 12,
                                backgroundColor: Colors.black54,
                                child: Icon(
                                  Icons.close,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
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
                    child:
                        _submitting
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

  Widget _categoryDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.softGray.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: _category,
          items:
              MarketplaceTaxonomy.marketplaceCategories
                  .map(
                    (category) => DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    ),
                  )
                  .toList(),
          onChanged: (value) => setState(() => _category = value!),
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
