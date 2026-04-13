import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/verification_controller.dart';

class CredentialUploadWidget extends ConsumerStatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback onSkip;

  const CredentialUploadWidget({
    super.key,
    required this.onComplete,
    required this.onSkip,
  });

  @override
  ConsumerState<CredentialUploadWidget> createState() => _CredentialUploadWidgetState();
}

class _CredentialUploadWidgetState extends ConsumerState<CredentialUploadWidget> {
  File? _imageFile;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
      ref.read(verificationControllerProvider.notifier).reset();
    }
  }

  void _verifyNow() {
    if (_imageFile == null) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    
    ref.read(verificationControllerProvider.notifier).verifyDocument(_imageFile!, uid);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(verificationControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 32),
        const Text('Professional Credentials', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        
        if (state.status == VerificationStateStatus.idle && _imageFile == null) ...[
          const Text('Upload your diploma, trade certificate, or professional license. Our AI reviews it instantly. Completely optional.'),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: _pickImage, child: const Text('Upload Document')),
          TextButton(onPressed: widget.onSkip, child: const Text('Skip for now →')),
        ] else if (state.status == VerificationStateStatus.idle && _imageFile != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(_imageFile!, height: 200, fit: BoxFit.cover),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: _verifyNow, child: const Text('Verify Now')),
          TextButton(onPressed: _pickImage, child: const Text('Choose different image')),
          TextButton(onPressed: widget.onSkip, child: const Text('Skip for now →')),
        ] else if (state.status == VerificationStateStatus.loading) ...[
          const SizedBox(height: 32),
          const Center(child: CircularProgressIndicator()),
          const SizedBox(height: 16),
          const Center(child: Text('Analyzing your document...')),
          const SizedBox(height: 32),
        ] else if (state.status == VerificationStateStatus.success) ...[
          const Center(child: Icon(Icons.check_circle, color: Colors.green, size: 64)),
          const SizedBox(height: 16),
          const Text(
            'You\'re verified! ✅ Your badge is now visible on your profile.',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: widget.onComplete, child: const Text('Continue')),
        ] else if (state.status == VerificationStateStatus.failure) ...[
          const Center(child: Icon(Icons.warning, color: Colors.amber, size: 64)),
          const SizedBox(height: 16),
          Text(
            state.error ?? 'We couldn\'t verify this document. Make sure it\'s fully visible, well-lit, and readable.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {
              ref.read(verificationControllerProvider.notifier).reset();
              setState(() => _imageFile = null);
            },
            child: const Text('Try Again'),
          ),
          TextButton(onPressed: widget.onComplete, child: const Text('Continue without badge →')),
        ],
      ],
    );
  }
}
