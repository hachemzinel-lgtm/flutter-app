import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_application_1/core/services/user_migration_service.dart';
import 'package:flutter_application_1/core/widgets/role_aware_scaffold.dart';
import 'package:flutter_application_1/providers/auth_providers.dart';
import 'package:flutter_application_1/providers/best_providers_screen.dart';
import 'package:flutter_application_1/providers/setup_provider_screen.dart';
import 'package:flutter_application_1/providers/provider_profile_screen.dart'
    as provider_profile;
import 'package:flutter_application_1/services/rate_service_screen.dart'
    as rate_service;
import 'package:flutter_application_1/routes/route_paths.dart';
import 'package:flutter_application_1/routes/simple_router.dart';
import 'package:flutter_application_1/views/account_type_selection_screen.dart';
import 'package:flutter_application_1/views/admin_dashboard_screen.dart';
import 'package:flutter_application_1/views/ai_chat_page.dart';
import 'package:flutter_application_1/views/chat_history_page.dart';
import 'package:flutter_application_1/views/chat_screen.dart';
import 'package:flutter_application_1/views/conversations_list_screen.dart';
import 'package:flutter_application_1/views/edit_profile_screen.dart';
import 'package:flutter_application_1/views/email_verification_screen.dart';
import 'package:flutter_application_1/views/favorites_screen.dart';
import 'package:flutter_application_1/views/forgot_password_screen.dart';
import 'package:flutter_application_1/views/home_shell_screen.dart';
import 'package:flutter_application_1/views/language_selector_screen.dart';
import 'package:flutter_application_1/views/login_screen.dart';
import 'package:flutter_application_1/views/marketplace_profile_screen.dart'
    as marketplace_profile;
import 'package:flutter_application_1/views/notifications_screen.dart';
import 'package:flutter_application_1/views/pending_verification_screen.dart';
import 'package:flutter_application_1/views/public_profile_screen.dart';
import 'package:flutter_application_1/views/rate_client_screen.dart'
    as rate_client;
import 'package:flutter_application_1/views/reviews_screen.dart';
import 'package:flutter_application_1/views/search_params.dart';
import 'package:flutter_application_1/views/search_results_screen.dart';
import 'package:flutter_application_1/views/search_screen.dart';
import 'package:flutter_application_1/views/settings_screen.dart';
import 'package:flutter_application_1/views/setup_client_screen.dart';
import 'package:flutter_application_1/views/setup_marketplace_screen.dart';
import 'package:flutter_application_1/views/signup_screen.dart';
import 'package:flutter_application_1/views/top_rated_screen.dart';
import 'package:flutter_application_1/views/welcome_screen.dart';

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
  final authValue = ref.watch(authProvider);
  final migrationState = ref.watch(userMigrationControllerProvider);

  return GoRouter(
    initialLocation: AppRoutes.welcome,
    refreshListenable: GoRouterRefreshStream(_combinedStream()),
    redirect: (context, state) {
      final routeName = state.name;
      final userDataValue = ref.read(currentUserDataProvider);
      final userDocValue = ref.read(currentUserDocProvider);

      if (authValue.isLoading) {
        return null;
      }

      if (authValue.hasError) {
        return null;
      }

      final authUser = authValue.asData?.value;
      if (authUser == null) {
        return AppRoutes.publicRouteNames.contains(routeName)
            ? null
            : state.namedLocation(AppRoutes.loginName);
      }

      if (migrationState.completedUid != authUser.uid) {
        return null;
      }

      if (userDataValue.isLoading || userDataValue.hasError) {
        return null;
      }

      final userData = userDataValue.asData?.value;
      final rawAccountType = userData?['accountType']?.toString();
      final normalizedAccountType = AppRoutes.normalizeAccountType(
        rawAccountType,
      );
      final emailVerified =
          userData?['emailVerified'] == true || authUser.emailVerified;
      final profileComplete = userData?['profileComplete'] == true;

      if (normalizedAccountType != null &&
          normalizedAccountType != 'admin' &&
          userDocValue.isLoading) {
        return null;
      }

      if (userDocValue.hasError) {
        return null;
      }

      if (!emailVerified) {
        return routeName == AppRoutes.emailVerificationName
            ? null
            : state.namedLocation(AppRoutes.emailVerificationName);
      }

      if (normalizedAccountType == 'admin') {
        return routeName == AppRoutes.adminName
            ? null
            : state.namedLocation(AppRoutes.adminName);
      }

      if (routeName == AppRoutes.adminName) {
        return state.namedLocation(AppRoutes.homeName);
      }

      if (normalizedAccountType == null) {
        return routeName == AppRoutes.accountTypeName
            ? null
            : state.namedLocation(AppRoutes.accountTypeName);
      }

      final setupRouteName = AppRoutes.setupNameForAccountType(
        normalizedAccountType,
      );

      if (!profileComplete) {
        return routeName == setupRouteName
            ? null
            : state.namedLocation(setupRouteName);
      }

      if (AppRoutes.onboardingRouteNames.contains(routeName) ||
          routeName == AppRoutes.clientHomeName ||
          routeName == AppRoutes.providerHomeName ||
          routeName == AppRoutes.marketplaceHomeName) {
        return state.namedLocation(AppRoutes.homeName);
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.welcome,
        name: AppRoutes.welcomeName,
        builder: (_, _) => const WelcomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        name: AppRoutes.signupName,
        builder: (_, _) => const SignupScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: AppRoutes.loginName,
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: AppRoutes.forgotPasswordName,
        builder: (_, _) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: AppRoutes.emailVerification,
        name: AppRoutes.emailVerificationName,
        builder:
            (_, state) => EmailVerificationScreen(
              email: state.extra is String ? state.extra as String : null,
            ),
      ),
      GoRoute(
        path: AppRoutes.accountType,
        name: AppRoutes.accountTypeName,
        builder: (_, _) => const AccountTypeSelectionScreen(),
      ),
      GoRoute(
        path: AppRoutes.setupClient,
        name: AppRoutes.setupClientName,
        builder: (_, _) => const SetupClientScreen(),
      ),
      GoRoute(
        path: AppRoutes.setupProvider,
        name: AppRoutes.setupProviderName,
        builder: (_, _) => const SetupProviderScreen(),
      ),
      GoRoute(
        path: AppRoutes.setupMarketplace,
        name: AppRoutes.setupMarketplaceName,
        builder: (_, _) => const SetupMarketplaceScreen(),
      ),
      GoRoute(
        path: AppRoutes.pendingVerification,
        name: AppRoutes.pendingVerificationName,
        builder: (_, _) => const PendingVerificationPage(),
      ),
      GoRoute(
        path: AppRoutes.admin,
        name: AppRoutes.adminName,
        builder: (_, _) => const AdminDashboardScreen(),
      ),
      ...buildSimpleAuthRoutes(),
      GoRoute(
        path: AppRoutes.clientHome,
        name: AppRoutes.clientHomeName,
        builder: (_, _) => const SizedBox.shrink(),
        redirect: (context, state) => state.namedLocation(AppRoutes.homeName),
      ),
      GoRoute(
        path: AppRoutes.providerHome,
        name: AppRoutes.providerHomeName,
        builder: (_, _) => const SizedBox.shrink(),
        redirect: (context, state) => state.namedLocation(AppRoutes.homeName),
      ),
      GoRoute(
        path: AppRoutes.marketplaceHome,
        name: AppRoutes.marketplaceHomeName,
        builder: (_, _) => const SizedBox.shrink(),
        redirect: (context, state) => state.namedLocation(AppRoutes.homeName),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return RoleAwareScaffold(
            location: state.matchedLocation,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: AppRoutes.home,
            name: AppRoutes.homeName,
            builder: (_, _) => const HomeShellScreen(),
          ),
          GoRoute(
            path: AppRoutes.search,
            name: AppRoutes.searchName,
            builder: (_, _) => const SearchScreen(),
          ),
          GoRoute(
            path: AppRoutes.aiChat,
            name: AppRoutes.aiChatName,
            builder: (_, _) => const ChatHistoryPage(),
          ),
          GoRoute(
            path: AppRoutes.chatBot,
            name: AppRoutes.chatBotName,
            builder: (_, _) => const AIChatPage(),
          ),
          GoRoute(
            path: AppRoutes.messages,
            name: AppRoutes.messagesName,
            builder: (_, _) => const ConversationsListScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            name: AppRoutes.profileName,
            builder: (_, _) => const EditProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.bestProviders,
        name: AppRoutes.bestProvidersName,
        builder: (_, _) => const BestProvidersScreen(),
      ),
      GoRoute(
        path: AppRoutes.topRated,
        name: AppRoutes.topRatedName,
        builder: (_, _) => const TopRatedScreen(),
      ),
      GoRoute(
        path: AppRoutes.searchResults,
        name: AppRoutes.searchResultsName,
        builder: (context, state) {
          final params = state.extra as SearchParams;
          return SearchResultsScreen(params: params);
        },
      ),
      GoRoute(
        path: '${AppRoutes.messages}/:conversationId',
        name: AppRoutes.messageThreadName,
        builder:
            (context, state) => ChatScreen(
              conversationId: state.pathParameters['conversationId']!,
              otherName: state.uri.queryParameters['otherName'],
            ),
      ),
      GoRoute(
        path: '/ai-chat/session',
        name: AppRoutes.aiChatSessionName,
        builder: (_, _) => const AIChatPage(),
      ),
      GoRoute(
        path: '/provider-profile/:id',
        name: AppRoutes.providerProfileName,
        builder:
            (context, state) => provider_profile.ProviderProfileScreen(
              id: state.pathParameters['id']!,
            ),
      ),
      GoRoute(
        path: '/marketplace-profile/:id',
        name: AppRoutes.marketplaceProfileName,
        builder:
            (context, state) => marketplace_profile.MarketplaceProfileScreen(
              id: state.pathParameters['id']!,
            ),
      ),
      GoRoute(
        path: '/reviews/:providerId',
        name: AppRoutes.reviewsName,
        builder:
            (context, state) =>
                ReviewsScreen(providerId: state.pathParameters['providerId']!),
      ),
      GoRoute(
        path: '/profile/:userId',
        name: AppRoutes.publicProfileName,
        builder:
            (context, state) =>
                PublicProfileScreen(userId: state.pathParameters['userId']!),
      ),
      GoRoute(
        path: '/rate-service/:providerId',
        name: AppRoutes.rateServiceName,
        builder:
            (context, state) => rate_service.RateServiceScreen(
              targetId: state.pathParameters['providerId']!,
            ),
      ),
      GoRoute(
        path: AppRoutes.favorites,
        name: AppRoutes.favoritesName,
        builder: (_, _) => const FavoritesScreen(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        name: AppRoutes.notificationsName,
        builder: (_, _) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: AppRoutes.settingsName,
        builder: (_, _) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.language,
        name: AppRoutes.languageName,
        builder: (_, _) => const LanguageSelectorScreen(),
      ),
      GoRoute(
        path: '/rate-client/:clientId',
        name: AppRoutes.rateClientName,
        builder:
            (context, state) => rate_client.RateClientScreen(
              clientId: state.pathParameters['clientId']!,
            ),
      ),
    ],
  );
}
