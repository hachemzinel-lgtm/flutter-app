import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';

class BuilderEditProfileScreen extends ConsumerStatefulWidget {
  const BuilderEditProfileScreen({super.key});

  @override
  ConsumerState<BuilderEditProfileScreen> createState() => _BuilderEditProfileScreenState();
}

class _BuilderEditProfileScreenState extends ConsumerState<BuilderEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();

  final _titleCtrl = TextEditingController();
  final _businessCtrl = TextEditingController();
  final _yearsExpCtrl = TextEditingController();
  List<String> _specializations = [];
  List<String> _languages = [];

  final _cityCtrl = TextEditingController();
  final _shopAddressCtrl = TextEditingController();
  final _postalCtrl = TextEditingController();
  double _serviceRadius = 25.0;

  final _hourlyRateCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  final _availableSpecializations = ['Emergency Plumbing', 'Pipe Repair', 'Wiring', 'Panels', 'Carpentry', 'Masonry'];
  final _availableLanguages = ['French', 'Arabic', 'English'];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (!doc.exists || !mounted) return;
    
    final d = doc.data()!;
    setState(() {
      _firstNameCtrl.text = d['firstName'] ?? d['name']?.split(' ').first ?? '';
      _lastNameCtrl.text = d['lastName'] ?? (d['name'] != null && d['name'].toString().contains(' ') ? d['name'].split(' ').last : '');
      _phoneCtrl.text = d['phoneNumber'] ?? d['phone'] ?? '';
      _whatsappCtrl.text = d['whatsappNumber'] ?? '';

      final prof = d['professional'] as Map<String, dynamic>? ?? {};
      _titleCtrl.text = prof['title'] ?? '';
      _businessCtrl.text = prof['businessName'] ?? '';
      _yearsExpCtrl.text = prof['yearsExperience']?.toString() ?? '';
      _specializations = List<String>.from(prof['specializations'] ?? []);
      _languages = List<String>.from(prof['languages'] ?? []);

      final loc = d['location'] as Map<String, dynamic>? ?? {};
      _cityCtrl.text = loc['city'] ?? '';
      _shopAddressCtrl.text = loc['shopAddress'] ?? '';
      _postalCtrl.text = loc['postalCode'] ?? '';
      _serviceRadius = (loc['serviceRadius'] as num?)?.toDouble() ?? 25.0;

      final prc = d['pricing'] as Map<String, dynamic>? ?? {};
      _hourlyRateCtrl.text = prc['hourlyRate']?.toString() ?? '';
      _bioCtrl.text = d['bio'] ?? '';
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'firstName': _firstNameCtrl.text.trim(),
        'lastName': _lastNameCtrl.text.trim(),
        'name': '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}',
        'phoneNumber': _phoneCtrl.text.trim(),
        'whatsappNumber': _whatsappCtrl.text.trim(),
        'professional': {
          'title': _titleCtrl.text.trim(),
          'businessName': _businessCtrl.text.trim(),
          'yearsExperience': int.tryParse(_yearsExpCtrl.text),
          'specializations': _specializations,
          'languages': _languages,
        },
        'location': {
          'city': _cityCtrl.text.trim(),
          'shopAddress': _shopAddressCtrl.text.trim(),
          'postalCode': _postalCtrl.text.trim(),
          'serviceRadius': _serviceRadius,
        },
        'pricing': {
          'hourlyRate': double.tryParse(_hourlyRateCtrl.text),
        },
        'bio': _bioCtrl.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Provider profile updated successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose(); _lastNameCtrl.dispose(); _phoneCtrl.dispose(); _whatsappCtrl.dispose();
    _titleCtrl.dispose(); _businessCtrl.dispose(); _yearsExpCtrl.dispose();
    _cityCtrl.dispose(); _shopAddressCtrl.dispose(); _postalCtrl.dispose();
    _hourlyRateCtrl.dispose(); _bioCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Provider Profile'), elevation: 0),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppSpacing.pagePadding,
          children: [
            _buildSection(
              title: 'Personal Info (Private)',
              icon: Icons.person_outline,
              children: [
                _field('First Name', _firstNameCtrl, Icons.person, required: true),
                _field('Last Name', _lastNameCtrl, Icons.person, required: true),
                _field('Phone Number', _phoneCtrl, Icons.phone, type: TextInputType.phone, required: true),
                _field('WhatsApp Number', _whatsappCtrl, Icons.chat, type: TextInputType.phone),
              ],
            ),
            _buildSection(
              title: 'Professional Details',
              icon: Icons.work_outline,
              children: [
                _field('Profession / Title', _titleCtrl, Icons.construction, required: true),
                _field('Years Experience', _yearsExpCtrl, Icons.timeline, type: TextInputType.number, required: true),
                _field('Business Name (Optional)', _businessCtrl, Icons.business),
                _multiSelect('Specializations', _availableSpecializations, _specializations, (v) => setState(() => _specializations = v)),
                _multiSelect('Languages', _availableLanguages, _languages, (v) => setState(() => _languages = v)),
                _field('Bio/Description', _bioCtrl, Icons.article, maxLines: 4),
              ],
            ),
            _buildSection(
              title: 'Service Area',
              icon: Icons.map_outlined,
              children: [
                _field('City', _cityCtrl, Icons.location_city, required: true),
                _field('Postal Code', _postalCtrl, Icons.markunread_mailbox, required: true),
                const SizedBox(height: 8),
                Text('Service Radius: ${_serviceRadius.toStringAsFixed(0)} km', style: AppTextStyles.bodyLarge),
                Slider(
                  value: _serviceRadius, min: 1, max: 100, divisions: 99,
                  activeColor: AppColors.accentBlue,
                  onChanged: (v) => setState(() => _serviceRadius = v),
                ),
              ],
            ),
            _buildSection(
              title: 'Pricing',
              icon: Icons.attach_money,
              children: [
                _field('Hourly Rate (\$)', _hourlyRateCtrl, Icons.money, type: TextInputType.number, required: true),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              height: AppSpacing.buttonHeight,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.borderRadius)),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required IconData icon, required List<Widget> children}) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.m),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.borderRadius), side: BorderSide(color: AppColors.softGray.withOpacity(0.15))),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: AppColors.accentBlue),
              const SizedBox(width: 8),
              Text(title, style: AppTextStyles.headingSmall.copyWith(fontSize: 15)),
            ]),
            const SizedBox(height: AppSpacing.l),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: children.map((w) => Padding(padding: const EdgeInsets.only(bottom: 12), child: w)).toList()),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, IconData icon, {TextInputType? type, bool required = false, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label + (required ? ' *' : ''), style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: type,
          maxLines: maxLines,
          validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null : null,
          decoration: InputDecoration(
            prefixIcon: maxLines == 1 ? Icon(icon, color: AppColors.softGray, size: 18) : null,
            filled: true,
            fillColor: AppColors.softGray.withOpacity(0.04),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _multiSelect(String label, List<String> options, List<String> selected, Function(List<String>) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6, runSpacing: 6,
          children: options.map((opt) {
            final isSelected = selected.contains(opt);
            return GestureDetector(
              onTap: () {
                final next = List<String>.from(selected);
                isSelected ? next.remove(opt) : next.add(opt);
                onChanged(next);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.accentBlue : AppColors.softGray.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(opt, style: TextStyle(color: isSelected ? Colors.white : AppColors.textDark, fontSize: 13, fontWeight: FontWeight.w500)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
