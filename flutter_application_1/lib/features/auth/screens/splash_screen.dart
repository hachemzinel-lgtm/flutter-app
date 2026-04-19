import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  /// Minimum time we stay on the splash so the brand flashes for one beat
  /// even on fast networks, without blocking real routing.
  static const _minSplashDuration = Duration(milliseconds: 800);

  bool _minElapsed = false;
  bool _routed = false;
  Timer? _minTimer;

  @override
  void initState() {
    super.initState();
    _minTimer = Timer(_minSplashDuration, () {
      if (!mounted) return;
      setState(() => _minElapsed = true);
    });
  }

  @override
  void dispose() {
    _minTimer?.cancel();
    super.dispose();
  }

  String _destinationFor(AuthLanding landing) {
    switch (landing) {
      case AuthLanding.login:
        return '/account-type';
      case AuthLanding.phoneVerification:
        // The phone number lives on the Firebase user and/or users doc —
        // we pass what we have via the router's `extra` field inside
        // `_routeTo`, not here.
        return '/otp-verification';
      case AuthLanding.accountType:
        return '/account-type';
      case AuthLanding.providerSetup:
        return '/provider-setup';
      case AuthLanding.merchantSetup:
        return '/merchant-setup';
      case AuthLanding.home:
        return '/home';
    }
  }

  Future<void> _routeTo(AuthLanding landing) async {
    if (_routed || !mounted) return;
    _routed = true;

    if (landing == AuthLanding.phoneVerification) {
      // Look up the phone number stored at signup time. If it's missing
      // for any reason (partial doc, mid-migration), fall back to the
      // Firebase user's phone, and finally to account-type so the user
      // doesn't end up stuck on an empty OTP screen.
      final user = ref.read(authStateProvider).value;
      final svc = ref.read(authServiceProvider);
      final phone = await svc.lookupSignupPhone(user?.uid) ??
          user?.phoneNumber ??
          '';

      if (!mounted) return;
      if (phone.isEmpty) {
        context.go('/account-type');
        return;
      }
      context.go('/otp-verification', extra: phone);
      return;
    }

    context.go(_destinationFor(landing));
  }

  @override
  Widget build(BuildContext context) {
    final landingAsync = ref.watch(authLandingProvider);

    // Route only when BOTH the auth landing has resolved AND the minimum
    // splash window has elapsed, otherwise the brand flickers for a frame
    // on a warm cache.
    landingAsync.whenData((landing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_minElapsed) _routeTo(landing);
      });
    });

    return Scaffold(
      backgroundColor: AppColors.accentBlue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.work_outline_rounded,
              size: 100,
              color: Colors.white,
            ),
            const SizedBox(height: 24),
            Text(
              'NearWork',
              style: AppTextStyles.headingLarge.copyWith(
                color: Colors.white,
                fontSize: 32,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Work better, Together',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 40),
            if (landingAsync.isLoading)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            if (landingAsync.hasError)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Could not start. Please check your connection and try again.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => ref.invalidate(authLandingProvider),
                      child: const Text('Retry',
                          style: TextStyle(color: Colors.white)),
                    ),
                    TextButton(
                      onPressed: () async {
                        // Escape hatch: sign out and send the user back to
                        // the account-type picker if the landing resolver
                        // is permanently wedged.
                        await ref
                            .read(authServiceProvider)
                            .signOut();
                        if (context.mounted) context.go('/account-type');
                      },
                      child: const Text('Sign out',
                          style: TextStyle(color: Colors.white70)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

