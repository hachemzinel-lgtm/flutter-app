import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../../../core/models/user_model.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final userAccountTypeProvider = FutureProvider<UserType?>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return null;
  return ref.watch(authServiceProvider).getUserType(user.uid);
});

/// Possible places the router should land an authenticated user.
enum AuthLanding {
  /// User is signed out entirely.
  login,

  /// User is signed in but hasn't verified their phone number via SMS OTP.
  /// Google-authenticated users skip this state (OAuth identity is trusted).
  phoneVerification,

  /// User is signed in but hasn't chosen a role yet (e.g. fresh Google sign-in).
  accountType,

  /// Service-provider user that still needs to complete provider setup.
  providerSetup,

  /// Merchant user that still needs to complete merchant setup.
  merchantSetup,

  /// User is fully onboarded.
  home,
}

/// Computes the single source of truth for "where should the user be" based
/// on Firebase Auth state and Firestore profile state. Consumed by both the
/// splash screen and the GoRouter redirect.
///
/// Order of precedence (top wins):
///   1. Not signed in → login
///   2. Signed in, phone not verified → phoneVerification
///   3. No role chosen yet → accountType
///   4. Role chosen but profile setup incomplete → provider/merchantSetup
///   5. Otherwise → home
final authLandingProvider = FutureProvider<AuthLanding>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return AuthLanding.login;

  final svc = ref.watch(authServiceProvider);

  // Phone OTP gate — applies to password-signup users who haven't yet
  // confirmed their SMS code. Google users are trusted via OAuth, so the
  // service returns `true` for them unconditionally.
  final phoneOk = await svc.hasVerifiedPhone(user.uid);
  if (!phoneOk) return AuthLanding.phoneVerification;

  final type = await svc.getUserType(user.uid);
  if (type == null) return AuthLanding.accountType;

  final hasSetup = await svc.hasCompletedSetup(user.uid, type);
  if (!hasSetup) {
    switch (type) {
      case UserType.serviceProvider:
        return AuthLanding.providerSetup;
      case UserType.marketplace:
        return AuthLanding.merchantSetup;
      case UserType.client:
        return AuthLanding.home;
    }
  }
  return AuthLanding.home;
});
