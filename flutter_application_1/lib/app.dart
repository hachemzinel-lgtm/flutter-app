import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_colors.dart';
import 'core/models/user_model.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/account_type_screen.dart';
import 'features/auth/screens/signup_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/forgot_password_screen.dart';
import 'features/auth/screens/otp_verification_screen.dart';
import 'features/home/screens/main_scaffold.dart';
import 'features/profile/screens/provider_profile_screen.dart';
import 'features/profile/screens/merchant_profile_screen.dart';
import 'features/profile/screens/provider_setup_screen.dart';
import 'features/profile/screens/merchant_setup_screen.dart';
import 'features/profile/screens/edit_profile_screen.dart';
import 'features/search/screens/results_list_screen.dart';
import 'features/chat/screens/conversations_list_screen.dart';
import 'features/chat/screens/chat_screen.dart';
import 'features/reviews/screens/reviews_screen.dart';
import 'features/reviews/screens/rate_service_screen.dart';
import 'features/notifications/screens/notifications_screen.dart';
import 'features/favorites/screens/favorites_screen.dart';
import 'features/settings/screens/settings_screen.dart';
import 'features/settings/screens/language_selector_screen.dart';
import 'features/settings/screens/availability_screen.dart';
import 'features/chatbot/screens/chatbot_screen.dart';
import 'features/notifications/services/fcm_controller.dart';

/// Routes that a signed-out user is allowed to visit directly.
/// `/otp-verification` is technically reachable only when signed in (the
/// user has just been created), but we keep it public so the splash
/// redirect can land there without bouncing back to `/account-type`.
const _publicRoutes = <String>{
  '/splash',
  '/account-type',
  '/login',
  '/forgot-password',
  '/otp-verification',
};

/// Routes that assume `_publicRoutes` signups (e.g. signup/:type) — prefix-matched.
const _publicPrefixes = <String>[
  '/signup/',
];

bool _isPublic(String location) {
  if (_publicRoutes.contains(location)) return true;
  for (final prefix in _publicPrefixes) {
    if (location.startsWith(prefix)) return true;
  }
  return false;
}

class NearWorkApp extends ConsumerWidget {
  const NearWorkApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);

    final router = GoRouter(
      initialLocation: '/splash',
      refreshListenable: _AuthRefreshNotifier(ref),
      redirect: (context, state) {
        // While auth state is still loading, keep the user on splash.
        if (authAsync.isLoading) {
          return state.matchedLocation == '/splash' ? null : '/splash';
        }

        final isSignedIn = authAsync.value != null;
        final location = state.matchedLocation;

        // Signed-out user trying to reach a protected page → account-type.
        if (!isSignedIn && !_isPublic(location)) {
          return '/account-type';
        }

        // Signed-in user bouncing back onto an auth screen → home.
        // (Splash handles its own finer-grained routing.)
        final authLandingScreens = {
          '/account-type',
          '/login',
          '/forgot-password',
        };
        if (isSignedIn && authLandingScreens.contains(location)) {
          return '/home';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/account-type',
          builder: (context, state) => const AccountTypeScreen(),
        ),
        GoRoute(
          path: '/signup/:type',
          builder: (context, state) => SignUpScreen(
            userType: UserModel.parseUserType(
                state.pathParameters['type'] ?? 'client'),
          ),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: '/otp-verification',
          builder: (context, state) {
            // `extra` carries the E.164 phone number captured at signup.
            // If missing (deep-link, cold-start edge case), we render an
            // empty string and the screen will show an "invalid phone"
            // error — the user can tap "Use a different account" to reset.
            final phone = state.extra is String ? state.extra as String : '';
            return OtpVerificationScreen(phoneNumber: phone);
          },
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const MainScaffold(),
        ),
        GoRoute(
          path: '/provider-setup',
          builder: (context, state) => const ProviderSetupScreen(),
        ),
        GoRoute(
          path: '/merchant-setup',
          builder: (context, state) => const MerchantSetupScreen(),
        ),
        GoRoute(
          path: '/provider-profile/:id',
          builder: (context, state) => ProviderProfileScreen(
            uid: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: '/merchant-profile/:id',
          builder: (context, state) => MerchantProfileScreen(
            uid: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: '/edit-profile',
          builder: (context, state) => const EditProfileScreen(),
        ),
        GoRoute(
          path: '/search-results',
          builder: (context, state) {
            final category = state.uri.queryParameters['category'];
            return ResultsListScreen(initialCategory: category);
          },
        ),
        GoRoute(
          path: '/conversations',
          builder: (context, state) => const ConversationsListScreen(),
        ),
        GoRoute(
          path: '/chat/:id',
          builder: (context, state) => ChatScreen(
            conversationId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: '/reviews/:providerId',
          builder: (context, state) => ReviewsScreen(
            providerId: state.pathParameters['providerId']!,
          ),
        ),
        GoRoute(
          path: '/rate-service/:providerId',
          builder: (context, state) => RateServiceScreen(
            providerId: state.pathParameters['providerId']!,
          ),
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: '/favorites',
          builder: (context, state) => const FavoritesScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/language',
          builder: (context, state) => const LanguageSelectorScreen(),
        ),
        GoRoute(
          path: '/availability',
          builder: (context, state) => const AvailabilityScreen(),
        ),
        GoRoute(
          path: '/chat-bot',
          builder: (context, state) => const ChatbotPage(),
        ),
      ],
    );

    return MaterialApp.router(
      title: 'NearWork',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.accentBlue,
        ),
        scaffoldBackgroundColor: AppColors.primaryBackground,
      ),
      routerConfig: router,
      // FcmLifecycle is a no-UI wrapper that binds/unbinds Firebase
      // Messaging as the auth state changes. Placed inside the router's
      // builder so it has a GoRouter-aware BuildContext for deep-links.
      builder: (context, child) =>
          FcmLifecycle(child: child ?? const SizedBox.shrink()),
    );
  }
}

/// Bridges Riverpod's auth stream into GoRouter so the redirect re-runs
/// whenever Firebase Auth state changes (login, logout, token refresh).
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(WidgetRef ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
  }
}
