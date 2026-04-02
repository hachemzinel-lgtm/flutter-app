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
      debugPrint('--- [SIGNUP] Calling Firebase createUserWithEmailAndPassword');
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final uid = userCredential.user?.uid;
      if (uid != null) {
        debugPrint('--- [SIGNUP] Account created successfully');
        await _firestore.collection('users').doc(uid).set({
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
          'emailVerified': false,
          'accountType': null,
          'profileCompleted': false,
          'uid': uid,
        });
      }

      debugPrint('--- [SIGNUP] Sending verification email');
      await userCredential.user?.sendEmailVerification();
      await userCredential.user?.reload();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> resendVerificationEmail() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  Future<void> sendVerificationCode(String email) async {
    // Generate a 6-digit code (skip for demo, using hardcoded 123456 below)
    
    // In a real app, you'd send this via an email provider (SendGrid, Mailgun, etc.)
    // For this rebuild, we store it in Firestore for the UI to "verify" and print it
    await _firestore.collection('verification_codes').doc(email).set({
      'code': '123456', // Hardcoded for demo/testing as requested in the "rebuilt" status or use actual random
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    // ignore: avoid_print
    print('DEBUG: Verification code for $email is 123456');
  }

  Future<bool> verifyCode(String email, String code) async {
    // For production, you'd check Firestore
    // For this demo/rebuild, we'll accept '123456' or match what's in Firestore
    final doc = await _firestore.collection('verification_codes').doc(email).get();
    if (!doc.exists) return false;
    
    final data = doc.data()!;
    final storedCode = data['code'] as String?;
    
    if (storedCode == code || code == '123456') {
      // Mark email as verified in Firebase Auth (Note: This is normally done by clicking a link, 
      // but we can't manually set emailVerified=true from client SDK easily without Admin SDK.
      // However, we can update our own User document)
      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        await _firestore.collection('users').doc(uid).update({'emailVerified': true});
      }
      return true;
    }
    return false;
  }

  Future<User?> reloadUser() async {
    await _auth.currentUser?.reload();
    return _auth.currentUser;
  }

  // Completes profile setup and saves to Firestore
  Future<void> setupProfile(UserModel userModel) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception("User must be logged in to setup profile");
    }

    final data = userModel.toJson()
      ..['uid'] = uid
      ..['email'] = _auth.currentUser?.email ?? userModel.email
      ..['createdAt'] = userModel.createdAt != null
          ? Timestamp.fromDate(userModel.createdAt!)
          : FieldValue.serverTimestamp()
      ..['updatedAt'] = FieldValue.serverTimestamp()
      ..['profileCompleted'] = true;

    await _firestore.collection('users').doc(uid).set(data, SetOptions(merge: true));
  }

  Future<UserType?> getUserType(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    final data = doc.data()!;
    return UserModel.parseUserType(data['userType'] ?? data['accountType'] ?? 'client');
  }

  Future<bool> isAdminUser(String uid) async {
    final adminDoc = await _firestore.collection('admins').doc(uid).get();
    return adminDoc.exists;
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
