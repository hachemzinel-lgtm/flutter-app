import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  static final _storage = FirebaseStorage.instance;

  static Future<String> uploadProfilePicture(String uid, File file) async {
    final ref = _storage.ref('users/$uid/profile/profile.jpg');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  static Future<String> uploadProfilePictureWithProgress(
    String uid,
    File file, {
    void Function(double progress)? onProgress,
  }) async {
    final ref = _storage.ref('users/$uid/profile/profile.jpg');
    final task = ref.putFile(file);
    final subscription = task.snapshotEvents.listen((snapshot) {
      if (snapshot.totalBytes <= 0) {
        return;
      }
      onProgress?.call(snapshot.bytesTransferred / snapshot.totalBytes);
    });

    try {
      final snapshot = await task;
      onProgress?.call(1);
      return await snapshot.ref.getDownloadURL();
    } finally {
      await subscription.cancel();
    }
  }

  static Future<String> uploadDocument(
    String uid,
    File file,
    String name,
  ) async {
    final ref = _storage.ref('users/$uid/documents/$name.pdf');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  static Future<String> uploadPortfolioPhoto(
    String uid,
    File file,
    String photoId,
  ) async {
    final ref = _storage.ref('users/$uid/portfolio/$photoId.jpg');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  static Future<String> uploadMarketplacePhoto(
    String uid,
    File file,
    String photoId,
  ) async {
    final ref = _storage.ref('users/$uid/marketplace_photos/$photoId.jpg');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  static Future<String> uploadMessageMedia(
    String conversationId,
    String messageId,
    File file,
    String ext,
  ) async {
    final ref = _storage.ref('messages/$conversationId/$messageId.$ext');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  static Future<void> deleteFile(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (_) {}
  }
}
