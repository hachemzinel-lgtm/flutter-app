import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flutter_application_1/views/app_colors.dart';
import 'package:flutter_application_1/views/app_spacing.dart';
import 'package:flutter_application_1/views/app_text_styles.dart';
import 'package:flutter_application_1/models/marketplace_model.dart';
import 'package:flutter_application_1/providers/auth_providers.dart';
import 'package:flutter_application_1/providers/profile_provider.dart';
import 'package:flutter_application_1/services/location_service.dart';
import 'package:flutter_application_1/services/storage_service.dart';
import 'package:flutter_application_1/views/reviews_screen.dart';

class MarketplaceEditProfileScreen extends ConsumerStatefulWidget {
  const MarketplaceEditProfileScreen({super.key, required this.initialUser});

  final MarketplaceModel initialUser;

  @override
  ConsumerState<MarketplaceEditProfileScreen> createState() =>
      _MarketplaceEditProfileScreenState();
}

class _MarketplaceEditProfileScreenState
    extends ConsumerState<MarketplaceEditProfileScreen> {
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  bool _initialized = false;
  bool _saving = false;
  double? _uploadProgress;
  bool _alwaysOpen = false;
  String _language = 'en';
  GeoPoint? _location;
  File? _newProfileImage;
  final List<File> _newPhotos = [];

  @override
  void dispose() {
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _hydrate(EditProfileSeed seed) {
    if (_initialized) return;
    _initialized = true;
    _descriptionController.text = seed.description;
    _addressController.text = seed.address;
    _alwaysOpen = seed.alwaysOpen;
    _language = seed.language;
    _location = seed.user.location;
  }

  Future<void> _pickProfileImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
    );
    if (picked != null) {
      setState(() => _newProfileImage = File(picked.path));
    }
  }

  Future<void> _pickPhotos() async {
    final picked = await ImagePicker().pickMultiImage(imageQuality: 78);
    if (picked.isEmpty) return;
    setState(() {
      for (final item in picked) {
        if (_newPhotos.length >= 20) break;
        _newPhotos.add(File(item.path));
      }
    });
  }

  Future<void> _useCurrentLocation() async {
    try {
      final position = await LocationService().getCurrentLocation(
        context: context,
        onRetry: _useCurrentLocation,
      );
      if (position == null) {
        return;
      }
      setState(() {
        _location = GeoPoint(position.latitude, position.longitude);
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  Future<void> _save(MarketplaceModel user) async {
    setState(() => _saving = true);
    try {
      String? profileUrl = user.photoUrl;
      if (_newProfileImage != null) {
        profileUrl = await StorageService.uploadProfilePictureWithProgress(
          user.id,
          _newProfileImage!,
          onProgress: (progress) {
            if (mounted) {
              setState(() => _uploadProgress = progress);
            }
          },
        );
      }

      final photos = <String>[...user.photos];
      for (var index = 0; index < _newPhotos.length; index++) {
        final url = await StorageService.uploadMarketplacePhoto(
          user.id,
          _newPhotos[index],
          'edit_${DateTime.now().millisecondsSinceEpoch}_$index',
        );
        photos.add(url);
      }

      final updated = MarketplaceModel(
        id: user.id,
        email: user.email,
        name: user.name,
        phone: user.phone,
        photoUrl: profileUrl,
        createdAt: user.createdAt,
        location: _location,
        address:
            _addressController.text.trim().isEmpty
                ? null
                : _addressController.text.trim(),
        language: _language,
        rating: user.rating,
        reviewCount: user.reviewCount,
        isBanned: user.isBanned,
        notificationsEnabled: user.notificationsEnabled,
        businessName: user.businessName,
        category: user.category,
        description: _descriptionController.text.trim(),
        openingHours: _alwaysOpen ? {'alwaysOpen': true} : user.openingHours,
        photos: photos,
      );

      await ref.read(authServiceProvider).setupProfile(updated);
      ref.invalidate(currentUserDataProvider);
      ref.invalidate(currentUserDocProvider);
      ref.invalidate(currentProfileProvider);
      ref.invalidate(profileProvider(user.id));
      ref.invalidate(marketplaceProfileStatsProvider(user.id));
      ref.invalidate(profileReviewsProvider(user.id));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated.'),
          backgroundColor: AppColors.availableGreen,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: AppColors.errorRed,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
          _uploadProgress = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final seed = ref.watch(editProfileProvider(widget.initialUser));
    _hydrate(seed);
    final user = widget.initialUser;

    return Scaffold(
      appBar: AppBar(title: const Text('My Marketplace Profile')),
      body: ListView(
        padding: AppSpacing.pagePadding,
        children: [
          Center(
            child: GestureDetector(
              onTap: _pickProfileImage,
              child: CircleAvatar(
                radius: 48,
                backgroundColor: AppColors.accentBlue.withValues(alpha: 0.12),
                backgroundImage: _profileImageProvider(user),
                child:
                    (_newProfileImage == null && user.photoUrl == null)
                        ? Text(
                          (user.businessName ?? user.name)
                              .substring(0, 1)
                              .toUpperCase(),
                          style: AppTextStyles.headingSmall.copyWith(
                            color: AppColors.accentBlue,
                          ),
                        )
                        : null,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (_uploadProgress != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.m),
              child: LinearProgressIndicator(value: _uploadProgress),
            ),
          if (_uploadProgress != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s),
              child: Text(
                'Uploading photo... ${(_uploadProgress! * 100).round()}%',
                style: AppTextStyles.bodyMedium,
              ),
            ),
          TextField(
            controller: _descriptionController,
            maxLines: 5,
            maxLength: 500,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          const SizedBox(height: AppSpacing.m),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Always open'),
            value: _alwaysOpen,
            onChanged: (value) => setState(() => _alwaysOpen = value),
          ),
          const SizedBox(height: AppSpacing.m),
          TextField(
            controller: _addressController,
            decoration: const InputDecoration(labelText: 'Location'),
          ),
          const SizedBox(height: AppSpacing.s),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _useCurrentLocation,
              icon: const Icon(Icons.my_location_outlined),
              label: const Text('Use current location'),
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          DropdownButtonFormField<String>(
            initialValue: _language,
            decoration: const InputDecoration(labelText: 'Language'),
            items: const [
              DropdownMenuItem(value: 'en', child: Text('English')),
              DropdownMenuItem(value: 'fr', child: Text('French')),
              DropdownMenuItem(value: 'ar', child: Text('Arabic')),
            ],
            onChanged: (value) => setState(() => _language = value ?? 'en'),
          ),
          const SizedBox(height: AppSpacing.l),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Business photos', style: AppTextStyles.headingSmall),
              TextButton.icon(
                onPressed: _pickPhotos,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('Add photos'),
              ),
            ],
          ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ...user.photos.map(
                (image) => ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    image,
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              ..._newPhotos.map(
                (image) => ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(
                    image,
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          ElevatedButton(
            onPressed: _saving ? null : () => _save(user),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
            ),
            child:
                _saving
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                    : const Text('Save Changes'),
          ),
          const SizedBox(height: AppSpacing.m),
          OutlinedButton(
            onPressed:
                () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ReviewsScreen(providerId: user.id),
                  ),
                ),
            child: const Text('My Reviews'),
          ),
          const SizedBox(height: AppSpacing.s),
          OutlinedButton(
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
              if (!context.mounted) return;
              context.go('/login');
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  ImageProvider<Object>? _profileImageProvider(MarketplaceModel user) {
    if (_newProfileImage != null) {
      return FileImage(_newProfileImage!);
    }
    if (user.photoUrl != null) {
      return NetworkImage(user.photoUrl!);
    }
    return null;
  }
}
