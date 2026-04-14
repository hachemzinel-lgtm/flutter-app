import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_application_1/views/ai_chat_page.dart';
import 'package:flutter_application_1/views/chat_history_page.dart';
import 'package:flutter_application_1/views/account_type_selection_screen.dart';
import 'package:flutter_application_1/views/email_verification_screen.dart';
import 'package:flutter_application_1/views/forgot_password_screen.dart';
import 'package:flutter_application_1/views/login_screen.dart';
import 'package:flutter_application_1/views/pending_verification_screen.dart';
import 'package:flutter_application_1/views/signup_screen.dart';
import 'package:flutter_application_1/views/welcome_screen.dart';
import 'package:flutter_application_1/views/setup_client_screen.dart';
import 'package:flutter_application_1/views/setup_marketplace_screen.dart';
import 'package:flutter_application_1/providers/setup_provider_screen.dart';
import 'package:flutter_application_1/providers/auth_providers.dart';
import 'package:flutter_application_1/views/chat_screen.dart';
import 'package:flutter_application_1/views/conversations_list_screen.dart';
import 'package:flutter_application_1/views/favorites_screen.dart';
import 'package:flutter_application_1/providers/best_providers_screen.dart';
import 'package:flutter_application_1/views/client_home_screen.dart';
import 'package:flutter_application_1/views/marketplace_home_screen.dart';
import 'package:flutter_application_1/providers/provider_home_screen.dart';
import 'package:flutter_application_1/views/notifications_screen.dart';
import 'package:flutter_application_1/views/marketplace_profile_screen.dart'
    as new_marketplace_profile;
import 'package:flutter_application_1/providers/provider_profile_screen.dart'
    as new_provider_profile;
import 'package:flutter_application_1/views/edit_profile_screen.dart';
import 'package:flutter_application_1/views/public_profile_screen.dart';
import 'package:flutter_application_1/views/rate_client_screen.dart'
    as new_rate_client;
import 'package:flutter_application_1/services/rate_service_screen.dart'
    as new_rate_service;
import 'package:flutter_application_1/views/reviews_screen.dart';
import 'package:flutter_application_1/views/search_params.dart';
import 'package:flutter_application_1/views/search_results_screen.dart';
import 'package:flutter_application_1/views/search_screen.dart';
import 'package:flutter_application_1/views/language_selector_screen.dart';
import 'package:flutter_application_1/views/settings_screen.dart';
import 'package:flutter_application_1/views/main_scaffold_wrapper.dart';
import 'package:flutter_application_1/views/top_rated_screen.dart';
import 'package:flutter_application_1/routes/route_paths.dart';
import 'simple_router.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

Stream<void> _combinedStream() {
  final controller = StreamController<void>.broadcast();
  StreamSubscription<User?>? authSubscription;
  StreamSubscription<dynamic>? userDocSubscription;

  void emit() {
    if (!controller.isClosed) {
      controller.add(null);
    }
  }

  authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
    userDocSubscription?.cancel();
    emit();

    if (user != null) {
      userDocSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((_) => emit(), onError: (_) {});
    }
  }, onError: (_) {});

  controller.onCancel = () async {
    await authSubscription?.cancel();
    await userDocSubscription?.cancel();
  };

  return controller.stream;
}

GoRouter buildAppRouter(Ref ref) {
  return GoRouter(
    initialLocation: AppRoutes.welcome,
    refreshListenable: GoRouterRefreshStream(_combinedStream()),
    redirect: (context, state) {
      final location = state.matchedLocation;
      final authValue = ref.read(authStateProvider);
      final userDataValue = ref.read(currentUserDataProvider);

      if (authValue.isLoading) {
        return null;
      }

      final user = authValue.value;

      if (user == null) {
        const publicRoutes = <String>{
          AppRoutes.welcome,
          AppRoutes.login,
          AppRoutes.signup,
          AppRoutes.forgotPassword,
        };
        return publicRoutes.contains(location) ? null : AppRoutes.welcome;
      }

      if (!user.emailVerified) {
        return location == AppRoutes.emailVerification
            ? null
            : AppRoutes.emailVerification;
      }

      if (userDataValue.isLoading) {
        return null;
      }

      final userData = userDataValue.value;
      final normalizedAccountType = AppRoutes.normalizeAccountType(
        userData?['accountType']?.toString(),
      );

      if (normalizedAccountType == null) {
        return location == AppRoutes.accountType ? null : AppRoutes.accountType;
      }

      final profileComplete =
          userData?['profileComplete'] == true ||
          userData?['profileCompleted'] == true;
      final expectedSetupRoute = AppRoutes.setupForAccountType(
        normalizedAccountType,
      );

      if (!profileComplete) {
        return location == expectedSetupRoute ? null : expectedSetupRoute;
      }

      const authFlowRoutes = <String>{
        AppRoutes.welcome,
        AppRoutes.login,
        AppRoutes.signup,
        AppRoutes.forgotPassword,
        AppRoutes.emailVerification,
        AppRoutes.accountType,
        AppRoutes.setupClient,
        AppRoutes.setupProvider,
        AppRoutes.setupMarketplace,
      };

      if (location == AppRoutes.home) {
        return AppRoutes.homeForAccountType(normalizedAccountType);
      }

      if (authFlowRoutes.contains(location)) {
        return AppRoutes.homeForAccountType(normalizedAccountType);
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
        builder: (_, _) => const ForgotPasswordPage(),
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
        builder: (_, _) => const SetupClientScreen(),
      ),
      GoRoute(
        path: AppRoutes.setupProvider,
        builder: (_, _) => const SetupProviderScreen(),
      ),
      GoRoute(
        path: AppRoutes.setupMarketplace,
        builder: (_, _) => const SetupMarketplaceScreen(),
      ),
      GoRoute(
        path: AppRoutes.pendingVerification,
        builder: (_, _) => const PendingVerificationPage(),
      ),
      ...buildSimpleAuthRoutes(),
      GoRoute(
        path: AppRoutes.home,
        redirect: (_, _) {
          final userData = ref.read(currentUserDataProvider).value;
          return resolveAuthenticatedRoute(userData);
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
            path: '/top-rated',
            builder: (_, _) => const TopRatedScreen(),
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
          final params = state.extra as SearchParams;
          return SearchResultsScreen(params: params);
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
        builder: (context, state) => new_provider_profile.ProviderProfileScreen(
          id: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/marketplace-profile/:id',
        builder: (context, state) =>
            new_marketplace_profile.MarketplaceProfileScreen(
              id: state.pathParameters['id']!,
            ),
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
        builder: (context, state) => new_rate_service.RateServiceScreen(
          targetId: state.pathParameters['providerId']!,
        ),
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
      GoRoute(path: '/search', builder: (_, _) => const SearchScreen()),
      GoRoute(
        path: '/rate-client/:clientId',
        builder: (context, state) => new_rate_client.RateClientScreen(
          clientId: state.pathParameters['clientId']!,
        ),
      ),
    ],
  );
}
