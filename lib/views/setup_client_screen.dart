import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class SetupClientScreen extends StatefulWidget {
  const SetupClientScreen({super.key});

  @override
  State<SetupClientScreen> createState() => _SetupClientScreenState();
}

class _SetupClientScreenState extends State<SetupClientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _cityController = TextEditingController();
  String _preferredLanguage = 'English';
  File? _imageFile;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

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
        'displayName': _displayNameController.text,
        'city': _cityController.text,
        'language': _preferredLanguage,
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
      appBar: AppBar(title: const Text('Complete Profile')),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator()) 
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
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
                      controller: _displayNameController,
                      decoration: const InputDecoration(labelText: 'Display Name'),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(labelText: 'City'),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    DropdownButtonFormField<String>(
                      value: _preferredLanguage,
                      items: ['Arabic', 'French', 'English']
                          .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                          .toList(),
                      onChanged: (v) => setState(() => _preferredLanguage = v!),
                      decoration: const InputDecoration(labelText: 'Preferred Language'),
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
