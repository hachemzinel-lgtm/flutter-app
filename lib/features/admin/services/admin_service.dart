import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';

final adminServiceProvider = Provider((ref) => AdminService());

final isAdminProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null || user.email == null) return false;
  
  return ref.read(adminServiceProvider).isUserAdmin(user.email!);
});

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // For this prototype, we whitelist admin emails in code or a specific collection
  final List<String> _whitelistedAdmins = [
    'admin@nearwork.com',
    'hachem@nearwork.com',
  ];

  Future<bool> isUserAdmin(String email) async {
    // Check local whitelist first
    if (_whitelistedAdmins.contains(email.toLowerCase())) return true;
    
    // Also check Firestore 'admins' collection if extra flexibility is needed
    try {
      final doc = await _firestore.collection('admins').doc(email.toLowerCase()).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  Stream<QuerySnapshot> getAllUsers() {
    return _firestore.collection('users').orderBy('createdAt', descending: true).snapshots();
  }

  Future<void> deleteUser(String uid) async {
    // In a real app, this would be a Cloud Function to handle Firebase Auth deletion too
    await _firestore.collection('users').doc(uid).delete();
  }
}
