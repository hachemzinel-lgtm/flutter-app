import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
    required UserType userType,
  }) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = userCredential.user!.uid;

    final newUser = UserModel(
      id: uid,
      email: email,
      name: name,
      phone: phone,
      userType: userType,
    );

    // Create user document in Firestore
    await _firestore.collection('users').doc(uid).set(newUser.toJson());

    // Send email verification
    await userCredential.user!.sendEmailVerification();
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<UserType> getUserType(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists || doc.data() == null) return UserType.client;
    final data = doc.data()!;
    return UserModel.parseUserType(data['userType'] ?? data['accountType'] ?? 'client');
  }
}
