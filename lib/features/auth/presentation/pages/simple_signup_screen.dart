import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../test_firebase.dart';

class SimpleSignupScreen extends StatefulWidget {
  const SimpleSignupScreen({super.key});

  @override
  State<SimpleSignupScreen> createState() => _SimpleSignupScreenState();
}

class _SimpleSignupScreenState extends State<SimpleSignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    setState(() => _loading = true);

    try {
      print('--- SIMPLE SIGNUP: Starting');
      final result = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      print('--- SIMPLE SIGNUP: SUCCESS ${result.user?.uid}');

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Account created!')));
      context.go('/debug-auth/home');
    } on FirebaseAuthException catch (error) {
      print('--- SIMPLE SIGNUP: ERROR ${error.code} ${error.message}');
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message ?? error.code)));
    } catch (error) {
      print('--- SIMPLE SIGNUP: UNKNOWN ERROR $error');
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Simple Signup')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _signUp,
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text('Sign Up'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: FirebaseAuthTest.testSignup,
              child: const Text('Run Fixed Firebase Signup Test'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go('/debug-auth/login'),
              child: const Text('Go to simple login'),
            ),
          ],
        ),
      ),
    );
  }
}
