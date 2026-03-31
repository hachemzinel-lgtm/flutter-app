import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/models/work_provider_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../services/storage_service.dart';
import '../../../services/document_verification_service.dart';
import '../../../core/widgets/map_preview_widget.dart';
import 'package:file_picker/file_picker.dart';

const _professions = [
  'Plumber (Plombier)',
  'Electrician (Élictrien)',
  'Cleaner (Nettoyeur)',
  'Carpenter (Menuisier)',
  'Painter (Peintre)',
  'Gardener (Jardinier)',
  'Mechanic (Mécanicien)',
  'Tutor (Tuteur)',
  'Photographer (Photographe)',
  'Other (specify)',
];

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
  final _yearsExpController = TextEditingController();

  File? _profileImage;
  File? _diplomaFile;
  File? _idFile;
  GeoPoint? _location;

  String _selectedProfession = _professions.first;
  String _selectedLanguage = 'en';
  bool _isAvailableNow = true;
  bool _prefersCustomQuote = false;
  bool _isLoading = false;
  bool _isLoadingLocation = false;
  bool _notificationsEnabled = true;
  int _currentStep = 0;

  final List<Map<String, dynamic>> _services = [];
  final List<File> _portfolioPhotos = [];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _hourlyRateController.dispose();
    _yearsExpController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() => _profileImage = File(picked.path));
  }

  Future<void> _pickDocument(bool isDiploma) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        if (isDiploma) {
          _diplomaFile = File(result.files.single.path!);
        } else {
          _idFile = File(result.files.single.path!);
        }
      });
    }
  }

  Future<void> _pickPortfolioPhotos() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 70);
    if (picked.isNotEmpty) {
      setState(() {
        for (var f in picked) {
          if (_portfolioPhotos.length < 10) {
            _portfolioPhotos.add(File(f.path));
          }
        }
      });
    }
  }

  Future<void> _detectLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition();
      setState(() => _location = GeoPoint(pos.latitude, pos.longitude));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location detected!'), backgroundColor: AppColors.availableGreen),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  void _addService() {
    showDialog(
      context: context,
      builder: (_) {
        final nameCtrl = TextEditingController();
        final priceCtrl = TextEditingController();
        return AlertDialog(
          title: const Text('Add Service'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Service Name')),
              TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price (DZD)')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.isNotEmpty && priceCtrl.text.isNotEmpty) {
                  setState(() => _services.add({'name': nameCtrl.text, 'price': double.tryParse(priceCtrl.text) ?? 0}));
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_profileImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture is required'), backgroundColor: AppColors.errorRed),
      );
      return;
    }
    if (_diplomaFile == null || _idFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Both documents are required'), backgroundColor: AppColors.errorRed),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final authService = ref.read(authServiceProvider);
      final uid = authService.currentUser!.uid;
      final email = authService.currentUser!.email!;

      // Show verification progress dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const _VerificationProgressDialog(),
        );
      }

      // Upload files
      String? photoUrl;
      if (_profileImage != null) {
        photoUrl = await StorageService.uploadProfilePicture(uid, _profileImage!);
      }

      String? diplomaUrl;
      if (_diplomaFile != null) {
        diplomaUrl = await StorageService.uploadDocument(uid, _diplomaFile!, 'diploma');
      }

      String? idUrl = _idFile != null 
          ? await StorageService.uploadDocument(uid, _idFile!, 'id_card')
          : null;

      // AI Verification (only if diploma added)
      String verificationStatus = 'pending';
      String? verificationReason;
      
      if (_diplomaFile != null) {
        final diplomaResult = await DocumentVerificationService.verifyDocument(_diplomaFile!);
        verificationStatus = diplomaResult.isValid ? 'approved' : 'rejected';
        verificationReason = diplomaResult.reason;
      }

      if (mounted) Navigator.of(context, rootNavigator: true).pop(); // close dialog

      final provider = WorkProviderModel(
        id: uid,
        email: email,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        photoUrl: photoUrl,
        location: _location,
        language: _selectedLanguage,
        createdAt: DateTime.now(),
        profession: _selectedProfession,
        yearsExperience: int.tryParse(_yearsExpController.text),
        bio: _bioController.text.trim(),
        hourlyRate: double.tryParse(_hourlyRateController.text),
        services: _services
            .map((s) => ServicePrice(name: s['name'], price: (s['price'] as num).toDouble()))
            .toList(),
        isAvailableNow: _isAvailableNow,
        documents: {
          if (diplomaUrl != null) 'diplomaURL': diplomaUrl,
          if (idUrl != null) 'idURL': idUrl,
        },
        verificationStatus: verificationStatus,
        verificationReason: verificationReason,
      );

      await authService.setupProfile(provider);

      if (mounted) {
        if (verificationStatus == 'approved') {
          context.go('/home');
        } else {
          context.go('/verification-pending');
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Stepper header
            _buildStepperHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: AppSpacing.pagePadding,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_currentStep == 0) _buildStep1(),
                      if (_currentStep == 1) _buildStep2(),
                      if (_currentStep == 2) _buildStep3(),
                      const SizedBox(height: AppSpacing.xxl),
                      _buildNavButtons(),
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepperHeader() {
    final steps = ['Personal', 'Professional', 'Documents'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.m),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Row(
            children: List.generate(steps.length, (i) {
              final isActive = i == _currentStep;
              final isDone = i < _currentStep;
              return Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDone
                            ? AppColors.availableGreen
                            : isActive
                                ? AppColors.accentBlue
                                : AppColors.softGray.withOpacity(0.2),
                      ),
                      child: Center(
                        child: isDone
                            ? const Icon(Icons.check, color: Colors.white, size: 14)
                            : Text('${i + 1}',
                                style: TextStyle(
                                  color: isActive ? Colors.white : AppColors.softGray,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                )),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        steps[i],
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: isActive ? FontWeight.w700 : FontWeight.normal,
                          color: isActive ? AppColors.accentBlue : AppColors.softGray,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (i < steps.length - 1)
                      Expanded(
                        child: Container(
                          height: 1,
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          color: isDone ? AppColors.availableGreen : AppColors.softGray.withOpacity(0.2),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.l),
        Text('Personal Information', style: AppTextStyles.headingLarge.copyWith(fontSize: 24)),
        const SizedBox(height: AppSpacing.s),
        Text('Work Provider Account', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.accentBlue, fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.xxl),

        // Profile photo (required)
        Center(
          child: GestureDetector(
            onTap: _pickImage,
            child: Stack(
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accentBlue.withOpacity(0.08),
                    border: Border.all(
                      color: _profileImage != null ? AppColors.accentBlue : AppColors.errorRed.withOpacity(0.3),
                      width: 2,
                    ),
                    image: _profileImage != null
                        ? DecorationImage(image: FileImage(_profileImage!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: _profileImage == null
                      ? const Icon(Icons.person_outline, size: 44, color: AppColors.accentBlue)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: const BoxDecoration(color: AppColors.accentBlue, shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Center(child: Text('Profile photo (required)', style: AppTextStyles.caption.copyWith(color: AppColors.errorRed.withOpacity(0.8)))),
        const SizedBox(height: AppSpacing.xl),

        _buildLabel('FULL NAME *'),
        TextFormField(
          controller: _nameController,
          decoration: _inputDecoration('Your full name', Icons.person_outline),
          validator: (v) => v == null || v.isEmpty ? 'Name is required' : null,
        ),
        const SizedBox(height: AppSpacing.l),

        _buildLabel('PHONE NUMBER *'),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: _inputDecoration('+213 --- --- ---', Icons.phone_outlined),
          validator: (v) => v == null || v.isEmpty ? 'Phone is required' : null,
        ),
        const SizedBox(height: AppSpacing.l),

        _buildLabel('PREFERRED LANGUAGE'),
        _buildLanguageDropdown(),
        const SizedBox(height: AppSpacing.l),

        // Notifications
        Container(
          decoration: BoxDecoration(
            color: AppColors.softGray.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: SwitchListTile(
            title: Text('Enable Push Notifications', style: AppTextStyles.bodyMedium),
            value: _notificationsEnabled,
            onChanged: (v) => setState(() => _notificationsEnabled = v),
            activeColor: AppColors.accentBlue,
          ),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.l),
        Text('Professional Info', style: AppTextStyles.headingLarge.copyWith(fontSize: 24)),
        const SizedBox(height: AppSpacing.s),
        Text('Tell clients about your expertise', style: AppTextStyles.bodyMedium),
        const SizedBox(height: AppSpacing.xxl),

        _buildLabel('PROFESSION *'),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.softGray.withOpacity(0.05),
            borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _selectedProfession,
              items: _professions.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
              onChanged: (v) => setState(() => _selectedProfession = v!),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.l),

        _buildLabel('YEARS OF EXPERIENCE'),
        TextFormField(
          controller: _yearsExpController,
          keyboardType: TextInputType.number,
          decoration: _inputDecoration('e.g. 5', Icons.work_history_outlined),
        ),
        const SizedBox(height: AppSpacing.l),

        _buildLabel('BIO / DESCRIPTION'),
        TextFormField(
          controller: _bioController,
          maxLines: 4,
          maxLength: 500,
          decoration: InputDecoration(
            hintText: 'Describe your skills and experience...',
            filled: true,
            fillColor: AppColors.softGray.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(height: AppSpacing.l),

        _buildLabel('HOURLY RATE (DZD)'),
        TextFormField(
          controller: _hourlyRateController,
          keyboardType: TextInputType.number,
          decoration: _inputDecoration('Optional', Icons.attach_money_rounded),
        ),
        const SizedBox(height: AppSpacing.l),

        // Custom quote toggle
        Container(
          decoration: BoxDecoration(
            color: AppColors.softGray.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: SwitchListTile(
            title: Text('Prefer to quote per job', style: AppTextStyles.bodyMedium),
            subtitle: Text('Clients will request custom quotes', style: AppTextStyles.caption),
            value: _prefersCustomQuote,
            onChanged: (v) => setState(() => _prefersCustomQuote = v),
            activeColor: AppColors.accentBlue,
          ),
        ),
        const SizedBox(height: AppSpacing.l),

        // Services
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildLabel('FIXED SERVICES'),
            TextButton.icon(
              onPressed: _addService,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add'),
            ),
          ],
        ),
        if (_services.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.l),
            decoration: BoxDecoration(
              color: AppColors.softGray.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.softGray.withOpacity(0.1)),
            ),
            child: Center(child: Text('No fixed services added', style: AppTextStyles.caption)),
          )
        else
          ..._services.asMap().entries.map((e) => ListTile(
                dense: true,
                title: Text(e.value['name'], style: AppTextStyles.bodyMedium),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${e.value['price']} DZD', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.accentBlue, fontWeight: FontWeight.w600)),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.errorRed),
                      onPressed: () => setState(() => _services.removeAt(e.key)),
                    ),
                  ],
                ),
              )),
        const SizedBox(height: AppSpacing.l),

        _buildLabel('LOCATION'),
        _buildLocationRow(),
        if (_location != null) ...[
          const SizedBox(height: AppSpacing.m),
          MapPreviewWidget(
            latitude: _location!.latitude,
            longitude: _location!.longitude,
          ),
        ],
        const SizedBox(height: AppSpacing.l),

        // Availability
        Container(
          decoration: BoxDecoration(
            color: _isAvailableNow ? AppColors.availableGreen.withOpacity(0.05) : AppColors.softGray.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isAvailableNow ? AppColors.availableGreen.withOpacity(0.3) : AppColors.softGray.withOpacity(0.15),
            ),
          ),
          child: SwitchListTile(
            title: Text('Available Now', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
            subtitle: Text(_isAvailableNow ? 'Clients can see you are available' : 'You appear offline', style: AppTextStyles.caption),
            value: _isAvailableNow,
            onChanged: (v) => setState(() => _isAvailableNow = v),
            activeColor: AppColors.availableGreen,
          ),
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.l),
        Text('Document Verification', style: AppTextStyles.headingLarge.copyWith(fontSize: 24)),
        const SizedBox(height: AppSpacing.s),
        Text('We verify your credentials to earn a verified badge', style: AppTextStyles.bodyMedium),
        const SizedBox(height: AppSpacing.m),

        Container(
          padding: const EdgeInsets.all(AppSpacing.m),
          decoration: BoxDecoration(
            color: AppColors.starGold.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.starGold.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: AppColors.starGold),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Text(
                  'Optional: Upload your professional certificate/diploma AND ID card to get a Verified Badge ✓. You can skip this and add them later.',
                  style: AppTextStyles.caption.copyWith(height: 1.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        _buildLabel('PROFESSIONAL CERTIFICATE / DIPLOMA (Optional)'),
        _buildDocUploadTile(
          label: _diplomaFile != null ? '✓ Document uploaded' : 'Tap to upload certificate or diploma',
          icon: Icons.description_outlined,
          isUploaded: _diplomaFile != null,
          onTap: () => _pickDocument(true),
        ),
        const SizedBox(height: AppSpacing.l),

        _buildLabel('ID CARD / PASSPORT (Optional)'),
        _buildDocUploadTile(
          label: _idFile != null ? '✓ ID uploaded' : 'Tap to upload your ID card',
          icon: Icons.badge_outlined,
          isUploaded: _idFile != null,
          onTap: () => _pickDocument(false),
        ),
        const SizedBox(height: AppSpacing.xl),

        Container(
          padding: const EdgeInsets.all(AppSpacing.m),
          decoration: BoxDecoration(
            color: AppColors.accentBlue.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(children: [
                const Icon(Icons.shield_outlined, color: AppColors.accentBlue, size: 18),
                const SizedBox(width: 8),
                Text('Verification Process', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700, color: AppColors.accentBlue)),
              ]),
              const SizedBox(height: 8),
              Text(
                '1. Upload your professional certificates or licenses. These will be verified by our system.\n2. AI analyzes your certificates\n3. You get approved or feedback in seconds\n4. Approved providers get a verified badge ✓',
                style: AppTextStyles.caption.copyWith(height: 1.8),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Portfolio
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildLabel('PORTFOLIO (OPTIONAL, MAX 10)'),
            TextButton.icon(
              onPressed: _pickPortfolioPhotos,
              icon: const Icon(Icons.add_a_photo_outlined, size: 16),
              label: const Text('Add Photos'),
            ),
          ],
        ),
        if (_portfolioPhotos.isEmpty)
          Center(
            child: Text('Add photos of your work', style: AppTextStyles.caption),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _portfolioPhotos.length,
            itemBuilder: (ctx, i) => Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(_portfolioPhotos[i], fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => setState(() => _portfolioPhotos.removeAt(i)),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                      child: const Icon(Icons.close, color: Colors.white, size: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDocUploadTile({required String label, required IconData icon, required bool isUploaded, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.l),
        decoration: BoxDecoration(
          color: isUploaded ? AppColors.availableGreen.withOpacity(0.06) : AppColors.softGray.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUploaded ? AppColors.availableGreen : AppColors.accentBlue.withOpacity(0.3),
            width: isUploaded ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(isUploaded ? Icons.check_circle_rounded : icon,
                color: isUploaded ? AppColors.availableGreen : AppColors.accentBlue, size: 28),
            const SizedBox(width: AppSpacing.m),
            Expanded(child: Text(label, style: AppTextStyles.bodyMedium.copyWith(
              color: isUploaded ? AppColors.availableGreen : AppColors.textDark,
            ))),
            Icon(Icons.upload_outlined, color: AppColors.softGray, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationRow() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.softGray.withOpacity(0.05),
              borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
            ),
            child: Text(
              _location != null
                  ? '${_location!.latitude.toStringAsFixed(4)}, ${_location!.longitude.toStringAsFixed(4)}'
                  : 'No location set',
              style: AppTextStyles.bodyMedium.copyWith(
                color: _location != null ? AppColors.textDark : AppColors.softGray,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _isLoadingLocation
            ? const SizedBox(width: 56, height: 56, child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
            : GestureDetector(
                onTap: _detectLocation,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _location != null ? AppColors.availableGreen.withOpacity(0.1) : AppColors.accentBlue.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _location != null ? AppColors.availableGreen : AppColors.accentBlue.withOpacity(0.3)),
                  ),
                  child: Icon(
                    _location != null ? Icons.my_location_rounded : Icons.gps_fixed_rounded,
                    color: _location != null ? AppColors.availableGreen : AppColors.accentBlue,
                  ),
                ),
              ),
      ],
    );
  }

  Widget _buildLanguageDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.softGray.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: _selectedLanguage,
          items: const [
            DropdownMenuItem(value: 'en', child: Text('English')),
            DropdownMenuItem(value: 'fr', child: Text('Français')),
            DropdownMenuItem(value: 'ar', child: Text('العربية')),
          ],
          onChanged: (v) => setState(() => _selectedLanguage = v!),
        ),
      ),
    );
  }

  Widget _buildNavButtons() {
    return Row(
      children: [
        if (_currentStep > 0)
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.accentBlue.withOpacity(0.4)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.borderRadius)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () => setState(() => _currentStep--),
              child: const Text('Back'),
            ),
          ),
        if (_currentStep > 0) const SizedBox(width: AppSpacing.m),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.borderRadius)),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: _isLoading
                ? null
                : () {
                    if (_currentStep < 2) {
                      if (_formKey.currentState!.validate()) setState(() => _currentStep++);
                    } else {
                      _submit();
                    }
                  },
            child: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : Text(
                    _currentStep < 2 ? 'Next' : 'Create Account & Verify',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.8)),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.softGray, size: 20),
      filled: true,
      fillColor: AppColors.softGray.withOpacity(0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
    );
  }
}

class _VerificationProgressDialog extends StatelessWidget {
  const _VerificationProgressDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.accentBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(child: CircularProgressIndicator(color: AppColors.accentBlue, strokeWidth: 3)),
            ),
            const SizedBox(height: AppSpacing.l),
            Text('Verifying Documents', style: AppTextStyles.headingSmall),
            const SizedBox(height: AppSpacing.s),
            Text(
              'Our AI is analyzing your certificates...\nThis may take a moment.',
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
