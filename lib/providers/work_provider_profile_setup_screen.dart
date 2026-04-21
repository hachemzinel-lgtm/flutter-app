import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flutter_application_1/views/app_colors.dart';
import 'package:flutter_application_1/views/app_spacing.dart';
import 'package:flutter_application_1/views/app_text_styles.dart';
import 'package:flutter_application_1/views/marketplace_taxonomy.dart';
import 'package:flutter_application_1/routes/route_paths.dart';
import 'package:flutter_application_1/views/map_preview_widget.dart';
import 'package:flutter_application_1/services/document_verification_service.dart';
import 'package:flutter_application_1/services/location_lookup_service.dart';
import 'package:flutter_application_1/services/services_notification_service.dart';
import 'package:flutter_application_1/services/storage_service.dart';
import 'package:flutter_application_1/providers/auth_providers.dart';

class WorkProviderProfileSetupScreen extends ConsumerStatefulWidget {
  const WorkProviderProfileSetupScreen({super.key});

  @override
  ConsumerState<WorkProviderProfileSetupScreen> createState() =>
      _WorkProviderProfileSetupScreenState();
}

class _WorkProviderProfileSetupScreenState
    extends ConsumerState<WorkProviderProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _yearsController = TextEditingController();
  final _bioController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _addressController = TextEditingController();
  final _otherProfessionController = TextEditingController();

  final List<Map<String, String>> _services = [];
  final List<File> _portfolioImages = [];

  File? _profileImage;
  File? _diplomaFile;
  File? _idFile;
  GeoPoint? _location;
  String _profession = MarketplaceTaxonomy.workProviderCategories.first;
  bool _customQuote = false;
  bool _availableNow = false;
  bool _isDetectingLocation = false;
  bool _isSubmitting = false;
  String _progressMessage = '';

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _yearsController.dispose();
    _bioController.dispose();
    _hourlyRateController.dispose();
    _addressController.dispose();
    _otherProfessionController.dispose();
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
    final picked = await ImagePicker().pickMultiImage(imageQuality: 78);
    if (picked.isEmpty) {
      return;
    }
    setState(() {
      for (final image in picked) {
        if (_portfolioImages.length >= 10) {
          break;
        }
        _portfolioImages.add(File(image.path));
      }
    });
  }

  Future<void> _pickPdf({required bool diploma}) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );

    final path = result?.files.single.path;
    final size = result?.files.single.size ?? 0;
    if (path == null) {
      return;
    }
    if (size > 10 * 1024 * 1024) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF files must be 10MB or less.'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    setState(() {
      if (diploma) {
        _diplomaFile = File(path);
      } else {
        _idFile = File(path);
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

  Future<void> _addService() async {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Fixed Service'),
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
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final price = priceController.text.trim();
                if (name.isEmpty || double.tryParse(price) == null) {
                  return;
                }
                setState(() {
                  _services.add({'name': name, 'price': price});
                });
                Navigator.of(context).pop();
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

    if (_profileImage == null) {
      _showError('Profile picture is required.');
      return;
    }
    if (_diplomaFile == null || _idFile == null) {
      _showError(
        'Please upload both your diploma/certificate and your ID card.',
      );
      return;
    }
    if (_location == null && _addressController.text.trim().isEmpty) {
      _showError('Please provide your work address or current location.');
      return;
    }
    if (!_customQuote &&
        _services.isEmpty &&
        double.tryParse(_hourlyRateController.text.trim()) == null) {
      _showError(
        'Add an hourly rate, a fixed service, or enable custom quote.',
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _progressMessage = 'Uploading to secure storage...';
    });

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: AppSpacing.m),
              Expanded(child: Text(_progressMessage)),
            ],
          ),
        ),
      ),
    );

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) {
        throw Exception('You must be signed in to complete profile setup.');
      }

      final profileUrl = await StorageService.uploadProfilePicture(
        user.uid,
        _profileImage!,
      );
      final diplomaUrl = await StorageService.uploadDocument(
        user.uid,
        _diplomaFile!,
        'diploma',
      );
      final idUrl = await StorageService.uploadDocument(
        user.uid,
        _idFile!,
        'id_card',
      );

      setState(
        () => _progressMessage =
            'Verifying your documents... This may take a minute',
      );

      final verification =
          await DocumentVerificationService.verifyProviderDocuments(
            professionalDocument: _diplomaFile!,
            identityDocument: _idFile!,
          );

      if (verification.status != 'approved') {
        await ref.read(userRepositoryProvider).updateUserDocument(user.uid, {
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'profession': _profession == 'Other'
              ? _otherProfessionController.text.trim()
              : _profession,
          'profilePicture': profileUrl,
          'documents': {'diplomaURL': diplomaUrl, 'idURL': idUrl},
          'verificationStatus': 'rejected',
          'verificationReason': verification.reason,
          'isVerified': false,
          'profileComplete': false,
          'profileCompleted': false,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
          await showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Documents Rejected'),
              content: Text(verification.reason),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Re-upload'),
                ),
              ],
            ),
          );
        }
        return;
      }

      setState(() => _progressMessage = 'Finalizing your profile...');

      final portfolioUrls = <String>[];
      for (var index = 0; index < _portfolioImages.length; index++) {
        final url = await StorageService.uploadPortfolioPhoto(
          user.uid,
          _portfolioImages[index],
          'portfolio_$index',
        );
        portfolioUrls.add(url);
      }

      await ref.read(userRepositoryProvider).updateUserDocument(user.uid, {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'profilePicture': profileUrl,
        'profession': _profession == 'Other'
            ? _otherProfessionController.text.trim()
            : _profession,
        'yearsExperience': int.tryParse(_yearsController.text.trim()),
        'bio': _bioController.text.trim(),
        'hourlyRate': double.tryParse(_hourlyRateController.text.trim()),
        'services': _services
            .map(
              (service) => {
                'name': service['name'],
                'price': double.tryParse(service['price'] ?? '') ?? 0,
              },
            )
            .toList(),
        'customQuoteEnabled': _customQuote,
        'documents': {'diplomaURL': diplomaUrl, 'idURL': idUrl},
        'verificationStatus': 'approved',
        'verificationReason': verification.reason,
        'isVerified': true,
        'location': _location,
        'address': _addressController.text.trim(),
        'isAvailableNow': _availableNow,
        'portfolio': portfolioUrls,
        'profileComplete': true,
        'profileCompleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await NotificationService.initialize();
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        context.go(AppRoutes.providerHome);
      }
    } catch (error, stackTrace) {
      print('--- [PROVIDER SETUP] ERROR: $error');
      print('--- [PROVIDER SETUP] Stack trace: $stackTrace');
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        _showError(error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Work Provider Setup')),
      body: SingleChildScrollView(
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
                'Upload your documents, services, and work details.',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.l),
              Center(
                child: GestureDetector(
                  onTap: _isSubmitting ? null : _pickProfileImage,
                  child: CircleAvatar(
                    radius: 54,
                    backgroundColor: AppColors.backgroundSecondary,
                    backgroundImage: _profileImage == null
                        ? null
                        : FileImage(_profileImage!),
                    child: _profileImage == null
                        ? const Icon(
                            Icons.camera_alt_outlined,
                            color: AppColors.accentBlue,
                          )
                        : null,
                  ),
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
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Full name is required'
                    : null,
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
              _label('Profession Category'),
              DropdownButtonFormField<String>(
                value: _profession,
                decoration: _dropdownDecoration(),
                items: MarketplaceTaxonomy.workProviderCategories
                    .map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      ),
                    )
                    .toList(),
                onChanged: _isSubmitting
                    ? null
                    : (value) =>
                          setState(() => _profession = value ?? _profession),
              ),
              if (_profession == 'Other') ...[
                const SizedBox(height: AppSpacing.m),
                TextFormField(
                  controller: _otherProfessionController,
                  decoration: _inputDecoration(
                    'Specify profession',
                    Icons.edit_outlined,
                  ),
                  validator: (value) {
                    if (_profession == 'Other' &&
                        (value == null || value.trim().isEmpty)) {
                      return 'Please specify your profession';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: AppSpacing.l),
              _label('Years of Experience'),
              TextFormField(
                controller: _yearsController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration('0-50', Icons.badge_outlined),
              ),
              const SizedBox(height: AppSpacing.l),
              _label('Bio / Description'),
              TextFormField(
                controller: _bioController,
                maxLength: 500,
                maxLines: 4,
                decoration: _inputDecoration(
                  'Describe your experience',
                  Icons.notes_outlined,
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Bio is required'
                    : null,
              ),
              const SizedBox(height: AppSpacing.l),
              _label('Hourly Rate'),
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
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('I prefer to quote per job'),
                value: _customQuote,
                activeTrackColor: AppColors.accentBlue,
                onChanged: _isSubmitting
                    ? null
                    : (value) => setState(() => _customQuote = value),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Fixed Services', style: AppTextStyles.headingSmall),
                  TextButton.icon(
                    onPressed: _isSubmitting ? null : _addService,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Service'),
                  ),
                ],
              ),
              if (_services.isEmpty)
                Text(
                  'No fixed services added yet.',
                  style: AppTextStyles.bodyMedium,
                )
              else
                ..._services.asMap().entries.map(
                  (entry) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(entry.value['name'] ?? ''),
                    subtitle: Text(entry.value['price'] ?? ''),
                    trailing: IconButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => setState(() => _services.removeAt(entry.key)),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.l),
              _label('Professional Certificate or Diploma (PDF)'),
              _uploadTile(
                file: _diplomaFile,
                title: 'Upload PDF (max 10MB)',
                onTap: () => _pickPdf(diploma: true),
              ),
              const SizedBox(height: AppSpacing.m),
              _label('ID Card (PDF)'),
              _uploadTile(
                file: _idFile,
                title: 'Upload government-issued ID (max 10MB)',
                onTap: () => _pickPdf(diploma: false),
              ),
              const SizedBox(height: AppSpacing.s),
              Text(
                'Uploading to secure storage and verifying your documents happens automatically when you continue.',
                style: AppTextStyles.bodyMedium,
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
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Available Now'),
                value: _availableNow,
                activeTrackColor: AppColors.accentBlue,
                onChanged: _isSubmitting
                    ? null
                    : (value) => setState(() => _availableNow = value),
              ),
              const SizedBox(height: AppSpacing.l),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Portfolio Photos', style: AppTextStyles.headingSmall),
                  TextButton.icon(
                    onPressed: _isSubmitting || _portfolioImages.length >= 10
                        ? null
                        : _pickPortfolioImages,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: Text('Add (${_portfolioImages.length}/10)'),
                  ),
                ],
              ),
              if (_portfolioImages.isNotEmpty)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _portfolioImages.length,
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
                              _portfolioImages[index],
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: _isSubmitting
                                ? null
                                : () => setState(
                                    () => _portfolioImages.removeAt(index),
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

  Widget _uploadTile({
    required File? file,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _isSubmitting ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.l),
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: file == null ? AppColors.borderLight : AppColors.accentBlue,
          ),
        ),
        child: Row(
          children: [
            Icon(
              file == null ? Icons.upload_file_outlined : Icons.check_circle,
              color: file == null
                  ? AppColors.accentBlue
                  : AppColors.availableGreen,
            ),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Text(
                file == null
                    ? title
                    : file.path.split(Platform.pathSeparator).last,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.errorRed),
    );
  }
}
