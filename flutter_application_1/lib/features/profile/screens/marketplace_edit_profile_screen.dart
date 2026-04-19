import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';

class MarketplaceEditProfileScreen extends ConsumerStatefulWidget {
  const MarketplaceEditProfileScreen({super.key});

  @override
  ConsumerState<MarketplaceEditProfileScreen> createState() => _MarketplaceEditProfileScreenState();
}

class _MarketplaceEditProfileScreenState extends ConsumerState<MarketplaceEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  final _shopNameCtrl = TextEditingController();
  final _shopDescCtrl = TextEditingController();
  final _shopCategoryCtrl = TextEditingController();
  
  final _ownerNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();

  final _streetCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  
  bool _deliveryAvailable = false;
  double _deliveryRadius = 15.0;

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
      _shopNameCtrl.text = d['shopName'] ?? d['name'] ?? '';
      _shopDescCtrl.text = d['shopDescription'] ?? '';
      _shopCategoryCtrl.text = d['shopCategory'] ?? '';

      _ownerNameCtrl.text = d['ownerName'] ?? d['firstName'] ?? '';
      
      final contact = d['contact'] as Map<String, dynamic>? ?? {};
      _phoneCtrl.text = contact['phoneNumber'] ?? d['phone'] ?? '';
      _whatsappCtrl.text = contact['whatsappNumber'] ?? '';

      final loc = d['location'] as Map<String, dynamic>? ?? {};
      _streetCtrl.text = loc['street'] ?? '';
      _cityCtrl.text = loc['city'] ?? '';
      _deliveryAvailable = loc['deliveryAvailable'] ?? false;
      _deliveryRadius = (loc['deliveryRadius'] as num?)?.toDouble() ?? 15.0;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'shopName': _shopNameCtrl.text.trim(),
        'name': _shopNameCtrl.text.trim(),
        'shopDescription': _shopDescCtrl.text.trim(),
        'shopCategory': _shopCategoryCtrl.text.trim(),
        'ownerName': _ownerNameCtrl.text.trim(),
        'contact': {
          'phoneNumber': _phoneCtrl.text.trim(),
          'whatsappNumber': _whatsappCtrl.text.trim(),
        },
        'location': {
          'street': _streetCtrl.text.trim(),
          'city': _cityCtrl.text.trim(),
          'deliveryAvailable': _deliveryAvailable,
          'deliveryRadius': _deliveryRadius,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Marketplace profile updated successfully!'), backgroundColor: Colors.green),
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
    _shopNameCtrl.dispose(); _shopDescCtrl.dispose(); _shopCategoryCtrl.dispose();
    _ownerNameCtrl.dispose(); _phoneCtrl.dispose(); _whatsappCtrl.dispose();
    _streetCtrl.dispose(); _cityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Marketplace Profile'), elevation: 0),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppSpacing.pagePadding,
          children: [
            _buildSection(
              title: 'Shop Details',
              icon: Icons.store_outlined,
              children: [
                _field('Shop / Business Name', _shopNameCtrl, Icons.store, required: true),
                _field('Category (e.g., Electronics, Bakery)', _shopCategoryCtrl, Icons.category, required: true),
                _field('Shop Description', _shopDescCtrl, Icons.article, maxLines: 4),
              ],
            ),
            _buildSection(
              title: 'Contact Information',
              icon: Icons.contact_page_outlined,
              children: [
                _field('Owner Name', _ownerNameCtrl, Icons.person, required: true),
                _field('Phone Number', _phoneCtrl, Icons.phone, type: TextInputType.phone, required: true),
                _field('WhatsApp Number', _whatsappCtrl, Icons.chat, type: TextInputType.phone),
              ],
            ),
            _buildSection(
              title: 'Location & Delivery',
              icon: Icons.local_shipping_outlined,
              children: [
                _field('Street Address', _streetCtrl, Icons.home, required: true),
                _field('City', _cityCtrl, Icons.location_city, required: true),
                SwitchListTile(
                  title: const Text('Delivery Available', style: TextStyle(fontWeight: FontWeight.w600)),
                  value: _deliveryAvailable,
                  activeColor: AppColors.accentBlue,
                  onChanged: (v) => setState(() => _deliveryAvailable = v),
                  contentPadding: EdgeInsets.zero,
                ),
                if (_deliveryAvailable) ...[
                  const SizedBox(height: 8),
                  Text('Delivery Radius: ${_deliveryRadius.toStringAsFixed(0)} km', style: AppTextStyles.bodyLarge),
                  Slider(
                    value: _deliveryRadius, min: 1, max: 100, divisions: 99,
                    activeColor: AppColors.accentBlue,
                    onChanged: (v) => setState(() => _deliveryRadius = v),
                  ),
                ],
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
}
