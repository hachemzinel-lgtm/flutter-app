import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/marketplace_taxonomy.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/widgets/map_preview_widget.dart';
import '../../../../services/location_lookup_service.dart';
import '../../../../services/notification_service.dart';
import '../../../../services/storage_service.dart';
import '../../providers/auth_providers.dart';

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
  final _otherCategoryController = TextEditingController();

  File? _storefrontImage;
  final List<File> _galleryImages = [];
  GeoPoint? _location;
  String _category = MarketplaceTaxonomy.marketplaceCategories.first;
  bool _alwaysOpen = false;
  bool _isDetectingLocation = false;
  bool _isSubmitting = false;

  final Map<String, TimeOfDayRange> _schedule = {
    'Monday': const TimeOfDayRange(
      open: TimeOfDay(hour: 9, minute: 0),
      close: TimeOfDay(hour: 18, minute: 0),
    ),
    'Tuesday': const TimeOfDayRange(
      open: TimeOfDay(hour: 9, minute: 0),
      close: TimeOfDay(hour: 18, minute: 0),
    ),
    'Wednesday': const TimeOfDayRange(
      open: TimeOfDay(hour: 9, minute: 0),
      close: TimeOfDay(hour: 18, minute: 0),
    ),
    'Thursday': const TimeOfDayRange(
      open: TimeOfDay(hour: 9, minute: 0),
      close: TimeOfDay(hour: 18, minute: 0),
    ),
    'Friday': const TimeOfDayRange(
      open: TimeOfDay(hour: 9, minute: 0),
      close: TimeOfDay(hour: 18, minute: 0),
    ),
    'Saturday': const TimeOfDayRange(
      open: TimeOfDay(hour: 10, minute: 0),
      close: TimeOfDay(hour: 16, minute: 0),
    ),
    'Sunday': const TimeOfDayRange(
      open: TimeOfDay(hour: 12, minute: 0),
      close: TimeOfDay(hour: 15, minute: 0),
    ),
  };

  @override
  void dispose() {
    _businessNameController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _otherCategoryController.dispose();
    super.dispose();
  }

  Future<void> _pickStorefrontImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
    );
    if (picked != null) {
      setState(() => _storefrontImage = File(picked.path));
    }
  }

  Future<void> _pickGalleryImages() async {
    final picked = await ImagePicker().pickMultiImage(imageQuality: 78);
    if (picked.isEmpty) {
      return;
    }

    setState(() {
      for (final item in picked) {
        if (_galleryImages.length >= 20) {
          break;
        }
        _galleryImages.add(File(item.path));
      }
    });
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

  Future<void> _pickTime(String day, bool isOpen) async {
    final initial = isOpen ? _schedule[day]!.open : _schedule[day]!.close;
    final time = await showTimePicker(context: context, initialTime: initial);
    if (time == null) {
      return;
    }
    setState(() {
      final current = _schedule[day]!;
      _schedule[day] = isOpen
          ? TimeOfDayRange(open: time, close: current.close)
          : TimeOfDayRange(open: current.open, close: time);
    });
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

    if (_location == null && _addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please provide your business address or current location.',
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

      final storefrontUrl = await StorageService.uploadProfilePicture(
        user.uid,
        _storefrontImage!,
      );

      final imageUrls = <String>[];
      for (var index = 0; index < _galleryImages.length; index++) {
        final url = await StorageService.uploadMarketplacePhoto(
          user.uid,
          _galleryImages[index],
          'gallery_$index',
        );
        imageUrls.add(url);
      }

      final category = _category == 'Other'
          ? _otherCategoryController.text.trim()
          : _category;

      await ref.read(userRepositoryProvider).updateUserDocument(user.uid, {
        'businessName': _businessNameController.text.trim(),
        'name': _businessNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'profilePicture': storefrontUrl,
        'category': category,
        'description': _descriptionController.text.trim(),
        'openingHours': _alwaysOpen
            ? {'alwaysOpen': true}
            : _schedule.map(
                (key, value) => MapEntry(key, {
                  'open': value.open.format(context),
                  'close': value.close.format(context),
                }),
              ),
        'photos': [storefrontUrl, ...imageUrls],
        'location': _location,
        'address': _addressController.text.trim(),
        'profileComplete': true,
        'profileCompleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await NotificationService.initialize();
      if (mounted) {
        context.go(AppRoutes.marketplaceHome);
      }
    } catch (error, stackTrace) {
      print('--- [MARKETPLACE SETUP] ERROR: $error');
      print('--- [MARKETPLACE SETUP] Stack trace: $stackTrace');
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
      appBar: AppBar(title: const Text('Marketplace Setup')),
      body: SingleChildScrollView(
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
                'Add your storefront, business details, opening hours, and photos.',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.l),
              GestureDetector(
                onTap: _isSubmitting ? null : _pickStorefrontImage,
                child: Container(
                  height: 190,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: AppColors.backgroundSecondary,
                    image: _storefrontImage == null
                        ? null
                        : DecorationImage(
                            image: FileImage(_storefrontImage!),
                            fit: BoxFit.cover,
                          ),
                  ),
                  child: _storefrontImage == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.storefront_outlined,
                              color: AppColors.accentBlue,
                              size: 36,
                            ),
                            const SizedBox(height: AppSpacing.s),
                            Text(
                              'Add Storefront Photo',
                              style: AppTextStyles.headingSmall,
                            ),
                          ],
                        )
                      : null,
                ),
              ),
              const SizedBox(height: AppSpacing.l),
              _label('Business Name'),
              TextFormField(
                controller: _businessNameController,
                decoration: _inputDecoration(
                  'Your business name',
                  Icons.badge_outlined,
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Business name is required'
                    : null,
              ),
              const SizedBox(height: AppSpacing.l),
              _label('Business Phone'),
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
              _label('Category'),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: _dropdownDecoration(),
                items: MarketplaceTaxonomy.marketplaceCategories
                    .map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      ),
                    )
                    .toList(),
                onChanged: _isSubmitting
                    ? null
                    : (value) => setState(() => _category = value ?? _category),
              ),
              if (_category == 'Other') ...[
                const SizedBox(height: AppSpacing.m),
                TextFormField(
                  controller: _otherCategoryController,
                  decoration: _inputDecoration(
                    'Specify category',
                    Icons.edit_outlined,
                  ),
                  validator: (value) {
                    if (_category == 'Other' &&
                        (value == null || value.trim().isEmpty)) {
                      return 'Please specify your business category';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: AppSpacing.l),
              _label('Description'),
              TextFormField(
                controller: _descriptionController,
                maxLength: 500,
                maxLines: 4,
                decoration: _inputDecoration(
                  'Describe your business',
                  Icons.notes_outlined,
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Description is required'
                    : null,
              ),
              const SizedBox(height: AppSpacing.s),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Open 24/7'),
                value: _alwaysOpen,
                activeThumbColor: AppColors.accentBlue,
                onChanged: _isSubmitting
                    ? null
                    : (value) => setState(() => _alwaysOpen = value),
              ),
              if (!_alwaysOpen)
                ..._schedule.entries.map(
                  (entry) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(entry.key),
                    subtitle: Text(
                      '${entry.value.open.format(context)} - ${entry.value.close.format(context)}',
                    ),
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        TextButton(
                          onPressed: _isSubmitting
                              ? null
                              : () => _pickTime(entry.key, true),
                          child: const Text('Open'),
                        ),
                        TextButton(
                          onPressed: _isSubmitting
                              ? null
                              : () => _pickTime(entry.key, false),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  ),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Business Photos', style: AppTextStyles.headingSmall),
                  TextButton.icon(
                    onPressed: _isSubmitting || _galleryImages.length >= 20
                        ? null
                        : _pickGalleryImages,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: Text('Add (${_galleryImages.length}/20)'),
                  ),
                ],
              ),
              if (_galleryImages.isNotEmpty)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _galleryImages.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.file(
                              _galleryImages[index],
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 4,
                          top: 4,
                          child: GestureDetector(
                            onTap: _isSubmitting
                                ? null
                                : () => setState(
                                    () => _galleryImages.removeAt(index),
                                  ),
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

class TimeOfDayRange {
  const TimeOfDayRange({required this.open, required this.close});

  final TimeOfDay open;
  final TimeOfDay close;
}
