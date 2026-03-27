import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class ImageService {
  static final ImageService _instance = ImageService._internal();
  factory ImageService() => _instance;
  ImageService._internal();

  final ImagePicker _picker = ImagePicker();

  /// Captures a photo using the device camera and returns it as a base64 string
  Future<String?> takeCameraPhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80, // Compresses the image to avoid max payload limits
      );
      if (photo != null) {
        return await _convertToBase64(photo);
      }
    } catch (e) {
      debugPrint('Error taking photo: $e');
    }
    return null;
  }

  /// Selects an image from the gallery and returns it as a base64 string
  Future<String?> selectFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );
      if (image != null) {
        return await _convertToBase64(image);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
    return null;
  }

  /// Helper to get base64 encoded string from file bytes
  Future<String> _convertToBase64(XFile file) async {
    final bytes = await file.readAsBytes();
    return base64Encode(bytes);
  }
}
