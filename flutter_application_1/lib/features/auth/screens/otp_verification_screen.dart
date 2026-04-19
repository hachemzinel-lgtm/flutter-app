import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' show PhoneAuthCredential;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/ghost_button.dart';
import '../../../core/widgets/primary_button.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';

/// 6-digit SMS OTP verification screen. Used immediately after email/
/// password signup to confirm the user owns the phone number they provided.
///
/// Contract:
///   - `phoneNumber` is expected to be in E.164 form (e.g. +21612345678).
///     The signup screen normalises it before navigating here.
///   - On success this pops back to `/splash` so `authLandingProvider`
///     re-resolves and routes to account-type / home based on state.
///   - Resending is rate-limited with a 60s cooldown to avoid SMS abuse.
class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String phoneNumber;

  const OtpVerificationScreen({super.key, required this.phoneNumber});

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  static const _codeLength = 6;
  static const _resendCooldown = Duration(seconds: 60);

  final _codeController = TextEditingController();
  final _codeFocus = FocusNode();

  PhoneVerificationHandle? _handle;
  bool _sending = true;
  bool _confirming = false;
  String? _error;

  Timer? _cooldownTimer;
  int _secondsUntilResend = 0;

  @override
  void initState() {
    super.initState();
    // Send the first SMS as soon as the screen is mounted — the signup
    // flow has already told the user a code is on the way.
    WidgetsBinding.instance.addPostFrameCallback((_) => _sendCode());
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _codeController.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _secondsUntilResend = _resendCooldown.inSeconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_secondsUntilResend <= 1) {
        t.cancel();
        setState(() => _secondsUntilResend = 0);
      } else {
        setState(() => _secondsUntilResend -= 1);
      }
    });
  }

  Future<void> _sendCode({bool resend = false}) async {
    if (!mounted) return;
    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      final handle =
          await ref.read(authServiceProvider).startPhoneVerification(
                phoneNumber: widget.phoneNumber,
                forceResendingToken: resend ? _handle?.resendToken : null,
              );

      if (!mounted) return;
      _handle = handle;

      // Android auto-retrieval: Firebase may sign the user in without the
      // code ever being typed. Finalise immediately in that case.
      if (handle.autoVerifiedCredential != null) {
        await _confirmWithAutoCredential(handle.autoVerifiedCredential!);
        return;
      }

      setState(() => _sending = false);
      _startCooldown();
      _codeFocus.requestFocus();

      if (resend) _showSnack('A new code has been sent to your phone.');
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = 'Could not send the code. Please try again.';
      });
    }
  }

  Future<void> _confirmWithAutoCredential(
      PhoneAuthCredential credential) async {
    setState(() {
      _confirming = true;
      _error = null;
    });
    try {
      await ref.read(authServiceProvider).confirmPhoneVerification(
            verificationId: _handle?.verificationId ?? '',
            autoVerifiedCredential: credential,
          );
      if (mounted) _onVerificationSuccess();
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _confirming = false;
          _error = e.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _confirming = false;
          _error = 'Verification failed. Please try again.';
        });
      }
    }
  }

  Future<void> _confirmCode() async {
    if (_confirming || _sending) return;
    final code = _codeController.text.trim();
    if (code.length != _codeLength) {
      setState(() => _error = 'Please enter the 6-digit code.');
      return;
    }
    final handle = _handle;
    if (handle == null) {
      setState(() => _error = 'Please request a new code.');
      return;
    }

    setState(() {
      _confirming = true;
      _error = null;
    });

    try {
      await ref.read(authServiceProvider).confirmPhoneVerification(
            verificationId: handle.verificationId,
            smsCode: code,
          );
      if (mounted) _onVerificationSuccess();
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _confirming = false;
          _error = e.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _confirming = false;
          _error = 'Verification failed. Please try again.';
        });
      }
    }
  }

  void _onVerificationSuccess() {
    // Invalidate the landing provider so it recomputes against the
    // freshly-flipped `phoneVerified` flag, then bounce through splash
    // to land at the right next screen.
    ref.invalidate(authLandingProvider);
    context.go('/splash');
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final maskedPhone = _maskPhone(widget.phoneNumber);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: const BackButton(),
      ),
      body: AbsorbPointer(
        absorbing: _confirming,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: AppSpacing.pagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.accentBlue.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.sms_outlined,
                      size: 56,
                      color: AppColors.accentBlue,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Verify Your Phone',
                  style: AppTextStyles.headingLarge.copyWith(fontSize: 28),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.s),
                Text(
                  'Enter the 6-digit code we sent to $maskedPhone.',
                  style: AppTextStyles.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xxl),
                _OtpInput(
                  controller: _codeController,
                  focusNode: _codeFocus,
                  length: _codeLength,
                  enabled: !_sending && !_confirming,
                  onCompleted: (_) => _confirmCode(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.m),
                  Text(
                    _error!,
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.errorRed),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                PrimaryButton(
                  text: _confirming ? 'Verifying…' : 'Verify',
                  onPressed:
                      (_sending || _confirming) ? null : _confirmCode,
                ),
                const SizedBox(height: AppSpacing.m),
                GhostButton(
                  text: _secondsUntilResend > 0
                      ? 'Resend in ${_secondsUntilResend}s'
                      : (_sending ? 'Sending…' : 'Resend code'),
                  onPressed: (_secondsUntilResend > 0 ||
                          _sending ||
                          _confirming)
                      ? null
                      : () => _sendCode(resend: true),
                ),
                const SizedBox(height: AppSpacing.l),
                Center(
                  child: TextButton(
                    onPressed: _confirming
                        ? null
                        : () async {
                            // Let the user bail out — sign them out so they
                            // can try again cleanly. Otherwise the auth
                            // landing provider keeps sending them here.
                            await ref.read(authServiceProvider).signOut();
                            if (context.mounted) {
                              context.go('/account-type');
                            }
                          },
                    child: Text(
                      'Use a different account',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.accentBlue,
                        fontWeight: FontWeight.w600,
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

  /// Masks the middle of a phone number for display — "+21612345678" →
  /// "+216 •••• 5678". Falls back to the original string for numbers
  /// too short to meaningfully mask.
  String _maskPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'\s+'), '');
    if (cleaned.length < 8) return phone;
    final last4 = cleaned.substring(cleaned.length - 4);
    // Keep the country code (+XXX) visible when present; otherwise show
    // the leading two digits so the user still recognises the number.
    final prefixLength = cleaned.startsWith('+') ? 4 : 2;
    final prefix = cleaned.substring(0, prefixLength);
    return '$prefix •••• $last4';
  }
}

/// Minimal boxed 6-digit PIN input. We use a single `TextField` masked as
/// 6 boxes rather than 6 focus-chained fields — it plays better with
/// SMS-autofill and avoids a class of focus-jumping bugs.
class _OtpInput extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final int length;
  final bool enabled;
  final ValueChanged<String>? onCompleted;

  const _OtpInput({
    required this.controller,
    required this.focusNode,
    required this.length,
    required this.enabled,
    this.onCompleted,
  });

  @override
  State<_OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<_OtpInput> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    setState(() {});
    if (widget.controller.text.length == widget.length) {
      widget.onCompleted?.call(widget.controller.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Boxes — purely visual.
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(widget.length, (i) {
            final value = i < widget.controller.text.length
                ? widget.controller.text[i]
                : '';
            final isActive = i == widget.controller.text.length;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: AspectRatio(
                  aspectRatio: 0.85,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.softGray.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(
                          AppSpacing.borderRadius),
                      border: Border.all(
                        color: isActive
                            ? AppColors.accentBlue
                            : AppColors.softGray.withValues(alpha: 0.25),
                        width: isActive ? 2 : 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      value,
                      style: AppTextStyles.headingLarge.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        // The real (transparent) input — captures keystrokes + paste + autofill.
        Positioned.fill(
          child: TextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            enabled: widget.enabled,
            autofocus: true,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            autofillHints: const [AutofillHints.oneTimeCode],
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(widget.length),
            ],
            style: const TextStyle(color: Colors.transparent, fontSize: 24),
            cursorColor: Colors.transparent,
            decoration: const InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              counterText: '',
            ),
          ),
        ),
      ],
    );
  }
}
