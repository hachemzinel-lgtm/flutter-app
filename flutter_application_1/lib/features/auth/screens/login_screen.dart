import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/primary_button.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';

/// Reasonable email regex — permits all common forms without being RFC-5322
/// pedantic. We also trust Firebase's own `invalid-email` error as a backstop.
final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.errorRed,
        ),
      );
  }

  Future<void> _handleLogin() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(authServiceProvider).signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      if (mounted) context.go('/splash');
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleLogin() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(authServiceProvider).signInWithGoogle();
      if (mounted) context.go('/splash');
    } on AuthException catch (e) {
      if (e.code != 'cancelled') _showError(e.message);
    } catch (_) {
      _showError('Google sign-in failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: AbsorbPointer(
        absorbing: _isLoading,
        child: Padding(
          padding: AppSpacing.pagePadding,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    'NearWork',
                    style: AppTextStyles.headingSmall
                        .copyWith(color: AppColors.accentBlue),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                Text(
                  'Welcome Back',
                  style: AppTextStyles.headingLarge.copyWith(fontSize: 32),
                ),
                const SizedBox(height: AppSpacing.s),
                Text(
                  'Enter your credentials to access your workspace.',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xxl),

                _buildLabel('EMAIL ADDRESS'),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: _inputDecoration(
                      'name@example.com', Icons.email_outlined),
                  validator: (val) {
                    final v = (val ?? '').trim();
                    if (v.isEmpty) return 'Please enter your email';
                    if (!_emailRegex.hasMatch(v)) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.l),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildLabel('PASSWORD'),
                    GestureDetector(
                      onTap: _isLoading
                          ? null
                          : () => context.push('/forgot-password'),
                      child: Text(
                        'Forgot password?',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.accentBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  autofillHints: const [AutofillHints.password],
                  decoration:
                      _inputDecoration('••••••••', Icons.lock_outline).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: AppColors.softGray,
                      ),
                      onPressed: () => setState(
                          () => _isPasswordVisible = !_isPasswordVisible),
                    ),
                  ),
                  validator: (val) => val == null || val.length < 6
                      ? 'Min 6 characters'
                      : null,
                  onFieldSubmitted: (_) => _handleLogin(),
                ),
                const SizedBox(height: AppSpacing.xxl),

                PrimaryButton(
                  text: _isLoading ? 'Signing in…' : 'Login',
                  onPressed: _isLoading ? null : _handleLogin,
                ),
                const SizedBox(height: AppSpacing.l),

                const _DividerWithText(text: 'OR CONTINUE WITH'),
                const SizedBox(height: AppSpacing.l),

                _SocialButton(
                  text: 'Continue with Google',
                  onPressed: _isLoading ? null : _handleGoogleLogin,
                ),

                const Spacer(),
                Center(
                  child: GestureDetector(
                    onTap: _isLoading
                        ? null
                        : () => context.push('/account-type'),
                    child: RichText(
                      text: TextSpan(
                        text: "Don't have an account? ",
                        style: AppTextStyles.bodyMedium,
                        children: [
                          TextSpan(
                            text: 'Sign up',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.accentBlue,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          letterSpacing: 1.1,
          fontWeight: FontWeight.w700,
          color: AppColors.textLight,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.softGray, size: 20),
      filled: true,
      fillColor: AppColors.softGray.withValues(alpha: 0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 20),
    );
  }
}

class _DividerWithText extends StatelessWidget {
  final String text;
  const _DividerWithText({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: Divider(color: AppColors.softGray.withValues(alpha: 0.2))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
          child: Text(
            text,
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
              color: AppColors.softGray.withValues(alpha: 0.6),
            ),
          ),
        ),
        Expanded(
            child: Divider(color: AppColors.softGray.withValues(alpha: 0.2))),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;

  const _SocialButton({
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppSpacing.buttonHeight,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.softGray.withValues(alpha: 0.2)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.g_mobiledata, size: 32, color: Colors.red),
            const SizedBox(width: AppSpacing.s),
            Text(
              text,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
