import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../core/models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('--- [AUTH SERVICE] Starting signUp for email: $email ---');
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('--- [AUTH SERVICE] signUp successful for UID: ${userCredential.user?.uid} ---');

      // Generate and "send" verification code
      await sendVerificationCode(email);
    } on FirebaseAuthException catch (e) {
      debugPrint('--- [AUTH SERVICE] FirebaseAuthException in signUp: [${e.code}] ${e.message} ---');
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('--- [AUTH SERVICE] Unexpected error in signUp: $e ---');
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  Future<void> sendVerificationCode(String email) async {
    // Generate a simple 6-digit code
    final code = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();
    debugPrint('--- [AUTH SERVICE] ******************************** ---');
    debugPrint('--- [AUTH SERVICE] VERIFICATION CODE FOR $email: $code ---');
    debugPrint('--- [AUTH SERVICE] ******************************** ---');
    
    // Store in Firestore for verification
    await _firestore.collection('temp_verifications').doc(email).set({
      'code': code,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<bool> verifyCode(String email, String code) async {
    debugPrint('--- [AUTH SERVICE] Verifying code $code for $email ---');
    final doc = await _firestore.collection('temp_verifications').doc(email).get();
    if (!doc.exists) return false;
    final data = doc.data()!;
    
    // Simple verification
    final matches = data['code'] == code;
    if (matches) {
      // Clear the code and MARK AS VERIFIED
      await _firestore.collection('temp_verifications').doc(email).delete();
      await _firestore.collection('verifications').doc(email).set({
        'verified': true,
        'verifiedAt': FieldValue.serverTimestamp(),
      });
    }
    return matches;
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('--- [AUTH SERVICE] Starting signIn for email: $email ---');
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      debugPrint('--- [AUTH SERVICE] signIn successful for UID: ${_auth.currentUser?.uid} ---');
    } on FirebaseAuthException catch (e) {
      debugPrint('--- [AUTH SERVICE] FirebaseAuthException in signIn: [${e.code}] ${e.message} ---');
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('--- [AUTH SERVICE] Unexpected error in signIn: $e ---');
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  Future<void> signOut() async {
    debugPrint('--- [AUTH SERVICE] Signing out... ---');
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    debugPrint('--- [AUTH SERVICE] Resetting password for: $email ---');
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> resendVerificationEmail() async {
    debugPrint('--- [AUTH SERVICE] Resending verification email to: ${_auth.currentUser?.email} ---');
    await _auth.currentUser?.sendEmailVerification();
  }

  Future<void> reloadUser() async {
    debugPrint('--- [AUTH SERVICE] Reloading user data... ---');
    await _auth.currentUser?.reload();
    debugPrint('--- [AUTH SERVICE] User reloaded. Verified: ${_auth.currentUser?.emailVerified} ---');
  }

  // Completes profile setup and saves to Firestore
  Future<void> setupProfile(UserModel userModel) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      debugPrint('--- [AUTH SERVICE] setupProfile FAILED: User not logged in ---');
      throw Exception("User must be logged in to setup profile");
    }
    
    debugPrint('--- [AUTH SERVICE] Saving profile to Firestore for UID: $uid ---');
    await _firestore.collection('users').doc(uid).set(userModel.toJson());
    debugPrint('--- [AUTH SERVICE] Profile saved successfully. ---');
  }

  Future<UserType?> getUserType(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    final data = doc.data()!;
    return UserModel.parseUserType(data['userType'] ?? data['accountType'] ?? 'client');
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'Email is already in use by another account.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'weak-password':
        return 'The password is too weak.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many login attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'Email/Password authentication is not enabled.';
      case 'channel-error':
        return 'Please ensure all fields are filled correctly.';
      default:
        return e.message ?? 'Authentication failed.';
    }
  }
}

