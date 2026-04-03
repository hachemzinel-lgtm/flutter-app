import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/ai_chat/presentation/pages/ai_chat_page.dart';
import '../../features/ai_chat/presentation/pages/chat_history_page.dart';
import '../../features/auth/presentation/pages/account_type_selection_screen.dart';
import '../../features/auth/presentation/pages/client_profile_setup_screen.dart';
import '../../features/auth/presentation/pages/email_verification_screen.dart';
import '../../features/auth/presentation/pages/login_screen.dart';
import '../../features/auth/presentation/pages/marketplace_profile_setup_screen.dart';
import '../../features/auth/presentation/pages/signup_screen.dart';
import '../../features/auth/presentation/pages/welcome_screen.dart';
import '../../features/auth/presentation/pages/work_provider_profile_setup_screen.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/verification_pending_screen.dart';
import '../../features/chat/screens/chat_screen.dart';
import '../../features/chat/screens/conversations_list_screen.dart';
import '../../features/favorites/screens/favorites_screen.dart';
import '../../features/home/screens/best_providers_screen.dart';
import '../../features/home/screens/client_home_screen.dart';
import '../../features/home/screens/map_results_screen.dart';
import '../../features/home/screens/marketplace_home_screen.dart';
import '../../features/home/screens/provider_home_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/profile/screens/merchant_profile_screen.dart';
import '../../features/profile/screens/provider_profile_screen.dart';
import '../../features/profile/screens/public_profile_screen.dart';
import '../../features/reviews/screens/rate_service_screen.dart';
import '../../features/reviews/screens/reviews_screen.dart';
import '../../features/settings/screens/language_selector_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/shared/presentation/widgets/components/main_scaffold_wrapper.dart';
import 'route_paths.dart';

GoRouter buildAppRouter(WidgetRef ref) {
  final authState = ref.watch(authStateProvider);
  final userDocState = ref.watch(currentUserDocProvider);

  return GoRouter(
    initialLocation: AppRoutes.welcome,
    redirect: (context, state) {
      final location = state.matchedLocation;
      final user = authState.value;
      final userDoc = userDocState.value;

      if (user == null) {
        if (AppRoutes.publicRoutes.contains(location)) {
          return null;
        }
        return AppRoutes.welcome;
      }

      if (!user.emailVerified) {
        if (location == AppRoutes.emailVerification) {
          return null;
        }
        return AppRoutes.emailVerification;
      }

      if (userDocState.isLoading) {
        return null;
      }

      final destination = resolveAuthenticatedRoute(userDoc?.toJson());
      final isHomeDestination = {
        AppRoutes.clientHome,
        AppRoutes.providerHome,
        AppRoutes.marketplaceHome,
      }.contains(destination);
      final protectedSetupRoute = AppRoutes.setupRoutes.contains(location);

      if (!isHomeDestination) {
        return location == destination ? null : destination;
      }

      if (location == AppRoutes.home) {
        return destination;
      }

      if (AppRoutes.publicRoutes.contains(location) ||
          location == AppRoutes.emailVerification ||
          protectedSetupRoute) {
        return location == destination ? null : destination;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.welcome,
        builder: (_, _) => const WelcomeScreen(),
      ),
      GoRoute(path: AppRoutes.signup, builder: (_, _) => const SignupScreen()),
      GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (_, _) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.emailVerification,
        builder: (_, state) => EmailVerificationScreen(
          email: state.extra is String ? state.extra as String : null,
        ),
      ),
      GoRoute(
        path: AppRoutes.accountType,
        builder: (_, _) => const AccountTypeSelectionScreen(),
      ),
      GoRoute(
        path: AppRoutes.setupClient,
        builder: (_, _) => const ClientProfileSetupScreen(),
      ),
      GoRoute(
        path: AppRoutes.setupProvider,
        builder: (_, _) => const WorkProviderProfileSetupScreen(),
      ),
      GoRoute(
        path: AppRoutes.setupMarketplace,
        builder: (_, _) => const MarketplaceProfileSetupScreen(),
      ),
      GoRoute(
        path: AppRoutes.pendingVerification,
        builder: (_, _) => const VerificationPendingScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        redirect: (_, state) {
          final userDoc = ref.read(currentUserDocProvider).value;
          return resolveAuthenticatedRoute(userDoc?.toJson());
        },
      ),
      ShellRoute(
        builder: (context, state, child) {
          return MainScaffoldWrapper(
            location: state.matchedLocation,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: AppRoutes.clientHome,
            builder: (_, _) => const ClientHomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.providerHome,
            builder: (_, _) => const ProviderHomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.marketplaceHome,
            builder: (_, _) => const MarketplaceHomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.bestProviders,
            builder: (_, _) => const BestProvidersScreen(),
          ),
          GoRoute(
            path: AppRoutes.messages,
            builder: (_, _) => const ConversationsListScreen(),
          ),
          GoRoute(
            path: AppRoutes.aiChat,
            builder: (_, _) => const ChatHistoryPage(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (_, _) => const EditProfileScreen(),
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
                double.tryParse(state.uri.queryParameters['radius'] ?? '') ??
                10,
            minimumRating:
                double.tryParse(state.uri.queryParameters['minRating'] ?? '') ??
                0,
            availableOnly: state.uri.queryParameters['availableOnly'] == 'true',
            originLatitude:
                double.tryParse(state.uri.queryParameters['lat'] ?? '') ?? 0,
            originLongitude:
                double.tryParse(state.uri.queryParameters['lng'] ?? '') ?? 0,
            originLabel: state.uri.queryParameters['label'] ?? 'Search area',
          );
        },
      ),
      GoRoute(
        path: '/messages/:conversationId',
        builder: (context, state) => ChatScreen(
          conversationId: state.pathParameters['conversationId']!,
          otherName: state.uri.queryParameters['otherName'],
        ),
      ),
      GoRoute(path: '/ai-chat/session', builder: (_, _) => const AIChatPage()),
      GoRoute(
        path: '/provider-profile/:id',
        builder: (context, state) =>
            ProviderProfileScreen(uid: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/merchant-profile/:id',
        builder: (context, state) =>
            MerchantProfileScreen(uid: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/reviews/:providerId',
        builder: (context, state) =>
            ReviewsScreen(providerId: state.pathParameters['providerId']!),
      ),
      GoRoute(
        path: '/profile/:userId',
        builder: (context, state) =>
            PublicProfileScreen(userId: state.pathParameters['userId']!),
      ),
      GoRoute(
        path: '/rate-service/:providerId',
        builder: (context, state) =>
            RateServiceScreen(providerId: state.pathParameters['providerId']!),
      ),
      GoRoute(path: '/favorites', builder: (_, _) => const FavoritesScreen()),
      GoRoute(
        path: '/notifications',
        builder: (_, _) => const NotificationsScreen(),
      ),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
      GoRoute(
        path: '/language',
        builder: (_, _) => const LanguageSelectorScreen(),
      ),
      GoRoute(path: '/admin', builder: (_, _) => const AdminDashboardScreen()),
      GoRoute(
        path: '/admin/users',
        builder: (_, _) => const AdminDashboardScreen(initialSection: 1),
      ),
      GoRoute(
        path: '/admin/verifications',
        builder: (_, _) => const AdminDashboardScreen(initialSection: 2),
      ),
      GoRoute(
        path: '/admin/reports',
        builder: (_, _) => const AdminDashboardScreen(initialSection: 3),
      ),
      GoRoute(
        path: '/admin/reviews',
        builder: (_, _) => const AdminDashboardScreen(initialSection: 4),
      ),
    ],
  );
}
