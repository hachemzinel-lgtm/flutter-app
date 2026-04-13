import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/marketplace_taxonomy.dart';
import '../../../core/models/work_provider_model.dart';
import '../../../core/widgets/map_preview_widget.dart';
import '../../../services/document_verification_service.dart';
import '../../../services/storage_service.dart';
import 'package:flutter_application_1/core/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';

class ProviderProfileSetupScreen extends ConsumerStatefulWidget {
  const ProviderProfileSetupScreen({super.key});

  @override
  ConsumerState<ProviderProfileSetupScreen> createState() =>
      _ProviderProfileSetupScreenState();
}

class _ProviderProfileSetupScreenState
    extends ConsumerState<ProviderProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _yearsExperienceController = TextEditingController();
  final _addressController = TextEditingController();

  final List<ServicePrice> _services = [];
  final List<File> _portfolioPhotos = [];

  File? _profileImage;
  File? _professionalDocument;
  File? _identityDocument;
  GeoPoint? _location;
  String _profession = MarketplaceTaxonomy.workProviderCategories.first;
  String _language = MarketplaceTaxonomy.supportedLanguages.first;
  bool _notificationsEnabled = true;
  bool _availableNow = true;
  bool _customQuoteEnabled = false;
  bool _submitting = false;
  bool _detectingLocation = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _hourlyRateController.dispose();
    _yearsExperienceController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
    );
    if (picked != null) {
      setState(() => _profileImage = File(picked.path));
    }
  }

  Future<void> _pickPortfolioImages() async {
    final picked = await ImagePicker().pickMultiImage(imageQuality: 76);
    if (picked.isEmpty) {
      return;
    }

    setState(() {
      for (final item in picked) {
        if (_portfolioPhotos.length >= 10) {
          break;
        }
        _portfolioPhotos.add(File(item.path));
      }
    });
  }

  Future<void> _pickPdf({required bool professional}) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );

    final path = result?.files.single.path;
    if (path == null) {
      return;
    }

    setState(() {
      if (professional) {
        _professionalDocument = File(path);
      } else {
        _identityDocument = File(path);
      }
    });
  }

  Future<void> _detectLocation() async {
    setState(() => _detectingLocation = true);
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        throw Exception('Location services are disabled.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        throw Exception('Location permission is required to use GPS.');
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

  Future<void> _addFixedService() async {
    final nameController = TextEditingController();
    final priceController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add fixed service'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Service name'),
              ),
              TextField(
                controller: priceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Price'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final price = double.tryParse(priceController.text.trim());
                if (nameController.text.trim().isEmpty || price == null) {
                  return;
                }

                setState(() {
                  _services.add(
                    ServicePrice(
                      name: nameController.text.trim(),
                      price: price,
                    ),
                  );
                });
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    nameController.dispose();
    priceController.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_profileImage == null ||
        _professionalDocument == null ||
        _identityDocument == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Profile photo, professional certificate, and ID document are required.',
          ),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    if (mounted) {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _VerificationProgressDialog(),
      );
    }

    try {
      final authService = ref.read(authServiceProvider);
      final uid = authService.currentUser!.uid;
      final email = authService.currentUser!.email!;

      final profileUrl = await StorageService.uploadProfilePicture(
        uid,
        _profileImage!,
      );
      final diplomaUrl = await StorageService.uploadDocument(
        uid,
        _professionalDocument!,
        'diploma',
      );
      final idUrl = await StorageService.uploadDocument(
        uid,
        _identityDocument!,
        'id_card',
      );

      final portfolioUrls = <String>[];
      for (var index = 0; index < _portfolioPhotos.length; index++) {
        final photoUrl = await StorageService.uploadPortfolioPhoto(
          uid,
          _portfolioPhotos[index],
          'portfolio_$index',
        );
        portfolioUrls.add(photoUrl);
      }

      final verification =
          await DocumentVerificationService.verifyProviderDocuments(
            professionalDocument: _professionalDocument!,
            identityDocument: _identityDocument!,
          );

      final model = WorkProviderModel(
        id: uid,
        email: email,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        photoUrl: profileUrl,
        location: _location,
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        language: _language,
        createdAt: DateTime.now(),
        notificationsEnabled: _notificationsEnabled,
        profession: _profession,
        yearsExperience: int.tryParse(_yearsExperienceController.text.trim()),
        bio: _bioController.text.trim(),
        hourlyRate: double.tryParse(_hourlyRateController.text.trim()),
        services: _services,
        isAvailableNow: _availableNow,
        documents: {'diplomaURL': diplomaUrl, 'idURL': idUrl},
        verificationStatus: verification.status,
        verificationReason: verification.reason,
        customQuoteEnabled: _customQuoteEnabled,
        portfolio: portfolioUrls,
      );

      await authService.setupProfile(model);

      if (!mounted) {
        return;
      }
      Navigator.of(context, rootNavigator: true).pop();
      context.go(
        verification.status == VerificationStatus.approved.name
            ? '/home'
            : '/verification-pending',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      Navigator.of(context, rootNavigator: true).pop();
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
                  'Set up your work provider profile',
                  style: AppTextStyles.headingLarge,
                ),
                const SizedBox(height: AppSpacing.s),
                Text(
                  'Upload your professional documents, pricing, and service details.',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xxl),
                Center(
                  child: GestureDetector(
                    onTap: _pickProfileImage,
                    child: CircleAvatar(
                      radius: 54,
                      backgroundColor: AppColors.accentBlue.withValues(
                        alpha: 0.12,
                      ),
                      backgroundImage: _profileImage == null
                          ? null
                          : FileImage(_profileImage!),
                      child: _profileImage == null
                          ? const Icon(
                              Icons.person_outline,
                              size: 42,
                              color: AppColors.accentBlue,
                            )
                          : null,
                    ),
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
                _label('PROFESSION CATEGORY'),
                _dropdown<String>(
                  value: _profession,
                  items: MarketplaceTaxonomy.workProviderCategories,
                  onChanged: (value) => setState(() => _profession = value!),
                ),
                const SizedBox(height: AppSpacing.l),
                _label('YEARS OF EXPERIENCE'),
                TextFormField(
                  controller: _yearsExperienceController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration('e.g. 5', Icons.badge_outlined),
                ),
                const SizedBox(height: AppSpacing.l),
                _label('BIO / DESCRIPTION'),
                TextFormField(
                  controller: _bioController,
                  maxLines: 4,
                  maxLength: 500,
                  validator: _requiredValidator,
                  decoration: _inputDecoration(
                    'Tell clients about your expertise',
                    Icons.notes_outlined,
                  ),
                ),
                const SizedBox(height: AppSpacing.l),
                _label('HOURLY RATE'),
                TextFormField(
                  controller: _hourlyRateController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: _inputDecoration(
                    'Optional',
                    Icons.payments_outlined,
                  ),
                ),
                const SizedBox(height: AppSpacing.m),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: AppColors
                      .accentBlue, // SwitchListTile uses activeColor for the switch itself, but let's check
                  title: const Text('I prefer to quote per job'),
                  value: _customQuoteEnabled,
                  onChanged: (value) {
                    setState(() => _customQuoteEnabled = value);
                  },
                ),
                const SizedBox(height: AppSpacing.m),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Fixed service prices',
                      style: AppTextStyles.headingSmall,
                    ),
                    TextButton.icon(
                      onPressed: _addFixedService,
                      icon: const Icon(Icons.add),
                      label: const Text('Add service'),
                    ),
                  ],
                ),
                if (_services.isEmpty)
                  Text(
                    'No fixed services added yet.',
                    style: AppTextStyles.caption,
                  )
                else
                  ..._services.asMap().entries.map(
                    (entry) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(entry.value.name),
                      subtitle: Text(entry.value.price.toStringAsFixed(2)),
                      trailing: IconButton(
                        onPressed: () {
                          setState(() => _services.removeAt(entry.key));
                        },
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.xl),
                _label('PROFESSIONAL CERTIFICATE OR LICENSE (PDF)'),
                _uploadTile(
                  label: _professionalDocument == null
                      ? 'Upload professional diploma, certificate, or work license'
                      : _professionalDocument!.path
                            .split(Platform.pathSeparator)
                            .last,
                  icon: Icons.description_outlined,
                  selected: _professionalDocument != null,
                  onTap: () => _pickPdf(professional: true),
                ),
                const SizedBox(height: AppSpacing.l),
                _label('ID CARD OR PASSPORT (PDF)'),
                _uploadTile(
                  label: _identityDocument == null
                      ? 'Upload government-issued identity document'
                      : _identityDocument!.path
                            .split(Platform.pathSeparator)
                            .last,
                  icon: Icons.badge_outlined,
                  selected: _identityDocument != null,
                  onTap: () => _pickPdf(professional: false),
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
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _detectingLocation ? null : _detectLocation,
                        icon: _detectingLocation
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.my_location_outlined),
                        label: const Text('Use my current location'),
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
                ],
                const SizedBox(height: AppSpacing.l),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: AppColors.availableGreen,
                  title: const Text('Available now'),
                  value: _availableNow,
                  onChanged: (value) => setState(() => _availableNow = value),
                ),
                const SizedBox(height: AppSpacing.l),
                _label('PREFERRED LANGUAGE'),
                _dropdown<String>(
                  value: _language,
                  items: MarketplaceTaxonomy.supportedLanguages,
                  itemLabel: (value) {
                    switch (value) {
                      case 'fr':
                        return 'French';
                      case 'ar':
                        return 'Arabic';
                      default:
                        return 'English';
                    }
                  },
                  onChanged: (value) => setState(() => _language = value!),
                ),
                const SizedBox(height: AppSpacing.m),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: AppColors
                      .accentBlue, // SwitchListTile uses activeColor for the switch itself, but let's check
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
                    Text('Portfolio photos', style: AppTextStyles.headingSmall),
                    TextButton.icon(
                      onPressed: _portfolioPhotos.length >= 10
                          ? null
                          : _pickPortfolioImages,
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      label: Text('Add (${_portfolioPhotos.length}/10)'),
                    ),
                  ],
                ),
                if (_portfolioPhotos.isNotEmpty)
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _portfolioPhotos.length,
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
                                _portfolioPhotos[index],
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 6,
                            right: 6,
                            child: InkWell(
                              onTap: () {
                                setState(
                                  () => _portfolioPhotos.removeAt(index),
                                );
                              },
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
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
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

  Widget _dropdown<T>({
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    String Function(T item)? itemLabel,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.softGray.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isExpanded: true,
          value: value,
          items: items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(itemLabel?.call(item) ?? item.toString()),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _uploadTile({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.l),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.availableGreen.withValues(alpha: 0.08)
              : AppColors.softGray.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.availableGreen : AppColors.borderLight,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.check_circle_outline : icon,
              color: selected ? AppColors.availableGreen : AppColors.accentBlue,
            ),
            const SizedBox(width: AppSpacing.m),
            Expanded(child: Text(label)),
          ],
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

class _VerificationProgressDialog extends StatelessWidget {
  const _VerificationProgressDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: AppSpacing.l),
            Text('Verifying documents...', style: AppTextStyles.headingSmall),
            const SizedBox(height: AppSpacing.s),
            Text(
              'Please wait while we analyze your professional certificate and ID.',
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
