import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'core/constants/app_colors.dart';
import 'core/models/user_model.dart';

// Auth screens
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/signup_screen.dart';
import 'features/auth/screens/forgot_password_screen.dart';
import 'features/auth/screens/verification_code_screen.dart';
import 'features/auth/screens/account_type_screen.dart';
import 'features/auth/screens/verification_pending_screen.dart';
import 'features/auth/providers/auth_provider.dart';

// Profile setup screens
import 'features/profile/screens/client_profile_setup_screen.dart';
import 'features/profile/screens/provider_setup_screen.dart';
import 'features/profile/screens/merchant_setup_screen.dart';

// Main feature screens
import 'features/home/screens/client_home_screen.dart';
import 'features/home/screens/provider_home_screen.dart';
import 'features/home/screens/marketplace_home_screen.dart';
import 'features/home/screens/map_results_screen.dart';
import 'features/home/screens/best_providers_screen.dart';
import 'features/profile/screens/provider_profile_screen.dart';
import 'features/profile/screens/merchant_profile_screen.dart';
import 'features/profile/screens/edit_profile_screen.dart';
import 'features/chat/screens/conversations_list_screen.dart';
import 'features/chat/screens/chat_screen.dart';
import 'features/reviews/screens/reviews_screen.dart';
import 'features/reviews/screens/rate_service_screen.dart';
import 'features/admin/screens/admin_dashboard_screen.dart';
import 'features/settings/screens/settings_screen.dart';
import 'features/settings/screens/language_selector_screen.dart';
import 'features/ai_chat/presentation/pages/chat_history_page.dart';
import 'features/ai_chat/presentation/pages/ai_chat_page.dart';
import 'features/shared/presentation/widgets/components/main_scaffold_wrapper.dart';

class NearWorkApp extends ConsumerWidget {
  const NearWorkApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = GoRouter(
      initialLocation: '/splash',
      refreshListenable: _GoRouterRefreshStream(ref.read(authServiceProvider).authStateChanges),
      redirect: (context, state) async {
        final authAsync = ref.read(authStateProvider);
        final user = authAsync.value;
        final loc = state.matchedLocation;

        debugPrint('--- [ROUTER REDIRECT] loc: $loc, user: ${user?.uid}, verified: ${user?.emailVerified} ---');

        // Skip redirect for splash/auth screens
        final publicRoutes = ['/splash', '/login', '/signup', '/forgot-password'];
        if (publicRoutes.contains(loc)) {
          // If user is already logged in and verified, don't let them stay on public routes (except splash briefly)
          final isEmailVerified = ref.watch(isEmailVerifiedProvider).value ?? false;
          if (user != null && isEmailVerified && loc != '/splash') {
            debugPrint('--- [ROUTER] User logged in & verified, redirecting from public route to /home ---');
            return '/home';
          }
          return null;
        }

        // If user not logged in, redirect to login
        if (user == null) {
          if (authAsync.isLoading) {
             debugPrint('--- [ROUTER] Auth state loading, staying put ---');
             return null;
          }
          debugPrint('--- [ROUTER] No user found, redirecting to /login ---');
          return '/login';
        }

        // If email not verified (Custom check)
        final isEmailVerified = ref.watch(isEmailVerifiedProvider).value ?? false;
        if (!isEmailVerified) {
          debugPrint('--- [ROUTER] Email NOT verified, redirecting to /verification-code ---');
          if (loc == '/verification-code') return null;
          return '/verification-code';
        }

        // If on verification page but already verified
        if (loc == '/verification-code') {
          debugPrint('--- [ROUTER] On verification-code but verified, moving to account-type ---');
          return '/account-type';
        }

        // Check if profile is set up
        final userDocAsync = ref.read(currentUserDocProvider);
        final userDoc = userDocAsync.value;

        // Still loading user doc
        if (userDocAsync.isLoading) {
          debugPrint('--- [ROUTER] User doc loading, staying put ---');
          return null;
        }

        if (userDoc == null) {
          // Profile not set up yet
          debugPrint('--- [ROUTER] No user doc found, profile setup required ---');
          if (loc == '/account-type' || loc.startsWith('/profile-setup')) return null;
          return '/account-type';
        }

        // Work provider verification check
        if (userDoc.userType == UserType.workProvider) {
          final data = userDoc.toJson();
          final status = (data['verificationStatus'] ?? 'pending') as String;
          debugPrint('--- [ROUTER] Work Provider check: status = $status ---');
          if (status == 'pending' || status == 'rejected') {
            if (loc == '/verification-pending' || loc.startsWith('/profile-setup')) return null;
            return '/verification-pending';
          }
        }

        debugPrint('--- [ROUTER] All checks passed, allowing navigation to $loc ---');
        return null;
      },
      routes: [
        // ─── Public routes ───────────────────────────────────────────
        GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(path: '/signup', builder: (_, __) => const SignUpScreen()),
        GoRoute(path: '/forgot-password', builder: (_, __) => const ForgotPasswordScreen()),
        GoRoute(path: '/verification-code', builder: (_, __) => const VerificationCodeScreen()),
        GoRoute(path: '/account-type', builder: (_, __) => const AccountTypeScreen()),

        // Profile setup routes
        GoRoute(
          path: '/profile-setup/client',
          builder: (_, __) => const ClientProfileSetupScreen(),
        ),
        GoRoute(
          path: '/profile-setup/provider',
          builder: (_, __) => const ProviderProfileSetupScreen(),
        ),
        GoRoute(
          path: '/profile-setup/marketplace',
          builder: (_, __) => const MarketplaceProfileSetupScreen(),
        ),
        GoRoute(path: '/verification-pending', builder: (_, __) => const VerificationPendingScreen()),

        // ─── Shell (bottom nav) ───────────────────────────────────────
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              MainScaffoldWrapper(navigationShell: navigationShell),
          branches: [
            // Branch 0 – Home
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) {
        final userDoc = ref.read(currentUserDocProvider).value;
                  switch (userDoc?.userType) {
                    case UserType.workProvider:
                      return const ProviderHomeScreen();
                    case UserType.marketplace:
                      return const MarketplaceHomeScreen();
                    default:
                      return const ClientHomeScreen();
                  }
                },
              ),
            ]),
            // Branch 1 – Best Providers (client only) / Search Results (others)
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/best-providers',
                builder: (_, __) => const BestProvidersScreen(),
              ),
            ]),
            // Branch 2 – Messages
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/conversations',
                builder: (_, __) => const ConversationsListScreen(),
              ),
            ]),
            // Branch 3 – AI Chat
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/chat-history',
                builder: (_, __) => const ChatHistoryPage(),
              ),
            ]),
            // Branch 4 – Profile
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/profile',
                builder: (_, __) => const EditProfileScreen(),
              ),
            ]),
          ],
        ),

        // ─── Standalone routes (no bottom nav) ───────────────────────
        GoRoute(
          path: '/map-results',
          builder: (context, state) {
            final category = state.uri.queryParameters['category'] ?? '';
            final type = state.uri.queryParameters['type'] ?? 'provider';
            return MapResultsScreen(category: category, searchType: type);
          },
        ),
        GoRoute(
          path: '/chat/:id',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            final name = state.uri.queryParameters['otherName'];
            return ChatScreen(conversationId: id, otherName: name);
          },
        ),
        GoRoute(
          path: '/ai-chat',
          builder: (_, __) => const AIChatPage(),
        ),
        GoRoute(
          path: '/provider-profile/:id',
          builder: (context, state) => ProviderProfileScreen(uid: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/merchant-profile/:id',
          builder: (context, state) => MerchantProfileScreen(uid: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/reviews/:providerId',
          builder: (context, state) => ReviewsScreen(providerId: state.pathParameters['providerId']!),
        ),
        GoRoute(
          path: '/rate-service/:providerId',
          builder: (context, state) => RateServiceScreen(providerId: state.pathParameters['providerId']!),
        ),
        GoRoute(
          path: '/admin',
          builder: (context, state) => const AdminDashboardScreen(),
        ),
    GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
        GoRoute(path: '/language', builder: (_, __) => const LanguageSelectorScreen()),
      ],
    );

    return MaterialApp.router(
      title: 'NearWork',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter',
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.accentBlue,
          surface: AppColors.primaryBackground,
        ),
      ),
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }
}

class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (dynamic _) => notifyListeners(),
        );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

