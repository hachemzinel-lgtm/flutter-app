import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/models/user_model.dart';
import '../../../core/widgets/primary_button.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';

/// Reasonable email regex — permits all common forms without being RFC-5322
/// pedantic. Firebase's own `invalid-email` error is the final backstop.
final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Phone validator: accepts E.164 (+<country><number>) with 8–15 digits.
/// Reject ambiguous local formats — the phone OTP step requires E.164 and
/// failing early gives a better error than "invalid-phone-number" from
/// Firebase after the account is already created.
final _phoneRegex = RegExp(r'^\+[1-9]\d{7,14}$');

class SignUpScreen extends ConsumerStatefulWidget {
  final UserType userType;

  const SignUpScreen({
    super.key,
    required this.userType,
  });

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
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

  /// Strip spaces, dashes, and parens so the phone field survives
  /// copy-paste from places like WhatsApp's "+216 12 345 678".
  String _normalisePhone(String raw) =>
      raw.replaceAll(RegExp(r'[\s\-().]'), '').trim();

  Future<void> _handleSignUp() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final phone = _normalisePhone(_phoneController.text);

    try {
      await ref.read(authServiceProvider).signUp(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            phone: phone,
            password: _passwordController.text,
            userType: widget.userType,
          );
      if (!mounted) return;
      // Account exists — now go verify the phone. We pass the E.164
      // number via `extra` so the OTP screen doesn't need to refetch it.
      context.go('/otp-verification', extra: phone);
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('Something went wrong. Please try again.');
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
        child: SingleChildScrollView(
          padding: AppSpacing.pagePadding,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create Account',
                  style: AppTextStyles.headingLarge.copyWith(fontSize: 32),
                ),
                const SizedBox(height: AppSpacing.s),
                Text(
                  'Join NearWork as a ${widget.userType.displayName}',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xxl),
                _buildLabel('FULL NAME'),
                TextFormField(
                  controller: _nameController,
                  autofillHints: const [AutofillHints.name],
                  decoration: _inputDecoration(
                      'Enter your full name', Icons.person_outline),
                  validator: (val) {
                    final v = (val ?? '').trim();
                    if (v.isEmpty) return 'Name is required';
                    if (v.length < 2) return 'Please enter your full name';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.l),
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
                _buildLabel('PHONE NUMBER'),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  decoration: _inputDecoration(
                      '+216 -- --- ---', Icons.phone_outlined),
                  validator: (val) {
                    final v = _normalisePhone(val ?? '');
                    if (v.isEmpty) return 'Phone number is required';
                    if (!_phoneRegex.hasMatch(v)) {
                      return 'Use international format (e.g. +21612345678)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.l),
                _buildLabel('PASSWORD'),
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: _inputDecoration('••••••••', Icons.lock_outline)
                      .copyWith(
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
                ),
                const SizedBox(height: AppSpacing.xxl),
                PrimaryButton(
                  text: _isLoading ? 'Creating account…' : 'Sign Up',
                  onPressed: _isLoading ? null : _handleSignUp,
                ),
                const SizedBox(height: AppSpacing.l),
                Center(
                  child: GestureDetector(
                    onTap: _isLoading ? null : () => context.push('/login'),
                    child: RichText(
                      text: TextSpan(
                        text: "Already have an account? ",
                        style: AppTextStyles.bodyMedium,
                        children: [
                          TextSpan(
                            text: 'Login',
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
