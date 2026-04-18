import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

// Screen Imports
import '../../features/auth/welcome_screen.dart';
import '../../features/auth/account_type_screen.dart';
import '../../features/auth/signup_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/auth/email_verification_screen.dart';

import '../../features/client/screens/client_home_screen.dart';
import '../../features/client/screens/client_profile_screen.dart';

import '../../features/work_provider/profile/provider_profile_screen.dart';
import '../../features/work_provider/profile/provider_setup_screen.dart';
import '../../features/work_provider/screens/wp_home_screen.dart';
import '../../features/work_provider/screens/wp_profile_screen.dart';
import '../../features/work_provider/screens/wp_search_screen.dart';

import '../../features/marketplace/screens/mp_home_screen.dart';
import '../../features/marketplace/screens/mp_profile_screen.dart';
import '../../features/marketplace/screens/mp_search_screen.dart';
import '../../features/marketplace/profile/merchant_profile_screen.dart';
import '../../features/marketplace/profile/merchant_setup_screen.dart';

import '../../features/shared/messages/conversations_list_screen.dart';
import '../../features/shared/messages/chat_screen.dart';
import '../../features/shared/notifications/notifications_screen.dart';
import '../../features/shared/settings/settings_screen.dart';
import '../../features/shared/ai_chat/screens/ai_chat_sessions_screen.dart';
import '../../features/shared/ai_chat/screens/ai_chat_session_screen.dart';
import '../../features/shared/search/screens/search_filter_screen.dart';
import '../../features/shared/search/screens/search_results_screen.dart';
import '../../features/shared/search/models/search_filter_model.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  redirect: (context, state) async {
    final user = FirebaseAuth.instance.currentUser;
    final bool isLoggingIn = state.matchedLocation == '/login' ||
        state.matchedLocation == '/signup' ||
        state.matchedLocation == '/splash';

    if (user == null && !isLoggingIn) return '/login';

    // Admin access restriction
    if (user != null && state.matchedLocation.startsWith('/admin')) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final accountType = doc.data()?['accountType'];
        if (accountType == 'work_provider') return '/wp-home';
        if (accountType == 'marketplace') return '/mp-home';
      }
      final userType = await AuthService().getUserType(user.uid);
      if (userType == UserType.client) return '/home';
    }

    // Redirect /home based on accountType
    if (user != null && state.matchedLocation == '/home') {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final accountType = doc.data()?['accountType'];
        if (accountType == 'work_provider') return '/wp-home';
        if (accountType == 'marketplace') return '/mp-home';
      }
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
      path: '/email-verification',
      builder: (context, state) => const EmailVerificationScreen(),
    ),

    // ── Client ──────────────────────────────────────────────────
    GoRoute(
      path: '/home',
      builder: (context, state) => const ClientHomeScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ClientProfileScreen(),
    ),

    // ── Shared Search ────────────────────────────────────────────
    GoRoute(
      path: '/search-filter',
      builder: (context, state) {
        final target =
            state.uri.queryParameters['target'] ?? 'work_provider';
        final excludeId = state.uri.queryParameters['excludeId'];
        return SearchFilterScreen(target: target, excludeId: excludeId);
      },
    ),
    GoRoute(
      path: '/search-results',
      builder: (context, state) {
        // Receives SearchFilterModel via GoRouter extra
        final filter = state.extra as SearchFilterModel? ??
            SearchFilterModel(
              target: state.uri.queryParameters['target'] ?? 'work_provider',
            );
        return SearchResultsScreen(filter: filter);
      },
    ),

    // ── Messaging ────────────────────────────────────────────────
    GoRoute(
      path: '/messages',
      builder: (context, state) => const ConversationsListScreen(),
    ),
    GoRoute(
      path: '/chat/:id',
      builder: (context, state) => ChatScreen(
        conversationId: state.pathParameters['id']!,
      ),
    ),

    // ── AI Chat ──────────────────────────────────────────────────
    GoRoute(
      path: '/ai-chat',
      builder: (context, state) => const AiChatSessionsScreen(),
    ),
    GoRoute(
      path: '/ai-chat/session',
      builder: (context, state) {
        final sessionId = state.uri.queryParameters['sessionId'];
        if (sessionId == null) return const AiChatSessionsScreen();
        return AiChatSessionScreen(sessionId: sessionId);
      },
    ),

    // ── Notifications ────────────────────────────────────────────
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),

    // ── Work Provider ────────────────────────────────────────────
    GoRoute(
      path: '/wp-home',
      builder: (context, state) => const WpHomeScreen(),
    ),
    GoRoute(
      path: '/wp-profile',
      builder: (context, state) => const WpProfileScreen(),
    ),
    GoRoute(
      path: '/wp-search',
      builder: (context, state) => const WpSearchScreen(),
    ),
    GoRoute(
      path: '/provider-setup',
      builder: (context, state) => const ProviderSetupScreen(),
    ),
    GoRoute(
      path: '/provider-profile/:id',
      builder: (context, state) =>
          ProviderProfileScreen(uid: state.pathParameters['id']!),
    ),

    // ── Marketplace ──────────────────────────────────────────────
    GoRoute(
      path: '/mp-home',
      builder: (context, state) => const MpHomeScreen(),
    ),
    GoRoute(
      path: '/mp-profile',
      builder: (context, state) => const MpProfileScreen(),
    ),
    GoRoute(
      path: '/mp-search',
      builder: (context, state) => const MpSearchScreen(),
    ),
    GoRoute(
      path: '/merchant-setup',
      builder: (context, state) => const MerchantSetupScreen(),
    ),
    GoRoute(
      path: '/merchant-profile/:id',
      builder: (context, state) =>
          MerchantProfileScreen(uid: state.pathParameters['id']!),
    ),

    // ── Settings ─────────────────────────────────────────────────
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
