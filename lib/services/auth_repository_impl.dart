import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter_application_1/services/services_google_auth_service.dart';
import 'package:flutter_application_1/services/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({FirebaseAuth? auth, GoogleAuthService? googleAuthService})
    : _auth = auth ?? FirebaseAuth.instance,
      _googleAuthService = googleAuthService ?? GoogleAuthService();

  final FirebaseAuth _auth;
  final GoogleAuthService _googleAuthService;

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Future<User?> signUpWithEmailPassword(String email, String password) async {
    print('--- [AUTH REPOSITORY] Starting sign-up for $email');
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('--- [AUTH REPOSITORY] User created: ${credential.user?.uid}');
      await credential.user?.sendEmailVerification();
      print('--- [AUTH REPOSITORY] Verification email sent');
      return credential.user;
    } on FirebaseAuthException catch (error, stackTrace) {
      print(
        '--- [AUTH REPOSITORY] Sign-up FirebaseAuthException: ${error.code}',
      );
      print('--- [AUTH REPOSITORY] Stack trace: $stackTrace');
      throw AuthRepositoryException(_mapAuthError(error));
    } catch (error, stackTrace) {
      print('--- [AUTH REPOSITORY] Unexpected sign-up error: $error');
      print('--- [AUTH REPOSITORY] Stack trace: $stackTrace');
      throw const AuthRepositoryException('Signup failed. Please try again.');
    }
  }

  @override
  Future<User?> signInWithEmailPassword(String email, String password) async {
    print('--- [AUTH REPOSITORY] Starting sign-in for $email');
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('--- [AUTH REPOSITORY] Sign-in success: ${credential.user?.uid}');
      print(
        '--- [AUTH REPOSITORY] Email verified: ${credential.user?.emailVerified}',
      );
      return credential.user;
    } on FirebaseAuthException catch (error, stackTrace) {
      print(
        '--- [AUTH REPOSITORY] Sign-in FirebaseAuthException: ${error.code}',
      );
      print('--- [AUTH REPOSITORY] Stack trace: $stackTrace');
      throw AuthRepositoryException(_mapAuthError(error));
    } catch (error, stackTrace) {
      print('--- [AUTH REPOSITORY] Unexpected sign-in error: $error');
      print('--- [AUTH REPOSITORY] Stack trace: $stackTrace');
      throw const AuthRepositoryException('Sign in failed. Please try again.');
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    print('--- [AUTH REPOSITORY] Sending email verification');
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw const AuthRepositoryException(
          'No authenticated user found to verify.',
        );
      }
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (error, stackTrace) {
      print(
        '--- [AUTH REPOSITORY] Send verification FirebaseAuthException: ${error.code}',
      );
      print('--- [AUTH REPOSITORY] Stack trace: $stackTrace');
      throw AuthRepositoryException(_mapAuthError(error));
    } catch (error, stackTrace) {
      print(
        '--- [AUTH REPOSITORY] Unexpected verification email error: $error',
      );
      print('--- [AUTH REPOSITORY] Stack trace: $stackTrace');
      if (error is AuthRepositoryException) {
        rethrow;
      }
      throw const AuthRepositoryException(
        'Unable to send verification email right now.',
      );
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    print('--- [AUTH REPOSITORY] Sending password reset email to $email');
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (error, stackTrace) {
      print('--- [AUTH REPOSITORY] Reset password error: ${error.code}');
      print('--- [AUTH REPOSITORY] Stack trace: $stackTrace');
      throw AuthRepositoryException(_mapAuthError(error));
    } catch (error, stackTrace) {
      print('--- [AUTH REPOSITORY] Unexpected reset password error: $error');
      print('--- [AUTH REPOSITORY] Stack trace: $stackTrace');
      throw const AuthRepositoryException(
        'Unable to send a password reset email right now.',
      );
    }
  }

  @override
  Future<void> signOut() async {
    print('--- [AUTH REPOSITORY] Signing out user');
    try {
      await _googleAuthService.signOut();
    } catch (_) {
      print('--- [AUTH REPOSITORY] Google sign-out skipped or failed silently');
    }
    await _auth.signOut();
  }

  @override
  Future<User?> signInWithGoogle() async {
    print('--- [AUTH REPOSITORY] Delegating to Google auth service');
    try {
      final credential = await _googleAuthService.signInWithGoogle();
      return credential?.user;
    } on GoogleAuthException catch (error, stackTrace) {
      print('--- [AUTH REPOSITORY] GoogleAuthException: $error');
      print('--- [AUTH REPOSITORY] Stack trace: $stackTrace');
      throw AuthRepositoryException(error.message);
    } catch (error, stackTrace) {
      print('--- [AUTH REPOSITORY] Unexpected Google sign-in error: $error');
      print('--- [AUTH REPOSITORY] Stack trace: $stackTrace');
      throw const AuthRepositoryException(
        'Google sign-in failed. Please try again.',
      );
    }
  }

  @override
  Future<bool> isEmailVerified() async {
    print('--- [AUTH REPOSITORY] Checking email verification status');
    return _auth.currentUser?.emailVerified ?? false;
  }

  @override
  Future<void> reloadUser() async {
    print('--- [AUTH REPOSITORY] Reloading current user');
    await _auth.currentUser?.reload();
  }

  String _mapAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'This email is already registered';
      case 'invalid-email':
        return 'Please enter a valid email address';
      case 'operation-not-allowed':
        return 'Email and password sign-in is not enabled for this app';
      case 'weak-password':
        return 'Password must be at least 6 characters';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect password';
      case 'network-request-failed':
        return 'Network error. Please check your connection and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      default:
        return error.message ?? 'Authentication failed. Please try again.';
    }
  }
}
