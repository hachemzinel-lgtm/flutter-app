import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_application_1/views/app_constants.dart';
import 'package:flutter_application_1/views/credential_upload_widget.dart';
import 'package:flutter_application_1/routes/route_paths.dart';
import 'package:flutter_application_1/services/location_service.dart';

class SetupProviderScreen extends StatefulWidget {
  const SetupProviderScreen({super.key});

  @override
  State<SetupProviderScreen> createState() => _SetupProviderScreenState();
}

class _SetupProviderScreenState extends State<SetupProviderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _experienceController = TextEditingController();
  String? _category;
  double _serviceRadius = 10;
  bool _availability = false;
  File? _imageFile;
  LatLng? _location;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _getLocation() async {
    final pos = await LocationService().getCurrentLocation(
      context: context,
      onRetry: _getLocation,
    );
    if (pos == null) {
      return;
    }
    setState(() => _location = LatLng(pos.latitude, pos.longitude));
  }

  Future<void> _submit({required bool skipVerification}) async {
    if (!_formKey.currentState!.validate()) return;
    if (_location == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select location')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      String? photoUrl;
      if (_imageFile != null) {
        final ref = FirebaseStorage.instance.ref().child(
          'avatars/${user.uid}/profile.jpg',
        );
        await ref.putFile(_imageFile!);
        photoUrl = await ref.getDownloadURL();
      }

      final updateData = <String, dynamic>{
        'displayName': _displayNameController.text,
        'phone': _phoneController.text,
        'category': _category,
        'bio': _bioController.text,
        'yearsExperience': int.tryParse(_experienceController.text) ?? 0,
        'serviceRadius': _serviceRadius.toInt(),
        'location': GeoPoint(_location!.latitude, _location!.longitude),
        'availabilityToggle': _availability,
        if (photoUrl != null) 'photoUrl': photoUrl,
        'profileComplete': true,
      };

      if (skipVerification) {
        updateData['verificationStatus'] = 'unverified';
        updateData['badgeVisible'] = false;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update(updateData);

      if (mounted) context.goNamed(AppRoutes.homeName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complete Provider Profile')),
      body:
          _isLoading
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
                          backgroundImage:
                              _imageFile != null
                                  ? FileImage(_imageFile!)
                                  : null,
                          child:
                              _imageFile == null
                                  ? const Icon(Icons.add_a_photo)
                                  : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _displayNameController,
                        decoration: const InputDecoration(
                          labelText: 'Display Name',
                        ),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                        ),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      DropdownButtonFormField<String>(
                        initialValue: _category,
                        items:
                            AppConstants.providerCategories
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) => setState(() => _category = v),
                        decoration: const InputDecoration(
                          labelText: 'Category',
                        ),
                        validator: (v) => v == null ? 'Required' : null,
                      ),
                      TextFormField(
                        controller: _bioController,
                        maxLength: 300,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Bio (max 300 chars)',
                        ),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      TextFormField(
                        controller: _experienceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Years of Experience',
                        ),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      Text('Service Radius: ${_serviceRadius.toInt()} km'),
                      Slider(
                        value: _serviceRadius,
                        min: 1,
                        max: 50,
                        onChanged: (v) => setState(() => _serviceRadius = v),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _getLocation,
                        icon: const Icon(Icons.gps_fixed),
                        label: const Text('Get My Location'),
                      ),
                      if (_location != null)
                        SizedBox(
                          height: 150,
                          child: FlutterMap(
                            options: MapOptions(
                              initialCenter: _location!,
                              initialZoom: 13,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: _location!,
                                    child: const Icon(
                                      Icons.location_pin,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      SwitchListTile(
                        title: const Text('Available for work'),
                        value: _availability,
                        onChanged: (v) => setState(() => _availability = v),
                      ),

                      CredentialUploadWidget(
                        onComplete: () => _submit(skipVerification: false),
                        onSkip: () => _submit(skipVerification: true),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
