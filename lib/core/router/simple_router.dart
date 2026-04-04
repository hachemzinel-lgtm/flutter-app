import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/simple_home_screen.dart';
import '../../features/auth/presentation/pages/simple_login_screen.dart';
import '../../features/auth/presentation/pages/simple_signup_screen.dart';

GoRouter buildSimpleRouter() {
  return GoRouter(
    initialLocation: '/debug-auth/signup',
    routes: buildSimpleAuthRoutes(),
  );
}

List<RouteBase> buildSimpleAuthRoutes() {
  return [
    GoRoute(
      path: '/debug-auth/signup',
      builder: (context, state) => const SimpleSignupScreen(),
    ),
    GoRoute(
      path: '/debug-auth/login',
      builder: (context, state) => const SimpleLoginScreen(),
    ),
    GoRoute(
      path: '/debug-auth/home',
      builder: (context, state) => const SimpleHomeScreen(),
    ),
  ];
}
