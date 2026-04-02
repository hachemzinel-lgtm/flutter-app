import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/constants/app_colors.dart';
import 'core/models/user_model.dart';
import 'features/admin/screens/admin_dashboard_screen.dart';
import 'features/admin/services/admin_service.dart';
import 'features/ai_chat/presentation/pages/ai_chat_page.dart';
import 'features/ai_chat/presentation/pages/chat_history_page.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/account_type_screen.dart';
import 'features/auth/screens/email_verification_screen.dart';
import 'features/auth/screens/forgot_password_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/signup_screen.dart';
import 'features/auth/screens/welcome_screen.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/verification_pending_screen.dart';
import 'features/chat/screens/chat_screen.dart';
import 'features/chat/screens/conversations_list_screen.dart';
import 'features/home/screens/best_providers_screen.dart';
import 'features/home/screens/client_home_screen.dart';
import 'features/home/screens/map_results_screen.dart';
import 'features/home/screens/marketplace_home_screen.dart';
import 'features/home/screens/provider_home_screen.dart';
import 'features/notifications/screens/notifications_screen.dart';
import 'features/profile/screens/client_profile_setup_screen.dart';
import 'features/profile/screens/edit_profile_screen.dart';
import 'features/profile/screens/merchant_profile_screen.dart';
import 'features/profile/screens/merchant_setup_screen.dart';
import 'features/profile/screens/public_profile_screen.dart';
import 'features/profile/screens/provider_profile_screen.dart';
import 'features/profile/screens/provider_setup_screen.dart';
import 'core/models/work_provider_model.dart';
import 'features/reviews/screens/rate_service_screen.dart';
import 'features/reviews/screens/reviews_screen.dart';
import 'features/notifications/services/notification_service.dart';
import 'features/settings/providers/locale_provider.dart';
import 'features/settings/screens/language_selector_screen.dart';
import 'features/settings/screens/settings_screen.dart';
import 'features/shared/presentation/widgets/components/main_scaffold_wrapper.dart';
import 'l10n/app_localizations.dart';

class NearWorkApp extends ConsumerWidget {
  const NearWorkApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(appLocaleProvider);
    final authState = ref.watch(authStateProvider);
    final currentUserDoc = ref.watch(currentUserDocProvider);
    final isEmailVerified = ref.watch(isEmailVerifiedProvider);

    ref.listen<AsyncValue<UserModel?>>(currentUserDocProvider, (previous, next) {
      final user = next.value;
      if (user != null && user.notificationsEnabled) {
        unawaited(
          ref.read(notificationServiceProvider).initNotifications(user.id),
        );
      }
    });

    final router = GoRouter(
      initialLocation: '/welcome',
      refreshListenable: _GoRouterRefreshStream(
        ref.read(authServiceProvider).authStateChanges,
      ),
      redirect: (context, state) async {
        final user = authState.value;
        final userDoc = currentUserDoc.value;
        final location = state.matchedLocation;
        final isAdminRoute =
            location == '/admin' || location.startsWith('/admin/');
        final isAdminUser = user == null
            ? false
            : await ref.read(adminServiceProvider).isAdminUser(user);

        const authRoutes = {
          '/welcome',
          '/splash',
          '/login',
          '/signup',
          '/forgot-password',
          '/email-verification',
        };

        final isProfileSetupRoute =
            location == '/account-type' || location.startsWith('/profile-setup');

        // 1. If user not authenticated → redirect to /welcome
        if (user == null) {
          if (authRoutes.contains(location)) {
            return null;
          }
          return '/welcome';
        }

        // 2. If authenticated but email not verified → redirect to /email-verify
        if (!isEmailVerified) {
          if (location == '/email-verification') {
            return null;
          }
          return '/email-verification';
        }

        if (location == '/email-verification') {
          return '/account-type';
        }

        if (currentUserDoc.isLoading) {
          if (isAdminRoute && isAdminUser) {
            return null;
          }
          // Only allowed fallback while waiting for firestore is splash or welcome
          return (location == '/splash' || location == '/welcome') ? null : '/splash';
        }

        // 3. If verified but no accountType in Firestore → redirect to /account-type
        if (userDoc == null) {
          if (isAdminUser) {
            return isAdminRoute ? null : '/admin';
          }
          if (isProfileSetupRoute) {
            return null;
          }
          return '/account-type';
        }

        if (!userDoc.profileCompleted) {
          if (isProfileSetupRoute) {
            return null;
          }
          // 4. If accountType set but profile incomplete → redirect to appropriate setup screen
          return '/account-type';
        }

        final needsVerificationReview =
            userDoc is WorkProviderModel &&
                userDoc.verificationStatus != VerificationStatus.approved.name;
        if (needsVerificationReview &&
            location != '/verification-pending' &&
            location != '/profile') {
          return '/verification-pending';
        }

        if (authRoutes.contains(location) || isProfileSetupRoute) {
          // 5. If everything complete → allow access to home screens
          return '/home';
        }

        if (location == '/splash' || location == '/welcome') {
          return '/home';
        }

        return null;
      },
      routes: [
        GoRoute(path: '/welcome', builder: (_, _) => const WelcomeScreen()),
        GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
        GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
        GoRoute(path: '/signup', builder: (_, _) => const SignUpScreen()),
        GoRoute(
          path: '/forgot-password',
          builder: (_, _) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: '/email-verification',
          builder: (_, _) => const EmailVerificationScreen(),
        ),
        GoRoute(
          path: '/account-type',
          builder: (_, _) => const AccountTypeScreen(),
        ),
        GoRoute(
          path: '/profile-setup/client',
          builder: (_, _) => const ClientProfileSetupScreen(),
        ),
        GoRoute(
          path: '/profile-setup/provider',
          builder: (_, _) => const ProviderProfileSetupScreen(),
        ),
        GoRoute(
          path: '/profile-setup/marketplace',
          builder: (_, _) => const MarketplaceProfileSetupScreen(),
        ),
        GoRoute(
          path: '/verification-pending',
          builder: (_, _) => const VerificationPendingScreen(),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return MainScaffoldWrapper(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/home',
                  builder: (context, state) {
                    final userDoc = ref.read(currentUserDocProvider).value;
                    switch (userDoc?.userType) {
                      case UserType.workProvider:
                        return const ProviderHomeScreen();
                      case UserType.marketplace:
                        return const MarketplaceHomeScreen();
                      case UserType.client:
                      case null:
                        return const ClientHomeScreen();
                    }
                  },
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/best-providers',
                  builder: (_, _) => const BestProvidersScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/messages',
                  builder: (_, _) => const ConversationsListScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/ai-chat',
                  builder: (_, _) => const ChatHistoryPage(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/profile',
                  builder: (_, _) => const EditProfileScreen(),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/search-results',
          builder: (context, state) {
            return MapResultsScreen(
              category: state.uri.queryParameters['category'] ?? 'Any',
              searchType: state.uri.queryParameters['type'] ?? 'provider',
              radiusKm:
                  double.tryParse(state.uri.queryParameters['radius'] ?? '') ?? 10,
              minimumRating:
                  double.tryParse(state.uri.queryParameters['minRating'] ?? '') ??
                      0,
              availableOnly:
                  state.uri.queryParameters['availableOnly'] == 'true',
              originLatitude:
                  double.tryParse(state.uri.queryParameters['lat'] ?? '') ??
                      0,
              originLongitude:
                  double.tryParse(state.uri.queryParameters['lng'] ?? '') ??
                      0,
              originLabel: state.uri.queryParameters['label'] ?? 'Search area',
            );
          },
        ),
        GoRoute(
          path: '/map-results',
          redirect: (context, state) {
            final query = state.uri.query;
            return query.isEmpty ? '/search-results' : '/search-results?$query';
          },
        ),
        GoRoute(
          path: '/messages/:conversationId',
          builder: (context, state) {
            return ChatScreen(
              conversationId: state.pathParameters['conversationId']!,
              otherName: state.uri.queryParameters['otherName'],
            );
          },
        ),
        GoRoute(
          path: '/conversations',
          redirect: (_, _) => '/messages',
        ),
        GoRoute(
          path: '/chat/:id',
          redirect: (context, state) {
            final id = state.pathParameters['id']!;
            final otherName = state.uri.queryParameters['otherName'];
            final params = otherName == null ? '' : '?otherName=$otherName';
            return '/messages/$id$params';
          },
        ),
        GoRoute(
          path: '/ai-chat/session',
          builder: (_, _) => const AIChatPage(),
        ),
        GoRoute(
          path: '/chat-bot',
          redirect: (_, _) => '/ai-chat/session',
        ),
        GoRoute(
          path: '/provider-profile/:id',
          builder: (context, state) {
            return ProviderProfileScreen(uid: state.pathParameters['id']!);
          },
        ),
        GoRoute(
          path: '/merchant-profile/:id',
          builder: (context, state) {
            return MerchantProfileScreen(uid: state.pathParameters['id']!);
          },
        ),
        GoRoute(
          path: '/reviews/:providerId',
          builder: (context, state) {
            return ReviewsScreen(providerId: state.pathParameters['providerId']!);
          },
        ),
        GoRoute(
          path: '/profile/:userId',
          builder: (context, state) {
            return PublicProfileScreen(userId: state.pathParameters['userId']!);
          },
        ),
        GoRoute(
          path: '/rate-service/:providerId',
          builder: (context, state) {
            return RateServiceScreen(
              providerId: state.pathParameters['providerId']!,
            );
          },
        ),
        GoRoute(
          path: '/admin',
          builder: (context, state) => const AdminDashboardScreen(),
        ),
        GoRoute(
          path: '/admin/users',
          builder: (context, state) => const AdminDashboardScreen(initialSection: 1),
        ),
        GoRoute(
          path: '/admin/verifications',
          builder: (context, state) => const AdminDashboardScreen(initialSection: 2),
        ),
        GoRoute(
          path: '/admin/reports',
          builder: (context, state) => const AdminDashboardScreen(initialSection: 3),
        ),
        GoRoute(
          path: '/admin/reviews',
          builder: (context, state) => const AdminDashboardScreen(initialSection: 4),
        ),
        GoRoute(
          path: '/notifications',
          builder: (_, _) => const NotificationsScreen(),
        ),
        GoRoute(
          path: '/favorites',
          redirect: (_, _) => '/best-providers',
        ),
        GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
        GoRoute(path: '/language', builder: (_, _) => const LanguageSelectorScreen()),
      ],
    );

    return MaterialApp.router(
      title: 'NearWork',
      debugShowCheckedModeBanner: false,
      locale: locale,
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter',
        scaffoldBackgroundColor: AppColors.primaryBackground,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.accentBlue,
          primary: AppColors.accentBlue,
          secondary: AppColors.starGold,
          surface: AppColors.cardSurface,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.primaryNavy,
          elevation: 0,
        ),
      ),
      localizationsDelegates: const [
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
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
