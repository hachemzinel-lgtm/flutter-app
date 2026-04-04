import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthTest {
  static Future<void> testSignup() async {
    try {
      print('--- TEST: Starting signup test');

      final result = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: 'test@test.com',
        password: 'test123456',
      );

      print('--- TEST: Signup SUCCESS!');
      print('--- TEST: User ID: ${result.user?.uid}');
      print('--- TEST: Email: ${result.user?.email}');
    } on FirebaseAuthException catch (error) {
      print('--- TEST: Signup FAILED');
      print('--- TEST: Error code: ${error.code}');
      print('--- TEST: Error message: ${error.message}');
    } catch (error) {
      print('--- TEST: Unknown error: $error');
    }
  }

  static Future<void> testLogin() async {
    try {
      print('--- TEST: Starting login test');

      final result = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: 'test@test.com',
        password: 'test123456',
      );

      print('--- TEST: Login SUCCESS!');
      print('--- TEST: User ID: ${result.user?.uid}');
    } on FirebaseAuthException catch (error) {
      print('--- TEST: Login FAILED');
      print('--- TEST: Error code: ${error.code}');
      print('--- TEST: Error message: ${error.message}');
    } catch (error) {
      print('--- TEST: Unknown login error: $error');
    }
  }
}
