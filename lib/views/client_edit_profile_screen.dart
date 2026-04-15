import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:intl/intl.dart';

import 'package:flutter_application_1/views/app_colors.dart';
import 'package:flutter_application_1/views/app_spacing.dart';
import 'package:flutter_application_1/views/app_text_styles.dart';
import 'package:flutter_application_1/models/client_model.dart';
import 'package:flutter_application_1/providers/auth_providers.dart';
import 'package:flutter_application_1/providers/profile_provider.dart';
import 'package:flutter_application_1/services/location_service.dart';
import 'package:flutter_application_1/services/storage_service.dart';

class ClientEditProfileScreen extends ConsumerStatefulWidget {
  const ClientEditProfileScreen({super.key, required this.initialUser});

  final ClientModel initialUser;

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
  double? _uploadProgress;
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

  void _hydrate(EditProfileSeed seed) {
    if (_initialized) return;
    _initialized = true;
    _nameController.text = seed.name;
    _phoneController.text = seed.phone;
    _addressController.text = seed.address;
    _language = seed.language;
    _notificationsEnabled = seed.notificationsEnabled;
    _location = seed.user.location;
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

  Future<void> _save(ClientModel user) async {
    setState(() => _saving = true);
    try {
      final uid = user.id;
      String? photoUrl = user.photoUrl;
      if (_newImage != null) {
        photoUrl = await StorageService.uploadProfilePictureWithProgress(
          uid,
          _newImage!,
          onProgress: (progress) {
            if (mounted) {
              setState(() => _uploadProgress = progress);
            }
          },
        );
      }

      final updated = ClientModel(
        id: uid,
        email: user.email,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        photoUrl: photoUrl,
        location: _location,
        address:
            _addressController.text.trim().isEmpty
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
      ref.invalidate(currentUserDataProvider);
      ref.invalidate(currentUserDocProvider);
      ref.invalidate(currentProfileProvider);
      ref.invalidate(profileProvider(user.id));
      ref.invalidate(clientProfileStatsProvider(user.id));
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
                child:
                    (_newImage == null && user.photoUrl == null)
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
          const SizedBox(height: AppSpacing.m),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 20),
              const SizedBox(width: 4),
              Text(
                '${(user.rating ?? 0.0).toStringAsFixed(1)} ',
                style: AppTextStyles.headingSmall,
              ),
              Text(
                '(${user.reviewCount ?? 0} reviews)',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.softGray,
                ),
              ),
            ],
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
            alignment: AlignmentDirectional.centerStart,
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
          Text('Reviews Received', style: AppTextStyles.headingSmall),
          const SizedBox(height: AppSpacing.m),
          StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.id)
                    .collection('reviews')
                    .orderBy('timestamp', descending: true)
                    .limit(5)
                    .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Text('No reviews received yet.');
              }
              return Column(
                children:
                    snapshot.data!.docs.map((doc) {
                      final rev = doc.data() as Map<String, dynamic>;
                      final date =
                          rev['timestamp'] != null
                              ? DateFormat.yMMMd().format(
                                (rev['timestamp'] as Timestamp).toDate(),
                              )
                              : '';
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundImage:
                              rev['fromPhotoUrl'] != null &&
                                      rev['fromPhotoUrl'].toString().isNotEmpty
                                  ? NetworkImage(rev['fromPhotoUrl'])
                                  : null,
                          child:
                              rev['fromPhotoUrl'] == null ||
                                      rev['fromPhotoUrl'].toString().isEmpty
                                  ? const Icon(Icons.person)
                                  : null,
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(rev['fromName'] ?? 'Anonymous'),
                            ),
                            Row(
                              children: List.generate(
                                5,
                                (i) => Icon(
                                  Icons.star,
                                  size: 14,
                                  color:
                                      i < (rev['rating'] ?? 0)
                                          ? Colors.amber
                                          : Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(date, style: const TextStyle(fontSize: 12)),
                            if (rev['comment'] != null &&
                                rev['comment'].toString().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(rev['comment']),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
              );
            },
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
