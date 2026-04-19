import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';

/// Reasonable email regex — same shape as the signup/login validators.
final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await ref
          .read(authServiceProvider)
          .resetPassword(_emailController.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('If an account exists, a reset link has been sent.')),
      );
      context.pop();
    } on AuthException catch (e) {
      // Deliberately do NOT leak whether the email exists — that's an
      // account-enumeration vector. Firebase already soft-fails silently
      // for unknown emails, so the only codes we really surface here are
      // `invalid-email` and network errors.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.errorRed),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not send reset link. Please try again.'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(elevation: 0, backgroundColor: Colors.transparent),
      body: AbsorbPointer(
        absorbing: _isLoading,
        child: Padding(
          padding: AppSpacing.pagePadding,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Forgot Password',
                  style: AppTextStyles.headingLarge.copyWith(fontSize: 32),
                ),
                const SizedBox(height: AppSpacing.s),
                Text(
                  'Enter your email to receive a password reset link.',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xxl),
                Text(
                  'EMAIL ADDRESS',
                  style: AppTextStyles.labelSmall
                      .copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.s),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: InputDecoration(
                    hintText: 'name@example.com',
                    prefixIcon: const Icon(Icons.email_outlined),
                    filled: true,
                    fillColor: AppColors.softGray.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.borderRadius),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (val) {
                    final v = (val ?? '').trim();
                    if (v.isEmpty) return 'Please enter your email';
                    if (!_emailRegex.hasMatch(v)) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _handleReset(),
                ),
                const SizedBox(height: AppSpacing.xl),
                PrimaryButton(
                  text: _isLoading ? 'Sending…' : 'Send Reset Link',
                  onPressed: _isLoading ? null : _handleReset,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
