import 'package:firebase_auth/firebase_auth.dart';

class AuthRepositoryException implements Exception {
  const AuthRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract class AuthRepository {
  Stream<User?> get authStateChanges;
  User? get currentUser;

  Future<User?> signUpWithEmailPassword(String email, String password);
  Future<User?> signInWithEmailPassword(String email, String password);
  Future<void> sendEmailVerification();
  Future<void> sendPasswordResetEmail(String email);
  Future<void> signOut();
  Future<User?> signInWithGoogle();
  Future<bool> isEmailVerified();
  Future<void> reloadUser();
}
