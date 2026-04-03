import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/route_paths.dart';
import '../../providers/auth_action_state.dart';
import '../../providers/login_controller.dart';
import '../../providers/signup_controller.dart';
import '../../widgets/google_sign_in_button.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthActionState>(signupControllerProvider, (previous, next) {
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

    ref.listen<AuthActionState>(loginControllerProvider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    });

    final signupState = ref.watch(signupControllerProvider);
    final googleState = ref.watch(loginControllerProvider);
    final isLoading = signupState.isLoading || googleState.isLoading;

    Future<void> submit() async {
      if (!_formKey.currentState!.validate()) {
        return;
      }

      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final route = await ref
          .read(signupControllerProvider.notifier)
          .signUp(email: email, password: password);
      if (context.mounted && route != null) {
        context.go(route, extra: email);
      }
    }

    Future<void> handleGoogleSignIn() async {
      final route = await ref
          .read(loginControllerProvider.notifier)
          .signInWithGoogle();
      if (context.mounted && route != null) {
        context.go(route);
      }
    }

    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        padding: AppSpacing.pagePadding,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Create Account', style: AppTextStyles.headingLarge),
              const SizedBox(height: AppSpacing.s),
              Text(
                'Create your NearWork account with your email and password.',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xl),
              _fieldLabel('Email'),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDecoration(
                  'name@example.com',
                  Icons.email_outlined,
                ),
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (email.isEmpty) {
                    return 'Email is required';
                  }
                  final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                  if (!emailRegex.hasMatch(email)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.l),
              _fieldLabel('Password'),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration:
                    _inputDecoration(
                      'Minimum 6 characters',
                      Icons.lock_outline,
                    ).copyWith(
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                validator: (value) {
                  final password = value?.trim() ?? '';
                  if (password.isEmpty) {
                    return 'Password is required';
                  }
                  if (password.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.l),
              _fieldLabel('Confirm Password'),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration:
                    _inputDecoration(
                      'Re-enter your password',
                      Icons.lock_outline,
                    ).copyWith(
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(
                            () => _obscureConfirmPassword =
                                !_obscureConfirmPassword,
                          );
                        },
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                validator: (value) {
                  final confirm = value?.trim() ?? '';
                  if (confirm.isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (confirm != _passwordController.text.trim()) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.m),
              CheckboxListTile(
                value: _acceptTerms,
                onChanged: isLoading
                    ? null
                    : (value) => setState(() => _acceptTerms = value ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'I agree to the terms and conditions',
                  style: AppTextStyles.bodyMedium,
                ),
              ),
              const SizedBox(height: AppSpacing.l),
              SizedBox(
                width: double.infinity,
                height: AppSpacing.buttonHeight,
                child: ElevatedButton(
                  onPressed: isLoading ? null : submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppSpacing.borderRadius,
                      ),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Sign Up',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.l),
              Row(
                children: [
                  Expanded(child: Divider(color: AppColors.borderLight)),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.m,
                    ),
                    child: Text('OR', style: AppTextStyles.labelSmall),
                  ),
                  Expanded(child: Divider(color: AppColors.borderLight)),
                ],
              ),
              const SizedBox(height: AppSpacing.l),
              GoogleSignInButton(
                text: 'Continue with Google',
                isLoading: isLoading,
                onPressed: handleGoogleSignIn,
              ),
              const SizedBox(height: AppSpacing.l),
              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: isLoading
                      ? null
                      : () => context.go(AppRoutes.login),
                  child: const Text('Already have an account? Sign In'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: AppColors.backgroundSecondary,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
        borderSide: BorderSide.none,
      ),
    );
  }
}
