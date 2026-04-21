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
import 'package:flutter_application_1/models/work_provider_model.dart';
import 'package:flutter_application_1/routes/route_paths.dart';
import 'package:flutter_application_1/services/storage_service.dart';
import 'package:flutter_application_1/providers/auth_provider.dart';
import 'package:flutter_application_1/views/reviews_screen.dart';

class ProviderEditProfileScreen extends ConsumerStatefulWidget {
  const ProviderEditProfileScreen({super.key});

  @override
  ConsumerState<ProviderEditProfileScreen> createState() =>
      _ProviderEditProfileScreenState();
}

class _ProviderEditProfileScreenState
    extends ConsumerState<ProviderEditProfileScreen> {
  final _bioController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _addressController = TextEditingController();
  bool _initialized = false;
  bool _saving = false;
  bool _availableNow = false;
  bool _customQuoteEnabled = false;
  String _language = 'en';
  GeoPoint? _location;
  File? _newProfileImage;
  final List<File> _newPortfolio = [];

  @override
  void dispose() {
    _bioController.dispose();
    _hourlyRateController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _hydrate(WorkProviderModel user) {
    if (_initialized) return;
    _initialized = true;
    _bioController.text = user.bio ?? '';
    _hourlyRateController.text = user.hourlyRate?.toString() ?? '';
    _addressController.text = user.address ?? '';
    _availableNow = user.isAvailableNow;
    _customQuoteEnabled = user.customQuoteEnabled;
    _language = user.language ?? 'en';
    _location = user.location;
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

  Future<void> _pickPortfolioImages() async {
    final picked = await ImagePicker().pickMultiImage(imageQuality: 78);
    if (picked.isEmpty) return;
    setState(() {
      for (final item in picked) {
        if (_newPortfolio.length >= 10) break;
        _newPortfolio.add(File(item.path));
      }
    });
  }

  Future<void> _useCurrentLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission is required.');
      }
      final position = await Geolocator.getCurrentPosition();
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

  Future<void> _save(WorkProviderModel user) async {
    setState(() => _saving = true);
    try {
      String? photoUrl = user.photoUrl;
      if (_newProfileImage != null) {
        photoUrl = await StorageService.uploadProfilePicture(
          user.id,
          _newProfileImage!,
        );
      }

      final portfolio = <String>[...user.portfolio];
      for (var index = 0; index < _newPortfolio.length; index++) {
        final url = await StorageService.uploadPortfolioPhoto(
          user.id,
          _newPortfolio[index],
          'edit_${DateTime.now().millisecondsSinceEpoch}_$index',
        );
        portfolio.add(url);
      }

      final updated = WorkProviderModel(
        id: user.id,
        email: user.email,
        name: user.name,
        phone: user.phone,
        photoUrl: photoUrl,
        createdAt: user.createdAt,
        location: _location,
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        language: _language,
        rating: user.rating,
        reviewCount: user.reviewCount,
        isBanned: user.isBanned,
        notificationsEnabled: user.notificationsEnabled,
        profession: user.profession,
        yearsExperience: user.yearsExperience,
        bio: _bioController.text.trim(),
        hourlyRate: double.tryParse(_hourlyRateController.text.trim()),
        services: user.services,
        isAvailableNow: _availableNow,
        documents: user.documents,
        verificationStatus: user.verificationStatus,
        verificationReason: user.verificationReason,
        customQuoteEnabled: _customQuoteEnabled,
        portfolio: portfolio,
      );

      await ref.read(authServiceProvider).setupProfile(updated);
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
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserDocProvider).value;
    if (user is! WorkProviderModel) {
      return const Center(child: CircularProgressIndicator());
    }
    _hydrate(user);

    return Scaffold(
      appBar: AppBar(title: const Text('My Provider Profile')),
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
                child: (_newProfileImage == null && user.photoUrl == null)
                    ? Text(
                        user.name.substring(0, 1).toUpperCase(),
                        style: AppTextStyles.headingSmall.copyWith(
                          color: AppColors.accentBlue,
                        ),
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          TextField(
            controller: _bioController,
            maxLines: 5,
            maxLength: 500,
            decoration: const InputDecoration(labelText: 'Bio'),
          ),
          const SizedBox(height: AppSpacing.m),
          TextField(
            controller: _hourlyRateController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Hourly rate'),
          ),
          const SizedBox(height: AppSpacing.m),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Available now'),
            value: _availableNow,
            onChanged: (value) => setState(() => _availableNow = value),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Custom quote available'),
            value: _customQuoteEnabled,
            onChanged: (value) => setState(() => _customQuoteEnabled = value),
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
            value: _language,
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
              Text('Portfolio', style: AppTextStyles.headingSmall),
              TextButton.icon(
                onPressed: _pickPortfolioImages,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('Add photos'),
              ),
            ],
          ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ...user.portfolio.map(
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
              ..._newPortfolio.map(
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
            child: _saving
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
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ReviewsScreen(providerId: user.id),
              ),
            ),
            child: const Text('My Reviews'),
          ),
          if (user.verificationStatus == 'rejected') ...[
            const SizedBox(height: AppSpacing.s),
            OutlinedButton(
              onPressed: () => context.push(AppRoutes.setupProvider),
              child: const Text('Re-upload Documents'),
            ),
          ],
          const SizedBox(height: AppSpacing.s),
          OutlinedButton(
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
              if (!context.mounted) return;
              context.go(AppRoutes.login);
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  ImageProvider<Object>? _profileImageProvider(WorkProviderModel user) {
    if (_newProfileImage != null) {
      return FileImage(_newProfileImage!);
    }
    if (user.photoUrl != null) {
      return NetworkImage(user.photoUrl!);
    }
    return null;
  }
}
