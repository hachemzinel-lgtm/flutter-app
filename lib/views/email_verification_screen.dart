import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_application_1/providers/auth_providers.dart';
import 'package:flutter_application_1/routes/route_paths.dart';
import 'package:flutter_application_1/views/app_colors.dart';
import 'package:flutter_application_1/views/app_spacing.dart';
import 'package:flutter_application_1/views/app_text_styles.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key, this.email});

  final String? email;

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen>
    with WidgetsBindingObserver {
  Timer? _verificationTimer;
  Timer? _cooldownTimer;
  bool _isChecking = false;
  bool _isResending = false;
  int _cooldownSeconds = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _verificationTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _checkVerification(autoTriggered: true);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _verificationTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkVerification(autoTriggered: true);
    }
  }

  Future<void> _resendEmail() async {
    if (_isResending || _cooldownSeconds > 0) {
      return;
    }

    setState(() => _isResending = true);
    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Verification email sent.')));
      _startCooldown();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to resend verification email: $error'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _cooldownSeconds = 60);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _cooldownSeconds <= 1) {
        timer.cancel();
        if (mounted) {
          setState(() => _cooldownSeconds = 0);
        }
        return;
      }
      setState(() => _cooldownSeconds -= 1);
    });
  }

  Future<void> _checkVerification({required bool autoTriggered}) async {
    if (_isChecking) {
      return;
    }

    setState(() => _isChecking = true);
    try {
      final currentUser =
          await ref.read(authProvider.notifier).refreshAuthState();
      final emailVerified = currentUser?.emailVerified == true;

      if (!emailVerified) {
        if (!autoTriggered && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email not verified yet. Please check your inbox.'),
            ),
          );
        }
        return;
      }

      if (currentUser != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .set({
              'emailVerified': true,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
      }

      _verificationTimer?.cancel();
      if (mounted) {
        context.goNamed(AppRoutes.homeName);
      }
    } catch (error) {
      if (!autoTriggered && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to check verification state: $error'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final email =
        widget.email ??
        FirebaseAuth.instance.currentUser?.email ??
        'your email address';

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(automaticallyImplyLeading: false),
      body: SingleChildScrollView(
        padding: AppSpacing.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.xl),
            const Icon(
              Icons.mark_email_unread_outlined,
              size: 96,
              color: AppColors.accentBlue,
            ),
            const SizedBox(height: AppSpacing.l),
            Text(
              'Waiting for verification',
              textAlign: TextAlign.center,
              style: AppTextStyles.headingLarge,
            ),
            const SizedBox(height: AppSpacing.m),
            Text(
              'We sent a verification email to $email.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              'Please check your email and click the verification link',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.softGray,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            SizedBox(
              height: AppSpacing.buttonHeight,
              child: ElevatedButton(
                onPressed:
                    _isChecking
                        ? null
                        : () => _checkVerification(autoTriggered: false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentBlue,
                  foregroundColor: Colors.white,
                ),
                child:
                    _isChecking
                        ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                        : const Text('I completed authentication'),
              ),
            ),
            const SizedBox(height: AppSpacing.m),
            SizedBox(
              height: AppSpacing.buttonHeight,
              child: OutlinedButton(
                onPressed:
                    (_isResending || _cooldownSeconds > 0)
                        ? null
                        : _resendEmail,
                child: Text(
                  _cooldownSeconds > 0
                      ? 'Resend Email ($_cooldownSeconds)'
                      : 'Resend Email',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
