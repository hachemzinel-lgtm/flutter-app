import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';

class ClientEditProfileScreen extends ConsumerStatefulWidget {
  const ClientEditProfileScreen({super.key});

  @override
  ConsumerState<ClientEditProfileScreen> createState() => _ClientEditProfileScreenState();
}

class _ClientEditProfileScreenState extends ConsumerState<ClientEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String? _gender;
  DateTime? _dob;

  final _streetCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _postalCtrl = TextEditingController();
  String? _homeType;

  List<String> _selectedCategories = [];
  String? _budgetRange;
  List<String> _selectedCommunication = [];
  List<String> _selectedLanguages = [];

  List<String> _preferredTimes = [];
  final _notesCtrl = TextEditingController();

  final _genders = ['Male', 'Female', 'Other'];
  final _homeTypes = ['House', 'Apartment', 'Condo', 'Other'];
  final _budgetRanges = ['< \$100', '\$100-500', '\$500+'];
  final _categories = ['Plumbing', 'Electrical', 'Carpentry', 'Cleaning', 'Painting'];
  final _comms = ['Phone', 'WhatsApp', 'Email', 'In-Person'];
  final _languages = ['French', 'Arabic', 'English'];
  final _times = ['Morning', 'Afternoon', 'Evening', 'Weekend'];

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
      _gender = d['gender'];
      _dob = d['dateOfBirth'] != null ? DateTime.tryParse(d['dateOfBirth']) : null;

      final address = d['address'] as Map<String, dynamic>? ?? {};
      _streetCtrl.text = address['street'] ?? '';
      _cityCtrl.text = address['city'] ?? '';
      _postalCtrl.text = address['postalCode'] ?? '';
      _homeType = address['homeType'];

      final prefs = d['preferences'] as Map<String, dynamic>? ?? {};
      _selectedCategories = List<String>.from(prefs['serviceCategories'] ?? []);
      _budgetRange = prefs['budgetRange'];
      _selectedCommunication = List<String>.from(prefs['communication'] ?? []);
      _selectedLanguages = List<String>.from(prefs['languages'] ?? []);

      final avail = d['availability'] as Map<String, dynamic>? ?? {};
      _preferredTimes = List<String>.from(avail['preferredTimes'] ?? []);
      _notesCtrl.text = avail['specialRequests'] ?? '';
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
        'gender': _gender,
        'dateOfBirth': _dob?.toIso8601String(),
        'address': {
          'street': _streetCtrl.text.trim(),
          'city': _cityCtrl.text.trim(),
          'postalCode': _postalCtrl.text.trim(),
          'homeType': _homeType,
        },
        'preferences': {
          'serviceCategories': _selectedCategories,
          'budgetRange': _budgetRange,
          'communication': _selectedCommunication,
          'languages': _selectedLanguages,
        },
        'availability': {
          'preferredTimes': _preferredTimes,
          'specialRequests': _notesCtrl.text.trim(),
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Client profile updated successfully!'), backgroundColor: Colors.green),
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
    _firstNameCtrl.dispose(); _lastNameCtrl.dispose(); _phoneCtrl.dispose();
    _streetCtrl.dispose(); _cityCtrl.dispose(); _postalCtrl.dispose(); _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Client Profile'), elevation: 0),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppSpacing.pagePadding,
          children: [
            _buildSection(
              title: 'Personal Information',
              icon: Icons.person_outline,
              children: [
                _field('First Name', _firstNameCtrl, Icons.person, required: true),
                _field('Last Name', _lastNameCtrl, Icons.person, required: true),
                _field('Phone Number', _phoneCtrl, Icons.phone, type: TextInputType.phone, required: true),
                _dropdown('Gender', _genders, _gender, (v) => setState(() => _gender = v)),
              ],
            ),
            _buildSection(
              title: 'Address & Location',
              icon: Icons.location_on_outlined,
              children: [
                _field('Street Address', _streetCtrl, Icons.home, required: true),
                Row(children: [
                  Expanded(child: _field('City', _cityCtrl, Icons.location_city, required: true)),
                  const SizedBox(width: AppSpacing.m),
                  Expanded(child: _field('Postal Code', _postalCtrl, Icons.markunread_mailbox, required: true)),
                ]),
                _dropdown('Home Type', _homeTypes, _homeType, (v) => setState(() => _homeType = v)),
              ],
            ),
            _buildSection(
              title: 'Preferences',
              icon: Icons.favorite_outline,
              children: [
                _dropdown('Budget Range', _budgetRanges, _budgetRange, (v) => setState(() => _budgetRange = v)),
                _multiSelect('Preferred Categories', _categories, _selectedCategories, (v) => setState(() => _selectedCategories = v)),
                _multiSelect('Communication', _comms, _selectedCommunication, (v) => setState(() => _selectedCommunication = v)),
                _multiSelect('Languages', _languages, _selectedLanguages, (v) => setState(() => _selectedLanguages = v)),
              ],
            ),
            _buildSection(
              title: 'Availability',
              icon: Icons.schedule,
              children: [
                _multiSelect('Preferred Service Times', _times, _preferredTimes, (v) => setState(() => _preferredTimes = v)),
                _field('Special Requests', _notesCtrl, Icons.note, maxLines: 3),
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

  Widget _dropdown(String label, List<String> items, String? value, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            filled: true, fillColor: AppColors.softGray.withOpacity(0.04),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
          items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
          onChanged: onChanged,
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
