import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_application_1/views/app_constants.dart';

class SetupMarketplaceScreen extends StatefulWidget {
  const SetupMarketplaceScreen({super.key});

  @override
  State<SetupMarketplaceScreen> createState() => _SetupMarketplaceScreenState();
}

class _SetupMarketplaceScreenState extends State<SetupMarketplaceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _category;
  double _deliveryRadius = 10;
  bool _openStatus = false;
  File? _imageFile;
  LatLng? _location;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location services are disabled.')));
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;
    
    Position pos = await Geolocator.getCurrentPosition();
    setState(() => _location = LatLng(pos.latitude, pos.longitude));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_location == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select location')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      String? photoUrl;
      if (_imageFile != null) {
        final ref = FirebaseStorage.instance.ref().child('avatars/${user.uid}/profile.jpg');
        await ref.putFile(_imageFile!);
        photoUrl = await ref.getDownloadURL();
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'businessName': _businessNameController.text,
        'phone': _phoneController.text,
        'category': _category,
        'description': _descriptionController.text,
        'deliveryRadius': _deliveryRadius.toInt(),
        'location': GeoPoint(_location!.latitude, _location!.longitude),
        'openStatus': _openStatus,
        if (photoUrl != null) 'photoUrl': photoUrl,
        'profileComplete': true,
      });

      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complete Marketplace Profile')),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator()) 
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
                        child: _imageFile == null ? const Icon(Icons.add_a_photo) : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _businessNameController, 
                      decoration: const InputDecoration(labelText: 'Business Name'), 
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    TextFormField(
                      controller: _phoneController, 
                      decoration: const InputDecoration(labelText: 'Phone Number'), 
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    DropdownButtonFormField<String>(
                      value: _category,
                      items: AppConstants.marketplaceCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) => setState(() => _category = v),
                      decoration: const InputDecoration(labelText: 'Category'),
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                    TextFormField(
                      controller: _descriptionController, 
                      maxLength: 400, 
                      maxLines: 3, 
                      decoration: const InputDecoration(labelText: 'Description (max 400 chars)'), 
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    Text('Delivery Radius: ${_deliveryRadius.toInt()} km'),
                    Slider(
                      value: _deliveryRadius, 
                      min: 1, 
                      max: 50, 
                      onChanged: (v) => setState(() => _deliveryRadius = v),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _getLocation, 
                      icon: const Icon(Icons.gps_fixed), 
                      label: const Text('Get Business Location'),
                    ),
                    if (_location != null)
                      SizedBox(
                        height: 150,
                        child: FlutterMap(
                          options: MapOptions(initialCenter: _location!, initialZoom: 13),
                          children: [
                            TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
                            MarkerLayer(markers: [Marker(point: _location!, child: const Icon(Icons.location_pin, color: Colors.blue))]),
                          ],
                        ),
                      ),
                    SwitchListTile(
                      title: const Text('Currently Open'), 
                      value: _openStatus, 
                      onChanged: (v) => setState(() => _openStatus = v),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(onPressed: _submit, child: const Text('Complete Profile')),
                  ],
                ),
              ),
            ),
    );
  }
}
