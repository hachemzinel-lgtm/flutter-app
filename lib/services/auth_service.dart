import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter_application_1/models/user_model.dart';
import 'package:flutter_application_1/services/auth_repository.dart';
import 'package:flutter_application_1/services/user_repository.dart';

class AuthService {
  AuthService({
    required AuthRepository authRepository,
    required UserRepository userRepository,
    FirebaseFirestore? firestore,
  }) : _authRepository = authRepository,
       _userRepository = userRepository,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final AuthRepository _authRepository;
  final UserRepository _userRepository;
  final FirebaseFirestore _firestore;

  Stream<User?> get authStateChanges => _authRepository.authStateChanges;
  User? get currentUser => _authRepository.currentUser;

  Future<void> signUp({required String email, required String password}) async {
    await _authRepository.signUpWithEmailPassword(email, password);
  }

  Future<void> signIn({required String email, required String password}) async {
    await _authRepository.signInWithEmailPassword(email, password);
  }

  Future<void> signOut() => _authRepository.signOut();

  Future<void> resetPassword(String email) {
    return _authRepository.sendPasswordResetEmail(email);
  }

  Future<void> resendVerificationEmail() {
    return _authRepository.sendEmailVerification();
  }

  Future<void> sendVerificationCode(String email) async {
    print(
      '--- [AUTH SERVICE] Deprecated sendVerificationCode called for $email. Using Firebase verification email instead.',
    );
    await _authRepository.sendEmailVerification();
  }

  Future<bool> verifyCode(String email, String code) async {
    print(
      '--- [AUTH SERVICE] Deprecated manual verification called for $email. Reloading Firebase user instead.',
    );
    await _authRepository.reloadUser();
    return _authRepository.isEmailVerified();
  }

  Future<User?> reloadUser() async {
    await _authRepository.reloadUser();
    return _authRepository.currentUser;
  }

  Future<void> setupProfile(UserModel userModel) async {
    final uid = _authRepository.currentUser?.uid;
    if (uid == null) {
      throw const AuthRepositoryException(
        'You must be signed in to complete profile setup.',
      );
    }

    final data = userModel.toJson()
      ..['updatedAt'] = FieldValue.serverTimestamp()
      ..['profileComplete'] = true
      ..['emailVerified'] = _authRepository.currentUser?.emailVerified ?? false;

    await _userRepository.updateUserDocument(uid, data);
  }

  Future<UserType?> getUserType(String uid) async {
    final data = await _userRepository.getUserDocument(uid);
    if (data == null) {
      return null;
    }
    return UserModel.parseUserType(
      data['accountType']?.toString() ??
          data['userType']?.toString() ??
          'client',
    );
  }

  Future<bool> isAdminUser(String uid) async {
    final userDoc = await _firestore.collection('users').doc(uid).get();
    return userDoc.data()?['accountType'] == 'admin';
  }
}
