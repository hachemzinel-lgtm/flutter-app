import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/route_paths.dart';
import '../../providers/auth_action_state.dart';
import '../../providers/auth_providers.dart';
import '../../providers/email_verification_controller.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key, this.email});

  final String? email;

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  Timer? _pollingTimer;
  Timer? _cooldownTimer;
  int _cooldown = 0;

  @override
  void initState() {
    super.initState();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      final route = await ref
          .read(emailVerificationControllerProvider.notifier)
          .confirmVerification();
      if (mounted && route != null) {
        _pollingTimer?.cancel();
        context.go(route);
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthActionState>(emailVerificationControllerProvider, (
      previous,
      next,
    ) {
      final messenger = ScaffoldMessenger.of(context);
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
      if (next.infoMessage != null &&
          next.infoMessage != previous?.infoMessage) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(next.infoMessage!),
            backgroundColor: AppColors.availableGreen,
          ),
        );
      }
    });

    final state = ref.watch(emailVerificationControllerProvider);
    final email = widget.email ?? ref.watch(currentUserProvider)?.email ?? '';

    Future<void> resend() async {
      if (_cooldown > 0) {
        return;
      }
      await ref
          .read(emailVerificationControllerProvider.notifier)
          .resendEmail();
      if (!mounted) {
        return;
      }
      setState(() => _cooldown = 60);
      _cooldownTimer?.cancel();
      _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted || _cooldown <= 1) {
          timer.cancel();
          if (mounted) {
            setState(() => _cooldown = 0);
          }
          return;
        }
        setState(() => _cooldown -= 1);
      });
    }

    Future<void> confirm() async {
      final route = await ref
          .read(emailVerificationControllerProvider.notifier)
          .confirmVerification();
      if (context.mounted && route != null) {
        context.go(route);
      }
    }

    Future<void> signOut() async {
      await ref.read(authRepositoryProvider).signOut();
      if (context.mounted) {
        context.go(AppRoutes.welcome);
      }
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(automaticallyImplyLeading: false),
        body: Padding(
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
                "We've sent a verification link to $email",
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.s),
              Text(
                'Please check your inbox and click the verification link.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium,
              ),
              const Spacer(),
              SizedBox(
                height: AppSpacing.buttonHeight,
                child: OutlinedButton(
                  onPressed: state.isLoading || _cooldown > 0 ? null : resend,
                  child: Text(
                    _cooldown > 0
                        ? 'Resend Email ($_cooldown)'
                        : 'Resend Email',
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.m),
              SizedBox(
                height: AppSpacing.buttonHeight,
                child: ElevatedButton(
                  onPressed: state.isLoading ? null : confirm,
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
                      : const Text("I've Verified My Email"),
                ),
              ),
              const SizedBox(height: AppSpacing.s),
              TextButton(
                onPressed: state.isLoading ? null : signOut,
                child: const Text('Sign Out'),
              ),
              const SizedBox(height: AppSpacing.l),
            ],
          ),
        ),
      ),
    );
  }
}
