class AppRoutes {
  static const welcome = '/welcome';
  static const login = '/login';
  static const signup = '/signup';
  static const forgotPassword = '/forgot-password';
  static const emailVerification = '/email-verification';
  static const accountType = '/account-type';
  static const setupClient = '/setup-client';
  static const setupProvider = '/setup-provider';
  static const setupMarketplace = '/setup-marketplace';
  static const pendingVerification = '/pending-verification';
  static const clientHome = '/client-home';
  static const providerHome = '/provider-home';
  static const marketplaceHome = '/marketplace-home';
  static const home = '/home';
  static const bestProviders = '/best-providers';
  static const messages = '/messages';
  static const aiChat = '/ai-chat';
  static const profile = '/profile';

  static const publicRoutes = <String>{welcome, login, signup, forgotPassword};

  static const setupRoutes = <String>{
    accountType,
    setupClient,
    setupProvider,
    setupMarketplace,
    pendingVerification,
  };

  static String? normalizeAccountType(String? value) {
    switch (value) {
      case 'client':
        return 'client';
      case 'workProvider':
      case 'work_provider':
      case 'provider':
      case 'serviceProvider':
        return 'workProvider';
      case 'marketplace':
      case 'merchant':
      case 'business':
        return 'marketplace';
      default:
        return null;
    }
  }

  static String setupForAccountType(String? rawAccountType) {
    switch (normalizeAccountType(rawAccountType)) {
      case 'workProvider':
        return setupProvider;
      case 'marketplace':
        return setupMarketplace;
      case 'client':
      default:
        return setupClient;
    }
  }

  static String homeForAccountType(String? rawAccountType) {
    switch (normalizeAccountType(rawAccountType)) {
      case 'workProvider':
        return providerHome;
      case 'marketplace':
        return marketplaceHome;
      case 'client':
      default:
        return clientHome;
    }
  }
}

String resolveAuthenticatedRoute(Map<String, dynamic>? userData) {
  if (userData == null) {
    return AppRoutes.accountType;
  }

  final accountType = AppRoutes.normalizeAccountType(
    userData['accountType']?.toString(),
  );
  final profileComplete =
      userData['profileComplete'] == true ||
      userData['profileCompleted'] == true;

  if (accountType == null) {
    return AppRoutes.accountType;
  }

  if (!profileComplete) {
    return AppRoutes.setupForAccountType(accountType);
  }

  return AppRoutes.homeForAccountType(accountType);
}
