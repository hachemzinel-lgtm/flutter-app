import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  // Personal
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();
  String? _gender;
  DateTime? _dob;

  // Professional
  final _titleCtrl = TextEditingController();
  final _businessCtrl = TextEditingController();
  final _yearsExpCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _certificationsCtrl = TextEditingController();
  List<String> _selectedSkills = [];
  List<String> _selectedLanguages = [];

  // Location
  final _cityCtrl = TextEditingController();
  final _postalCtrl = TextEditingController();
  double _serviceRadius = 10.0;

  // Availability
  TimeOfDay? _weekdayStart;
  TimeOfDay? _weekdayEnd;
  bool _emergencyAvailable = false;
  bool _weekendsAvailable = false;

  // Pricing
  final _hourlyRateCtrl = TextEditingController();
  final _minPriceCtrl = TextEditingController();
  final _pricingNotesCtrl = TextEditingController();

  // Section expand state
  bool _personalExpanded = true;
  bool _professionalExpanded = false;
  bool _locationExpanded = false;
  bool _availabilityExpanded = false;
  bool _pricingExpanded = false;

  final _allSkills = ['Pipe Repair', 'Leaks', 'Emergency Plumbing', 'Drain Cleaning', 'Wiring', 'Panels', 'Smart Home', 'Lighting', 'Interior Painting', 'Exterior Painting', 'Masonry', 'Tiling'];
  final _allLanguages = ['French', 'Arabic', 'English', 'Tamazight'];
  final _genders = ['Male', 'Female', 'Other'];

  int get _completionPercent {
    int filled = 0, total = 8;
    if (_firstNameCtrl.text.isNotEmpty) filled++;
    if (_lastNameCtrl.text.isNotEmpty) filled++;
    if (_phoneCtrl.text.isNotEmpty) filled++;
    if (_titleCtrl.text.isNotEmpty) filled++;
    if (_bioCtrl.text.isNotEmpty) filled++;
    if (_cityCtrl.text.isNotEmpty) filled++;
    if (_hourlyRateCtrl.text.isNotEmpty) filled++;
    if (_selectedSkills.isNotEmpty) filled++;
    return ((filled / total) * 100).round();
  }

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
      _firstNameCtrl.text = d['firstName'] ?? '';
      _lastNameCtrl.text = d['lastName'] ?? '';
      _phoneCtrl.text = d['phone'] ?? '';
      _whatsappCtrl.text = d['whatsapp'] ?? '';
      _gender = d['gender'];
      _titleCtrl.text = d['title'] ?? '';
      _businessCtrl.text = d['businessName'] ?? '';
      _yearsExpCtrl.text = d['yearsExp']?.toString() ?? '';
      _bioCtrl.text = d['bio'] ?? '';
      _certificationsCtrl.text = d['certifications'] ?? '';
      _selectedSkills = List<String>.from(d['skills'] ?? []);
      _selectedLanguages = List<String>.from(d['languages'] ?? []);
      _cityCtrl.text = d['city'] ?? '';
      _postalCtrl.text = d['postalCode'] ?? '';
      _serviceRadius = (d['serviceRadius'] as num?)?.toDouble() ?? 10.0;
      _emergencyAvailable = d['emergencyAvailable'] ?? false;
      _weekendsAvailable = d['weekendsAvailable'] ?? false;
      _hourlyRateCtrl.text = d['hourlyRate']?.toString() ?? '';
      _minPriceCtrl.text = d['minPrice']?.toString() ?? '';
      _pricingNotesCtrl.text = d['pricingNotes'] ?? '';
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
        'displayName': '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}',
        'phone': _phoneCtrl.text.trim(),
        'whatsapp': _whatsappCtrl.text.trim(),
        'gender': _gender,
        'dob': _dob?.toIso8601String(),
        'title': _titleCtrl.text.trim(),
        'businessName': _businessCtrl.text.trim(),
        'yearsExp': int.tryParse(_yearsExpCtrl.text),
        'bio': _bioCtrl.text.trim(),
        'certifications': _certificationsCtrl.text.trim(),
        'skills': _selectedSkills,
        'languages': _selectedLanguages,
        'city': _cityCtrl.text.trim(),
        'postalCode': _postalCtrl.text.trim(),
        'serviceRadius': _serviceRadius,
        'emergencyAvailable': _emergencyAvailable,
        'weekendsAvailable': _weekendsAvailable,
        'hourlyRate': double.tryParse(_hourlyRateCtrl.text),
        'minPrice': double.tryParse(_minPriceCtrl.text),
        'pricingNotes': _pricingNotesCtrl.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Profile updated successfully!'), backgroundColor: Colors.green),
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
    _whatsappCtrl.dispose(); _titleCtrl.dispose(); _businessCtrl.dispose();
    _yearsExpCtrl.dispose(); _bioCtrl.dispose(); _certificationsCtrl.dispose();
    _cityCtrl.dispose(); _postalCtrl.dispose(); _hourlyRateCtrl.dispose();
    _minPriceCtrl.dispose(); _pricingNotesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pct = _completionPercent;
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile'), elevation: 0),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppSpacing.pagePadding,
          children: [
            // Avatar
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 52,
                    backgroundColor: AppColors.accentBlue.withOpacity(0.1),
                    child: const Icon(Icons.person, size: 52, color: AppColors.accentBlue),
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: AppColors.accentBlue, shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.l),

            // Completion
            Row(children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: pct / 100,
                  backgroundColor: AppColors.softGray.withOpacity(0.15),
                  valueColor: const AlwaysStoppedAnimation(AppColors.accentBlue),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 12),
              Text('$pct% Complete', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700, color: AppColors.accentBlue)),
            ]),
            const SizedBox(height: AppSpacing.l),

            // ── PERSONAL ──────────────────────────────────────
            _section(
              title: 'Personal Information',
              icon: Icons.person_outline,
              expanded: _personalExpanded,
              onToggle: () => setState(() => _personalExpanded = !_personalExpanded),
              children: [
                _row([
                  _field('First Name', _firstNameCtrl, Icons.badge_outlined, required: true),
                  const SizedBox(width: 12),
                  _field('Last Name', _lastNameCtrl, Icons.badge_outlined, required: true),
                ]),
                _field('Phone Number', _phoneCtrl, Icons.phone_outlined, type: TextInputType.phone),
                _field('WhatsApp Number', _whatsappCtrl, Icons.chat_outlined, type: TextInputType.phone),
                _dropdown('Gender', _genders, _gender, (v) => setState(() => _gender = v), Icons.wc_outlined),
                _dobPicker(),
              ],
            ),

            // ── PROFESSIONAL ──────────────────────────────────
            _section(
              title: 'Professional Info',
              icon: Icons.work_outline,
              expanded: _professionalExpanded,
              onToggle: () => setState(() => _professionalExpanded = !_professionalExpanded),
              children: [
                _field('Professional Title', _titleCtrl, Icons.construction_outlined, hint: 'e.g. Plombier, Électricien'),
                _field('Business/Company Name', _businessCtrl, Icons.business_outlined),
                _field('Years of Experience', _yearsExpCtrl, Icons.timeline_outlined, type: TextInputType.number),
                _field('Bio / About Me', _bioCtrl, Icons.article_outlined, maxLines: 4, maxLen: 500, hint: 'Tell clients about yourself...'),
                _field('Certifications', _certificationsCtrl, Icons.verified_outlined, maxLines: 3),
                _multiSelect('Skills / Specializations', _allSkills, _selectedSkills, (v) => setState(() => _selectedSkills = v)),
                _multiSelect('Languages Spoken', _allLanguages, _selectedLanguages, (v) => setState(() => _selectedLanguages = v)),
              ],
            ),

            // ── LOCATION ──────────────────────────────────────
            _section(
              title: 'Location & Service Area',
              icon: Icons.location_on_outlined,
              expanded: _locationExpanded,
              onToggle: () => setState(() => _locationExpanded = !_locationExpanded),
              children: [
                _field('City / Region', _cityCtrl, Icons.location_city_outlined),
                _field('Postal Code', _postalCtrl, Icons.local_post_office_outlined, type: TextInputType.number),
                const SizedBox(height: 8),
                Text('Service Radius: ${_serviceRadius.toStringAsFixed(0)} km', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                Slider(
                  value: _serviceRadius, min: 1, max: 100, divisions: 99,
                  activeColor: AppColors.accentBlue,
                  onChanged: (v) => setState(() => _serviceRadius = v),
                ),
              ],
            ),

            // ── AVAILABILITY ──────────────────────────────────
            _section(
              title: 'Work Hours & Availability',
              icon: Icons.schedule_outlined,
              expanded: _availabilityExpanded,
              onToggle: () => setState(() => _availabilityExpanded = !_availabilityExpanded),
              children: [
                _timePickers(),
                SwitchListTile(
                  value: _emergencyAvailable,
                  activeColor: AppColors.accentBlue,
                  contentPadding: EdgeInsets.zero,
                  title: Text('Available for Emergency Calls', style: AppTextStyles.bodyLarge),
                  onChanged: (v) => setState(() => _emergencyAvailable = v),
                ),
                SwitchListTile(
                  value: _weekendsAvailable,
                  activeColor: AppColors.accentBlue,
                  contentPadding: EdgeInsets.zero,
                  title: Text('Available on Weekends', style: AppTextStyles.bodyLarge),
                  onChanged: (v) => setState(() => _weekendsAvailable = v),
                ),
              ],
            ),

            // ── PRICING ───────────────────────────────────────
            _section(
              title: 'Pricing',
              icon: Icons.attach_money,
              expanded: _pricingExpanded,
              onToggle: () => setState(() => _pricingExpanded = !_pricingExpanded),
              children: [
                _row([
                  _field('Hourly Rate (DT)', _hourlyRateCtrl, Icons.attach_money, type: TextInputType.number),
                  const SizedBox(width: 12),
                  _field('Min Job Price (DT)', _minPriceCtrl, Icons.money_off_outlined, type: TextInputType.number),
                ]),
                _field('Pricing Notes', _pricingNotesCtrl, Icons.note_outlined, hint: 'e.g. Free consultation', maxLines: 2),
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
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────

  Widget _section({required String title, required IconData icon, required bool expanded, required VoidCallback onToggle, required List<Widget> children}) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.m),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.borderRadius), side: BorderSide(color: AppColors.softGray.withOpacity(0.15))),
      child: ExpansionTile(
        initiallyExpanded: expanded,
        leading: Icon(icon, color: AppColors.accentBlue),
        title: Text(title, style: AppTextStyles.headingSmall.copyWith(fontSize: 15)),
        onExpansionChanged: (_) => onToggle(),
        childrenPadding: const EdgeInsets.fromLTRB(AppSpacing.m, 0, AppSpacing.m, AppSpacing.m),
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: children.map((w) => Padding(padding: const EdgeInsets.only(bottom: 12), child: w)).toList()),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, IconData icon, {
    TextInputType? type, bool required = false, int maxLines = 1, int? maxLen, String? hint
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label + (required ? ' *' : ''), style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: type,
          maxLines: maxLines,
          maxLength: maxLen,
          onChanged: (_) => setState(() {}),
          validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null : null,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: maxLines == 1 ? Icon(icon, color: AppColors.softGray, size: 18) : null,
            filled: true,
            fillColor: AppColors.softGray.withOpacity(0.04),
            counterText: '',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _row(List<Widget> children) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: children.map((w) => w is SizedBox ? w : Expanded(child: w)).toList(),
  );

  Widget _dropdown(String label, List<String> items, String? value, ValueChanged<String?> onChanged, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.softGray, size: 18),
            filled: true,
            fillColor: AppColors.softGray.withOpacity(0.04),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
          hint: Text('Select $label', style: AppTextStyles.bodyMedium),
          items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _dobPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Date of Birth', style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _dob ?? DateTime(1990),
              firstDate: DateTime(1940),
              lastDate: DateTime.now(),
            );
            if (picked != null) setState(() => _dob = picked);
          },
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.softGray.withOpacity(0.04),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined, color: AppColors.softGray, size: 18),
                const SizedBox(width: 12),
                Text(
                  _dob != null ? '${_dob!.day}/${_dob!.month}/${_dob!.year}' : 'Select date',
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            ),
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
          spacing: 6,
          runSpacing: 6,
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

  Widget _timePickers() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mon–Fri Work Hours', style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _timePicker('Start Time', _weekdayStart, (t) => setState(() => _weekdayStart = t))),
            const SizedBox(width: 12),
            Expanded(child: _timePicker('End Time', _weekdayEnd, (t) => setState(() => _weekdayEnd = t))),
          ],
        ),
      ],
    );
  }

  Widget _timePicker(String label, TimeOfDay? time, Function(TimeOfDay) onPick) {
    return InkWell(
      onTap: () async {
        final t = await showTimePicker(context: context, initialTime: time ?? TimeOfDay.now());
        if (t != null) onPick(t);
      },
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.softGray.withOpacity(0.04),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time, color: AppColors.softGray, size: 18),
            const SizedBox(width: 8),
            Text(time != null ? time.format(context) : label, style: AppTextStyles.bodyMedium),
          ],
        ),
      ),
    );
  }
}
