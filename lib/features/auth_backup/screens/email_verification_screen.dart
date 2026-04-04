import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../providers/auth_provider.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  Timer? _pollingTimer;
  Timer? _cooldownTimer;
  bool _isChecking = false;
  bool _isResending = false;
  int _cooldownSeconds = 0;

  final _codeController = TextEditingController();
  bool _isVerifyingManualCode = false;

  @override
  void initState() {
    super.initState();
    // Fire off the 6-digit explicit verification code to the assigned email
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final email = ref.read(authServiceProvider).currentUser?.email;
      if (email != null) {
        ref.read(authServiceProvider).sendVerificationCode(email);
      }
    });

    _pollingTimer = Timer.periodic(
      const Duration(seconds: 4),
      (_) => _refreshVerificationStatus(),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    _pollingTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshVerificationStatus() async {
    if (_isChecking) return;
    setState(() => _isChecking = true);
    try {
      final user = await ref.read(authServiceProvider).reloadUser();
      if (user?.emailVerified == true) {
        _pollingTimer?.cancel();
        if (mounted) context.go('/account-type');
      }
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _verifyManualCode() async {
    final email = ref.read(authServiceProvider).currentUser?.email;
    final code = _codeController.text.trim();
    if (email == null || code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the 6-digit code.'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    setState(() => _isVerifyingManualCode = true);
    try {
      final success = await ref
          .read(authServiceProvider)
          .verifyCode(email, code);
      if (success) {
        _pollingTimer?.cancel();
        if (mounted) context.go('/account-type');
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid verification code.'),
              backgroundColor: AppColors.errorRed,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isVerifyingManualCode = false);
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (_cooldownSeconds > 0) return;

    setState(() => _isResending = true);
    try {
      final email = ref.read(authServiceProvider).currentUser?.email;
      if (email != null) {
        // Send both the Firebase link and the 6-Digit code
        await ref.read(authServiceProvider).resendVerificationEmail();
        await ref.read(authServiceProvider).sendVerificationCode(email);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification sent! Please check your inbox.'),
          backgroundColor: AppColors.availableGreen,
        ),
      );

      setState(() => _cooldownSeconds = 45);
      _cooldownTimer?.cancel();
      _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted || _cooldownSeconds <= 1) {
          timer.cancel();
          if (mounted) setState(() => _cooldownSeconds = 0);
          return;
        }
        setState(() => _cooldownSeconds -= 1);
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: AppColors.errorRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = ref.read(authServiceProvider).currentUser?.email ?? '';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.pagePadding,
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.9,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryNavy,
                        AppColors.accentBlue.withValues(alpha: 0.9),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(
                    Icons.mark_email_unread_outlined,
                    size: 56,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                Text(
                  'Verify Your Email',
                  style: AppTextStyles.headingLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.m),
                Text(
                  email,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.accentBlue,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.m),
                Text(
                  'Enter the 6-digit code sent to your email, or click the link we sent you to proceed automatically.',
                  style: AppTextStyles.caption,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xxl),

                // Writing Label for Verification Code
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'VERIFICATION CODE',
                    style: AppTextStyles.labelSmall.copyWith(
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textLight,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.s),
                TextFormField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.headingMedium.copyWith(letterSpacing: 8),
                  decoration: InputDecoration(
                    hintText: '• • • • • •',
                    hintStyle: AppTextStyles.headingMedium.copyWith(
                      letterSpacing: 8,
                      color: AppColors.softGray,
                    ),
                    filled: true,
                    counterText: '',
                    fillColor: AppColors.softGray.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppSpacing.borderRadius,
                      ),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 20),
                  ),
                ),

                const SizedBox(height: AppSpacing.l),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isVerifyingManualCode
                        ? null
                        : _verifyManualCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.borderRadius,
                        ),
                      ),
                    ),
                    child: _isVerifyingManualCode
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            "Verify Code",
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: AppSpacing.m),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: _isChecking ? null : _refreshVerificationStatus,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primaryNavy),
                      foregroundColor: AppColors.primaryNavy,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.borderRadius,
                        ),
                      ),
                    ),
                    child: _isChecking
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.4),
                          )
                        : const Text(
                            "I clicked the email link instead",
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),

                const Spacer(),
                const SizedBox(height: AppSpacing.m),
                TextButton(
                  onPressed: _isResending ? null : _resendVerificationEmail,
                  child: _isResending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          _cooldownSeconds > 0
                              ? 'Resend verification in ${_cooldownSeconds}s'
                              : 'Resend verification',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.accentBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
                TextButton(
                  onPressed: () async {
                    _pollingTimer?.cancel();
                    await ref.read(authServiceProvider).signOut();
                    if (!context.mounted) return;
                    context.go('/login');
                  },
                  child: Text(
                    'Use a different account',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.softGray,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
