import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/primary_button.dart';
import '../providers/auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Future<void> _handleReset() async {
    if (_formKey.currentState!.validate()) {
      try {
        await ref.read(authServiceProvider).resetPassword(_emailController.text.trim());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reset link sent to your email')),
          );
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: AppColors.errorRed),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(elevation: 0, backgroundColor: Colors.transparent),
      body: Padding(
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
                style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.s),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: 'name@example.com',
                  prefixIcon: const Icon(Icons.email_outlined),
                  filled: true,
                  fillColor: AppColors.softGray.withOpacity(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (val) => val == null || !val.contains('@') ? 'Invalid email' : null,
              ),
              const SizedBox(height: AppSpacing.xl),
              
              PrimaryButton(
                text: 'Send Reset Link',
                onPressed: _handleReset,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
