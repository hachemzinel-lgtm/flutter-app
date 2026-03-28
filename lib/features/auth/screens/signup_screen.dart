import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/models/user_model.dart';
import '../providers/auth_provider.dart';

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

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (_formKey.currentState!.validate()) {
      try {
        await ref.read(authServiceProvider).signUp(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          password: _passwordController.text,
          userType: widget.userType,
        );
        if (mounted) {
          context.go('/email-verification');
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
      appBar: AppBar(
        leading: const BackButton(),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
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
                decoration: _inputDecoration('Enter your full name', Icons.person_outline),
                validator: (val) => val == null || val.isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: AppSpacing.l),
              
              _buildLabel('EMAIL ADDRESS'),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDecoration('name@example.com', Icons.email_outlined),
                validator: (val) => val == null || !val.contains('@') ? 'Invalid email' : null,
              ),
              const SizedBox(height: AppSpacing.l),

              _buildLabel('PHONE NUMBER'),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration('+216 -- --- ---', Icons.phone_outlined),
                validator: (val) => val == null || val.isEmpty ? 'Phone is required' : null,
              ),
              const SizedBox(height: AppSpacing.l),
              
              _buildLabel('PASSWORD'),
              TextFormField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: _inputDecoration('••••••••', Icons.lock_outline).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.softGray,
                    ),
                    onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                  ),
                ),
                validator: (val) => val == null || val.length < 6 ? 'Min 6 characters' : null,
              ),
              const SizedBox(height: AppSpacing.xxl),
              
              PrimaryButton(
                text: 'Sign Up',
                onPressed: _handleSignUp,
              ),
              const SizedBox(height: AppSpacing.l),
              
              Center(
                child: GestureDetector(
                  onTap: () => context.push('/login'),
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
      fillColor: AppColors.softGray.withOpacity(0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 20),
    );
  }
}
