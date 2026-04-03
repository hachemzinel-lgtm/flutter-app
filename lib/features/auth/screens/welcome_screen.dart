import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../widgets/google_sign_in_button.dart';
import '../services/google_auth_service.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _isGoogleLoading = false;
  final GoogleAuthService _googleAuthService = GoogleAuthService();

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);
    try {
      final credential = await _googleAuthService.signInWithGoogle();
      if (credential != null && mounted) {
        // App router will handle navigation strictly based on Auth state + Firestore doc state
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
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.pagePadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Icon(
                Icons.work_outline_rounded,
                size: 100,
                color: AppColors.accentBlue,
              ),
              const SizedBox(height: AppSpacing.l),
              Text(
                'NearWork',
                textAlign: TextAlign.center,
                style: AppTextStyles.headingLarge.copyWith(
                  color: AppColors.primaryNavy,
                  fontSize: 36,
                ),
              ),
              const SizedBox(height: AppSpacing.s),
              Text(
                'Work better, Together',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textLight,
                ),
              ),
              const Spacer(),
              PrimaryButton(
                text: 'Sign Up',
                onPressed: () => context.push('/signup'),
              ),
              const SizedBox(height: AppSpacing.m),
              OutlinedButton(
                onPressed: () => context.push('/login'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
                  side: const BorderSide(color: AppColors.accentBlue),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppSpacing.borderRadius,
                    ),
                  ),
                ),
                child: Text(
                  'Login',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.accentBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.l),
              Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: AppColors.softGray.withValues(alpha: 0.2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.m,
                    ),
                    child: Text(
                      'OR',
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.softGray,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: AppColors.softGray.withValues(alpha: 0.2),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.l),
              GoogleSignInButton(
                text: 'Continue with Google',
                isLoading: _isGoogleLoading,
                onPressed: _handleGoogleSignIn,
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}
