import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_application_1/views/app_colors.dart';
import 'package:flutter_application_1/views/app_spacing.dart';
import 'package:flutter_application_1/views/app_text_styles.dart';
import 'package:flutter_application_1/routes/route_paths.dart';
import 'package:flutter_application_1/views/auth_action_state.dart';
import 'package:flutter_application_1/providers/email_verification_controller.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key, this.email});

  final String? email;

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  Timer? _cooldownTimer;
  int _cooldownSeconds = 0;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _cooldownSeconds = 60);
    _cooldownTimer?.cancel();
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

  Future<void> _resend() async {
    await ref.read(emailVerificationControllerProvider.notifier).resendEmail();
    if (mounted) {
      _startCooldown();
    }
  }

  Future<void> _confirmVerification() async {
    final route = await ref
        .read(emailVerificationControllerProvider.notifier)
        .confirmVerification();
    if (mounted && route != null) {
      context.go(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthActionState>(emailVerificationControllerProvider, (
      previous,
      next,
    ) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
      if (next.infoMessage != null &&
          next.infoMessage != previous?.infoMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.infoMessage!),
            backgroundColor: AppColors.availableGreen,
          ),
        );
      }
    });

    final state = ref.watch(emailVerificationControllerProvider);
    final email =
        widget.email ??
        FirebaseAuth.instance.currentUser?.email ??
        'your email';

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
              Icons.mark_email_read_outlined,
              size: 96,
              color: AppColors.accentBlue,
            ),
            const SizedBox(height: AppSpacing.l),
            Text(
              'Verify Your Email',
              textAlign: TextAlign.center,
              style: AppTextStyles.headingLarge,
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              'We sent a verification email to $email.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              'Click the link in the email to continue.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.softGray,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            SizedBox(
              height: AppSpacing.buttonHeight,
              child: ElevatedButton(
                onPressed: state.isLoading ? null : _confirmVerification,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppSpacing.borderRadius,
                    ),
                  ),
                ),
                child: state.isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Text("I've verified my email"),
              ),
            ),
            const SizedBox(height: AppSpacing.m),
            SizedBox(
              height: AppSpacing.buttonHeight,
              child: OutlinedButton(
                onPressed: state.isLoading || _cooldownSeconds > 0
                    ? null
                    : _resend,
                child: Text(
                  _cooldownSeconds > 0
                      ? 'Resend email ($_cooldownSeconds)'
                      : 'Resend email',
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            TextButton(
              onPressed: state.isLoading
                  ? null
                  : () async {
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        context.go(AppRoutes.welcome);
                      }
                    },
              child: const Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }
}
