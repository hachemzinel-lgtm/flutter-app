import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthException implements Exception {
  const GoogleAuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class GoogleAuthService {
  GoogleAuthService({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
    FirebaseFirestore? firestore,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn(),
       _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final FirebaseFirestore _firestore;

  Future<UserCredential?> signInWithGoogle() async {
    print('--- [GOOGLE AUTH] Starting Google sign-in flow');
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print('--- [GOOGLE AUTH] User cancelled Google sign-in');
        return null;
      }

      final googleAuth = await googleUser.authentication;
      print('--- [GOOGLE AUTH] Retrieved Google authentication tokens');

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) {
        throw const GoogleAuthException(
          'Google sign-in did not return a valid user. Please try again.',
        );
      }

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        print(
          '--- [GOOGLE AUTH] Creating initial Firestore document for new user',
        );
        await _firestore.collection('users').doc(user.uid).set({
          'email': user.email,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'emailVerified': true,
          'accountType': null,
          'profileComplete': false,
          'profileCompleted': false,
          'notificationsEnabled': true,
        });
      }

      print('--- [GOOGLE AUTH] Google sign-in completed for ${user.uid}');
      return userCredential;
    } on FirebaseAuthException catch (error, stackTrace) {
      print('--- [GOOGLE AUTH] FirebaseAuthException: ${error.code}');
      print('--- [GOOGLE AUTH] Stack trace: $stackTrace');
      switch (error.code) {
        case 'account-exists-with-different-credential':
          throw const GoogleAuthException(
            'An account already exists with the same email using a different sign-in method.',
          );
        case 'invalid-credential':
          throw const GoogleAuthException(
            'The Google credential is invalid. Please try again.',
          );
        case 'network-request-failed':
          throw const GoogleAuthException(
            'Network error while signing in with Google. Please check your connection.',
          );
        default:
          throw GoogleAuthException(
            error.message ??
                'Google sign-in failed. Please try again in a moment.',
          );
      }
    } catch (error, stackTrace) {
      print('--- [GOOGLE AUTH] Unexpected error: $error');
      print('--- [GOOGLE AUTH] Stack trace: $stackTrace');
      if (error is GoogleAuthException) {
        rethrow;
      }
      throw const GoogleAuthException(
        'Google sign-in failed. Please try again.',
      );
    }
  }

  Future<void> signOut() async {
    print('--- [GOOGLE AUTH] Signing out Google session');
    await _googleSignIn.signOut();
  }
}
