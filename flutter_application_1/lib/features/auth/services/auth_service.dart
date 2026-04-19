import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/models/user_model.dart';

/// Thrown by [AuthService] with a human-readable message that screens can
/// show to the user without leaking low-level Firebase error codes.
class AuthException implements Exception {
  final String message;
  final String? code;
  AuthException(this.message, {this.code});
  @override
  String toString() => message;
}

/// Returned by [AuthService.startPhoneVerification] so screens can track
/// the in-flight verification across resends and auto-retrieval.
class PhoneVerificationHandle {
  /// Firebase verification id — needed to pair with the user-entered SMS
  /// code via [PhoneAuthProvider.credential].
  final String verificationId;

  /// Resend token for [FirebaseAuth.verifyPhoneNumber]'s
  /// `forceResendingToken` — lets the next "resend" call skip the
  /// anti-abuse cooldown.
  final int? resendToken;

  /// If Android auto-retrieved the SMS and signed the user in without
  /// them ever typing a code, this is the credential that was used.
  /// Screens should close the OTP UI when this is non-null.
  final PhoneAuthCredential? autoVerifiedCredential;

  const PhoneVerificationHandle({
    required this.verificationId,
    this.resendToken,
    this.autoVerifiedCredential,
  });
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _googleReady = false;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<void> _ensureGoogleReady() async {
    if (_googleReady) return;
    try {
      await GoogleSignIn.instance.initialize();
    } catch (_) {
      // Some platforms (e.g. Linux/Windows) don't support Google Sign-In.
      // We let the subsequent `authenticate()` call surface a clear error.
    }
    _googleReady = true;
  }

  // ─── Email / password ──────────────────────────────────────────────────

  /// Creates an email/password account and mirrors the profile to
  /// Firestore. Does NOT trigger Firebase's email-verification link —
  /// we use phone-number OTP for verification instead (see
  /// [startPhoneVerification]).
  Future<void> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
    required UserType userType,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw AuthException('Account creation failed. Please try again.');
      }

      // Reflect the display name on the Firebase Auth user so other screens
      // can read `user.displayName` without an extra Firestore round-trip.
      await user.updateDisplayName(name);

      // Mirror the core profile in Firestore. `phoneVerified` starts false
      // and is flipped by [confirmPhoneVerification] once the SMS code is
      // accepted.
      await _firestore.collection('users').doc(user.uid).set({
        ...UserModel(
          id: user.uid,
          email: email,
          name: name,
          phone: phone,
          userType: userType,
        ).toJson(),
        'phoneVerified': false,
        'authProviders': ['password'],
      });
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendlyAuthError(e), code: e.code);
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
          email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendlyAuthError(e), code: e.code);
    }
  }

  // ─── Phone OTP (verification) ──────────────────────────────────────────

  /// Starts a phone-number verification. Returns a handle the caller can
  /// use to pair the received code with the original verification id.
  ///
  /// On Android, Firebase may auto-retrieve the SMS and emit a credential
  /// without the user ever typing — that arrives on
  /// [PhoneVerificationHandle.autoVerifiedCredential]; callers should
  /// still finalise the flow by calling [confirmPhoneVerification] with
  /// that credential.
  ///
  /// Each resend should pass the previous handle's `resendToken` so
  /// Firebase bypasses its cooldown.
  Future<PhoneVerificationHandle> startPhoneVerification({
    required String phoneNumber,
    Duration timeout = const Duration(seconds: 60),
    int? forceResendingToken,
  }) {
    // verifyPhoneNumber is a callback-based API; wrap it in a Future we
    // resolve when Firebase has either (a) sent the SMS, (b) auto-verified,
    // or (c) thrown a FirebaseAuthException. The `done` latch guards against
    // the SDK firing multiple callbacks for the same flow (e.g. codeSent AND
    // codeAutoRetrievalTimeout both landing after we've already resolved).
    final completer = Completer<PhoneVerificationHandle>();
    var done = false;

    void resolve(PhoneVerificationHandle v) {
      if (done) return;
      done = true;
      completer.complete(v);
    }

    void reject(Object e) {
      if (done) return;
      done = true;
      completer.completeError(e);
    }

    _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: timeout,
      forceResendingToken: forceResendingToken,
      verificationCompleted: (PhoneAuthCredential credential) {
        // verificationId is not provided on auto-verify; the credential
        // carries everything needed. Use an empty placeholder so callers
        // can still construct a handle — they should switch on
        // autoVerifiedCredential != null.
        resolve(PhoneVerificationHandle(
          verificationId: '',
          autoVerifiedCredential: credential,
        ));
      },
      codeSent: (String verificationId, int? resendToken) {
        resolve(PhoneVerificationHandle(
          verificationId: verificationId,
          resendToken: resendToken,
        ));
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        // Fired when the auto-retrieval window closes. By this point
        // `codeSent` has already fired, so we don't need to do anything.
      },
      verificationFailed: (FirebaseAuthException e) {
        reject(AuthException(_friendlyPhoneError(e), code: e.code));
      },
    );

    return completer.future;
  }

  /// Confirms a phone-number verification by pairing the verification id
  /// with the 6-digit SMS code (or using an already-auto-verified
  /// credential from Android). Links the phone credential to the
  /// currently signed-in user and flips `phoneVerified: true` on the
  /// user document.
  Future<void> confirmPhoneVerification({
    required String verificationId,
    String? smsCode,
    PhoneAuthCredential? autoVerifiedCredential,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw AuthException('You are not signed in. Please sign up again.');
    }

    final credential = autoVerifiedCredential ??
        PhoneAuthProvider.credential(
          verificationId: verificationId,
          smsCode: (smsCode ?? '').trim(),
        );

    try {
      // Link the phone credential to the existing email/password user.
      // If the phone number is already linked to ANOTHER account,
      // `provider-already-linked` / `credential-already-in-use` will fire.
      try {
        await user.linkWithCredential(credential);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'provider-already-linked') {
          // Already linked to THIS user — nothing to do, proceed.
        } else if (e.code == 'credential-already-in-use') {
          throw AuthException(
              'This phone number is already linked to another account.',
              code: e.code);
        } else {
          rethrow;
        }
      }

      await _firestore.collection('users').doc(user.uid).set({
        'phoneVerified': true,
        'phoneVerifiedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendlyPhoneError(e), code: e.code);
    }
  }

  /// Whether the signed-in user has completed phone-OTP verification.
  /// Considers Google users implicitly verified (we trust the OAuth
  /// identity) so they don't get bounced through an SMS flow on login.
  Future<bool> hasVerifiedPhone(String uid) async {
    final user = _auth.currentUser;
    if (user == null) return false;
    // Google sign-in is an OAuth identity we trust — skip phone OTP.
    final isGoogle =
        user.providerData.any((p) => p.providerId == 'google.com');
    if (isGoogle) return true;

    final doc = await _firestore.collection('users').doc(uid).get();
    final data = doc.data();
    if (data == null) return false;
    return (data['phoneVerified'] as bool?) ?? false;
  }

  /// Reads the phone number captured at signup from the users document.
  /// Used by the splash screen to route a partially-onboarded user back
  /// to the OTP screen after a cold start.
  Future<String?> lookupSignupPhone(String? uid) async {
    if (uid == null) return null;
    final doc = await _firestore.collection('users').doc(uid).get();
    final data = doc.data();
    if (data == null) return null;
    final phone = (data['phone'] as String?)?.trim();
    return (phone == null || phone.isEmpty) ? null : phone;
  }

  // ─── Google ────────────────────────────────────────────────────────────

  /// Signs in with Google. Returns true if a new Firestore user doc was
  /// created (so the caller can route to the account-type picker).
  Future<bool> signInWithGoogle() async {
    try {
      await _ensureGoogleReady();

      if (!GoogleSignIn.instance.supportsAuthenticate()) {
        throw AuthException(
          'Google sign-in is not available on this platform.',
          code: 'unsupported',
        );
      }

      final account = await GoogleSignIn.instance.authenticate();
      final auth = account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        throw AuthException('Google sign-in did not return a token.');
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) {
        throw AuthException('Google sign-in failed.');
      }

      if ((user.displayName ?? '').isEmpty && account.displayName != null) {
        await user.updateDisplayName(account.displayName);
      }

      final docRef = _firestore.collection('users').doc(user.uid);
      final snapshot = await docRef.get();
      if (!snapshot.exists) {
        await docRef.set({
          ...UserModel(
            id: user.uid,
            email: user.email ?? account.email,
            name: user.displayName ?? account.displayName ?? '',
            phone: user.phoneNumber ?? '',
            userType: UserType.client, // provisional; user picks on onboarding
            photoUrl: user.photoURL ?? account.photoUrl,
          ).toJson(),
          // Google identities are OAuth-trusted — skip phone OTP.
          'phoneVerified': true,
          'authProviders': ['google.com'],
        });
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendlyAuthError(e), code: e.code);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw AuthException('Sign-in cancelled.', code: 'cancelled');
      }
      throw AuthException('Google sign-in failed: ${e.description ?? e.code}',
          code: e.code.toString());
    }
  }

  // ─── Misc ──────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    await _auth.signOut();
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Non-fatal — user may not have Google-signed in this session.
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendlyAuthError(e), code: e.code);
    }
  }

  Future<void> reloadCurrentUser() async {
    await _auth.currentUser?.reload();
  }

  /// Returns the user's stored type, or null if the user document does not
  /// yet exist.
  Future<UserType?> getUserType(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    final data = doc.data()!;
    return UserModel.parseUserType(
      (data['userType'] ?? data['accountType'] ?? 'client').toString(),
    );
  }

  /// Whether the user has completed their role-specific profile setup.
  Future<bool> hasCompletedSetup(String uid, UserType type) async {
    switch (type) {
      case UserType.serviceProvider:
        final d = await _firestore.collection('providers').doc(uid).get();
        return d.exists;
      case UserType.marketplace:
        final d = await _firestore.collection('merchants').doc(uid).get();
        return d.exists;
      case UserType.client:
        return true;
    }
  }

  // ─── Error formatting ──────────────────────────────────────────────────

  String _friendlyAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'That email address looks invalid.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email or password is incorrect.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Please choose a stronger password (min 6 characters).';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled.';
      case 'network-request-failed':
        return 'Network error. Please check your connection and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a minute and try again.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }

  String _friendlyPhoneError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'That phone number looks invalid. Include the country code '
            '(e.g. +21612345678).';
      case 'invalid-verification-code':
        return 'The code you entered is incorrect. Please try again.';
      case 'invalid-verification-id':
        return 'This verification has expired. Please request a new code.';
      case 'missing-verification-code':
        return 'Please enter the 6-digit code sent to your phone.';
      case 'session-expired':
        return 'The code has expired. Please request a new one.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a few minutes and try again.';
      case 'quota-exceeded':
        return 'SMS quota reached. Please try again later.';
      case 'credential-already-in-use':
        return 'This phone number is already linked to another account.';
      case 'network-request-failed':
        return 'Network error. Please check your connection and try again.';
      default:
        return e.message ?? 'Verification failed. Please try again.';
    }
  }
}

