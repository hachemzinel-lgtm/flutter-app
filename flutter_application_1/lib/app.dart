import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_colors.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/account_type_screen.dart';
import 'features/auth/screens/signup_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/forgot_password_screen.dart';
import 'features/auth/screens/email_verification_screen.dart';
import 'features/home/screens/home_map_screen.dart';
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

class NearWorkApp extends ConsumerWidget {
  const NearWorkApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = GoRouter(
      initialLocation: '/splash',
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
            accountType: state.pathParameters['type'] ?? 'client',
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
          path: '/email-verification',
          builder: (context, state) => const EmailVerificationScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeMapScreen(),
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
      ],
      // TODO: Implement redirect logic based on Auth State
    );

    return MaterialApp.router(
      title: 'NearWork',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.accentBlue,
          background: AppColors.primaryBackground,
        ),
        scaffoldBackgroundColor: AppColors.primaryBackground,
      ),
      routerConfig: router,
    );
  }
}
