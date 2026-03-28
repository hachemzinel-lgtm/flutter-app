import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

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
      );
      if (image != null) {
        return await _convertToBase64(image);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
    return null;
  }

  /// Helper to get base64 encoded string from file bytes, heavily compressed using the `image` package
  Future<String> _convertToBase64(XFile file) async {
    final bytes = await file.readAsBytes();
    
    // Decode the image
    img.Image? decodedImage = img.decodeImage(bytes);
    if (decodedImage == null) return base64Encode(bytes); // Fallback

    // Resize the image to have a maximum width of 800 while maintaining aspect ratio
    if (decodedImage.width > 800) {
      decodedImage = img.copyResize(decodedImage, width: 800);
    }

    // Compress using JPEG encoding
    final compressedBytes = img.encodeJpg(decodedImage, quality: 70);
    
    return base64Encode(compressedBytes);
  }
}
