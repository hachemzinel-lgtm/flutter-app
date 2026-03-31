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
import '../../../core/models/marketplace_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../services/storage_service.dart';
import '../../../core/widgets/map_preview_widget.dart';

const _marketplaceCats = [
  'Restaurant',
  'Bakery',
  'Grocery Store',
  'Pharmacy',
  'Hardware Store',
  'Café',
  'Butcher Shop',
  'Clothing Store',
  'Electronics Store',
  'Other',
];

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

  File? _storefrontPhoto;
  final List<File> _productPhotos = [];
  GeoPoint? _location;
  String _selectedCategory = _marketplaceCats.first;
  String _selectedLanguage = 'en';
  bool _isAlwaysOpen = false;
  bool _isLoading = false;
  bool _isLoadingLocation = false;
  bool _notificationsEnabled = true;
  int _currentStep = 0;

  // Opening hours
  final Map<String, Map<String, String>> _openingHours = {
    'Mon': {'open': '09:00', 'close': '18:00', 'enabled': 'true'},
    'Tue': {'open': '09:00', 'close': '18:00', 'enabled': 'true'},
    'Wed': {'open': '09:00', 'close': '18:00', 'enabled': 'true'},
    'Thu': {'open': '09:00', 'close': '18:00', 'enabled': 'true'},
    'Fri': {'open': '09:00', 'close': '18:00', 'enabled': 'true'},
    'Sat': {'open': '09:00', 'close': '14:00', 'enabled': 'true'},
    'Sun': {'open': '00:00', 'close': '00:00', 'enabled': 'false'},
  };

  @override
  void dispose() {
    _businessNameController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickStorefront() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) setState(() => _storefrontPhoto = File(picked.path));
  }

  Future<void> _pickProductPhotos() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 80);
    if (picked.isNotEmpty) {
      setState(() {
        for (var f in picked) {
          if (_productPhotos.length < 20) _productPhotos.add(File(f.path));
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_storefrontPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Storefront photo is required'), backgroundColor: AppColors.errorRed),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final authService = ref.read(authServiceProvider);
      final uid = authService.currentUser!.uid;
      final email = authService.currentUser!.email!;

      // Upload storefront
      final storefrontUrl = await StorageService.uploadProfilePicture(uid, _storefrontPhoto!);

      // Upload product photos
      final List<String> photoUrls = [storefrontUrl];
      for (int i = 0; i < _productPhotos.length; i++) {
        final url = await StorageService.uploadMarketplacePhoto(uid, _productPhotos[i], 'product_$i');
        photoUrls.add(url);
      }

      final market = MarketplaceModel(
        id: uid,
        email: email,
        name: _businessNameController.text.trim(),
        phone: _phoneController.text.trim(),
        photoUrl: storefrontUrl,
        location: _location,
        language: _selectedLanguage,
        createdAt: DateTime.now(),
        businessName: _businessNameController.text.trim(),
        category: _selectedCategory,
        description: _descriptionController.text.trim(),
        openingHours: _isAlwaysOpen ? {'alwaysOpen': true} : _openingHours,
        photos: photoUrls,
      );

      await authService.setupProfile(market);
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
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
            _buildHeader(),
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

  Widget _buildHeader() {
    final steps = ['Business Info', 'Hours & Location', 'Photos'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.m),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Row(
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
                    color: isDone ? AppColors.availableGreen : isActive ? const Color(0xFF10B981) : AppColors.softGray.withOpacity(0.2),
                  ),
                  child: Center(
                    child: isDone
                        ? const Icon(Icons.check, color: Colors.white, size: 14)
                        : Text('${i + 1}', style: TextStyle(color: isActive ? Colors.white : AppColors.softGray, fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    steps[i],
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.normal,
                      color: isActive ? const Color(0xFF10B981) : AppColors.softGray,
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
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.l),
        Text('Business Information', style: AppTextStyles.headingLarge.copyWith(fontSize: 24)),
        const SizedBox(height: AppSpacing.s),
        Text('Marketplace Account', style: AppTextStyles.bodyMedium.copyWith(color: const Color(0xFF10B981), fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.xxl),

        _buildLabel('BUSINESS NAME *'),
        TextFormField(
          controller: _businessNameController,
          decoration: _inputDecoration('e.g. Bakery El Amouri', Icons.storefront_outlined),
          validator: (v) => v == null || v.isEmpty ? 'Business name is required' : null,
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

        _buildLabel('CATEGORY *'),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.softGray.withOpacity(0.05),
            borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _selectedCategory,
              items: _marketplaceCats.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _selectedCategory = v!),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.l),

        _buildLabel('DESCRIPTION'),
        TextFormField(
          controller: _descriptionController,
          maxLines: 4,
          maxLength: 500,
          decoration: InputDecoration(
            hintText: 'Describe your business...',
            filled: true,
            fillColor: AppColors.softGray.withOpacity(0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.borderRadius), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(height: AppSpacing.l),

        _buildLabel('PREFERRED LANGUAGE'),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: AppColors.softGray.withOpacity(0.05), borderRadius: BorderRadius.circular(AppSpacing.borderRadius)),
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
        ),
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
            activeColor: const Color(0xFF10B981),
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
        Text('Hours & Location', style: AppTextStyles.headingLarge.copyWith(fontSize: 24)),
        const SizedBox(height: AppSpacing.xxl),

        // Always open toggle
        Container(
          decoration: BoxDecoration(
            color: _isAlwaysOpen ? AppColors.availableGreen.withOpacity(0.05) : AppColors.softGray.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _isAlwaysOpen ? AppColors.availableGreen.withOpacity(0.3) : AppColors.softGray.withOpacity(0.15)),
          ),
          child: SwitchListTile(
            title: Text('Always Open (24/7)', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
            value: _isAlwaysOpen,
            onChanged: (v) => setState(() => _isAlwaysOpen = v),
            activeColor: AppColors.availableGreen,
          ),
        ),
        const SizedBox(height: AppSpacing.l),

        if (!_isAlwaysOpen) ...[
          _buildLabel('OPENING HOURS'),
          ..._openingHours.entries.map((e) => _DayHoursRow(
                day: e.key,
                openHour: e.value['open']!,
                closeHour: e.value['close']!,
                isEnabled: e.value['enabled'] == 'true',
                onToggle: (v) => setState(() => _openingHours[e.key]!['enabled'] = v ? 'true' : 'false'),
              )),
          const SizedBox(height: AppSpacing.l),
        ],

        _buildLabel('LOCATION'),
        _buildLocationRow(),
        if (_location != null) ...[
          const SizedBox(height: AppSpacing.m),
          MapPreviewWidget(
            latitude: _location!.latitude,
            longitude: _location!.longitude,
          ),
        ],
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.l),
        Text('Business Photos', style: AppTextStyles.headingLarge.copyWith(fontSize: 24)),
        const SizedBox(height: AppSpacing.s),
        Text('Help customers discover your business', style: AppTextStyles.bodyMedium),
        const SizedBox(height: AppSpacing.xxl),

        _buildLabel('STOREFRONT PHOTO *'),
        GestureDetector(
          onTap: _pickStorefront,
          child: Container(
            height: 180,
            decoration: BoxDecoration(
              color: _storefrontPhoto != null ? null : AppColors.softGray.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _storefrontPhoto != null ? AppColors.availableGreen : AppColors.accentBlue.withOpacity(0.3), width: 1.5),
              image: _storefrontPhoto != null
                  ? DecorationImage(image: FileImage(_storefrontPhoto!), fit: BoxFit.cover)
                  : null,
            ),
            child: _storefrontPhoto == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_photo_alternate_outlined, size: 40, color: AppColors.accentBlue),
                      const SizedBox(height: 8),
                      Text('Tap to add storefront photo', style: AppTextStyles.caption.copyWith(color: AppColors.accentBlue)),
                    ],
                  )
                : null,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildLabel('PRODUCT PHOTOS (${_productPhotos.length}/20)'),
            TextButton.icon(
              onPressed: _pickProductPhotos,
              icon: const Icon(Icons.add_photo_alternate_outlined, size: 16),
              label: const Text('Add Photos'),
            ),
          ],
        ),
        if (_productPhotos.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.l),
            decoration: BoxDecoration(
              color: AppColors.softGray.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.softGray.withOpacity(0.1)),
            ),
            child: Center(child: Text('No product photos added (optional)', style: AppTextStyles.caption)),
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
            itemCount: _productPhotos.length,
            itemBuilder: (ctx, i) => Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(_productPhotos[i], fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => setState(() => _productPhotos.removeAt(i)),
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

  Widget _buildLocationRow() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: AppColors.softGray.withOpacity(0.05),
              borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
            ),
            child: Text(
              _location != null ? '${_location!.latitude.toStringAsFixed(4)}, ${_location!.longitude.toStringAsFixed(4)}' : 'No location set',
              style: AppTextStyles.bodyMedium.copyWith(color: _location != null ? AppColors.textDark : AppColors.softGray),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _detectLocation,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _location != null ? AppColors.availableGreen.withOpacity(0.1) : AppColors.accentBlue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _location != null ? AppColors.availableGreen : AppColors.accentBlue.withOpacity(0.3)),
            ),
            child: _isLoadingLocation
                ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                : Icon(_location != null ? Icons.my_location_rounded : Icons.gps_fixed_rounded,
                    color: _location != null ? AppColors.availableGreen : AppColors.accentBlue),
          ),
        ),
      ],
    );
  }

  Widget _buildNavButtons() {
    return Row(
      children: [
        if (_currentStep > 0) ...[
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF10B981)),
                foregroundColor: const Color(0xFF10B981),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.borderRadius)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () => setState(() => _currentStep--),
              child: const Text('Back'),
            ),
          ),
          const SizedBox(width: AppSpacing.m),
        ],
        Expanded(
          flex: 2,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
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
                    _currentStep < 2 ? 'Next' : 'Create Business Account',
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

class _DayHoursRow extends StatelessWidget {
  final String day;
  final String openHour;
  final String closeHour;
  final bool isEnabled;
  final ValueChanged<bool> onToggle;

  const _DayHoursRow({
    required this.day,
    required this.openHour,
    required this.closeHour,
    required this.isEnabled,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(day, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
          ),
          Switch(value: isEnabled, onChanged: onToggle, activeColor: const Color(0xFF10B981), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
          if (isEnabled) ...[
            const Spacer(),
            Text('$openHour – $closeHour', style: AppTextStyles.caption),
          ] else
            Text(' Closed', style: AppTextStyles.caption.copyWith(color: AppColors.errorRed)),
        ],
      ),
    );
  }
}
