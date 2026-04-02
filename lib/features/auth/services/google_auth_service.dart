import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class GoogleAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserCredential?> signInWithGoogle() async {
    try {
      debugPrint('--- [GOOGLE AUTH] Starting Google Sign-In');
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('--- [GOOGLE AUTH] Cancelled by user');
        return null; // The user canceled the sign-in
      }

      debugPrint('--- [GOOGLE AUTH] Google credentials obtained');
      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      debugPrint('--- [GOOGLE AUTH] Signing in to Firebase');
      // Once signed in, return the UserCredential
      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      // Check if user exists in Firestore
      debugPrint('--- [GOOGLE AUTH] Checking if new user');
      final uid = userCredential.user?.uid;
      if (uid != null) {
        final doc = await _firestore.collection('users').doc(uid).get();
        if (!doc.exists) {
          debugPrint('--- [GOOGLE AUTH] User is new. Saving placeholder doc.');
          // Create initial user doc for new Google users
          await _firestore.collection('users').doc(uid).set({
            'email': userCredential.user?.email ?? '',
            'createdAt': FieldValue.serverTimestamp(),
            'emailVerified': true, // Google accounts are implicitly verified
            'accountType': null,
            'profileCompleted': false,
            'uid': uid,
          });
        } else {
          debugPrint('--- [GOOGLE AUTH] Existing user.');
        }
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('--- [GOOGLE AUTH] Error: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('--- [GOOGLE AUTH] General Error: $e');
      throw 'An error occurred during Google Sign-In.';
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
