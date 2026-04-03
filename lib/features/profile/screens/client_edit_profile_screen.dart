import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/models/client_model.dart';
import '../../../services/storage_service.dart';
import '../../auth/providers/auth_provider.dart';

class ClientEditProfileScreen extends ConsumerStatefulWidget {
  const ClientEditProfileScreen({super.key});

  @override
  ConsumerState<ClientEditProfileScreen> createState() =>
      _ClientEditProfileScreenState();
}

class _ClientEditProfileScreenState
    extends ConsumerState<ClientEditProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _initialized = false;
  bool _notificationsEnabled = true;
  bool _saving = false;
  String _language = 'en';
  GeoPoint? _location;
  File? _newImage;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _hydrate(ClientModel user) {
    if (_initialized) return;
    _initialized = true;
    _nameController.text = user.name;
    _phoneController.text = user.phone;
    _addressController.text = user.address ?? '';
    _language = user.language ?? 'en';
    _notificationsEnabled = user.notificationsEnabled;
    _location = user.location;
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
    );
    if (picked != null) {
      setState(() => _newImage = File(picked.path));
    }
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

  Future<void> _save(ClientModel user) async {
    setState(() => _saving = true);
    try {
      final uid = user.id;
      String? photoUrl = user.photoUrl;
      if (_newImage != null) {
        photoUrl = await StorageService.uploadProfilePicture(uid, _newImage!);
      }

      final updated = ClientModel(
        id: uid,
        email: user.email,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        photoUrl: photoUrl,
        location: _location,
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        language: _language,
        createdAt: user.createdAt,
        notificationsEnabled: _notificationsEnabled,
        rating: user.rating,
        reviewCount: user.reviewCount,
        isBanned: user.isBanned,
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
    if (user is! ClientModel) {
      return const Center(child: CircularProgressIndicator());
    }
    _hydrate(user);

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: ListView(
        padding: AppSpacing.pagePadding,
        children: [
          Center(
            child: GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 46,
                backgroundColor: AppColors.accentBlue.withValues(alpha: 0.12),
                backgroundImage: _profileImageProvider(user),
                child: (_newImage == null && user.photoUrl == null)
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
          _field('Name', _nameController),
          const SizedBox(height: AppSpacing.m),
          _field(
            'Phone number',
            _phoneController,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: AppSpacing.m),
          InputDecorator(
            decoration: const InputDecoration(labelText: 'Email'),
            child: Text(
              user.email,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primaryNavy,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          _field('Saved location', _addressController),
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
          const SizedBox(height: AppSpacing.m),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Enable push notifications'),
            value: _notificationsEnabled,
            onChanged: (value) => setState(() => _notificationsEnabled = value),
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

  Widget _field(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label),
    );
  }

  ImageProvider<Object>? _profileImageProvider(ClientModel user) {
    if (_newImage != null) {
      return FileImage(_newImage!);
    }
    if (user.photoUrl != null) {
      return NetworkImage(user.photoUrl!);
    }
    return null;
  }
}
