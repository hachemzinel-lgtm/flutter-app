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
  static const home = '/home';
  static const admin = '/admin';
  static const clientHome = '/client-home';
  static const providerHome = '/provider-home';
  static const marketplaceHome = '/marketplace-home';
  static const bestProviders = '/best-providers';
  static const messages = '/messages';
  static const aiChat = '/ai-chat';
  static const chatBot = '/chat-bot';
  static const profile = '/profile';
  static const topRated = '/top-rated';
  static const search = '/search';
  static const searchResults = '/search-results';
  static const favorites = '/favorites';
  static const notifications = '/notifications';
  static const settings = '/settings';
  static const language = '/language';

  static const welcomeName = 'welcome';
  static const loginName = 'login';
  static const signupName = 'signup';
  static const forgotPasswordName = 'forgot-password';
  static const emailVerificationName = 'email-verification';
  static const accountTypeName = 'account-type';
  static const setupClientName = 'setup-client';
  static const setupProviderName = 'setup-provider';
  static const setupMarketplaceName = 'setup-marketplace';
  static const pendingVerificationName = 'pending-verification';
  static const homeName = 'home';
  static const adminName = 'admin';
  static const clientHomeName = 'client-home';
  static const providerHomeName = 'provider-home';
  static const marketplaceHomeName = 'marketplace-home';
  static const bestProvidersName = 'best-providers';
  static const messagesName = 'messages';
  static const messageThreadName = 'message-thread';
  static const aiChatName = 'ai-chat';
  static const chatBotName = 'chatBot';
  static const aiChatSessionName = 'ai-chat-session';
  static const topRatedName = 'top-rated';
  static const profileName = 'profile';
  static const publicProfileName = 'public-profile';
  static const providerProfileName = 'provider-profile';
  static const marketplaceProfileName = 'marketplace-profile';
  static const searchName = 'search';
  static const searchResultsName = 'search-results';
  static const reviewsName = 'reviews';
  static const rateServiceName = 'rate-service';
  static const rateClientName = 'rate-client';
  static const favoritesName = 'favorites';
  static const notificationsName = 'notifications';
  static const settingsName = 'settings';
  static const languageName = 'language';

  static const publicRoutes = <String>{welcome, login, signup, forgotPassword};

  static const publicRouteNames = <String>{
    welcomeName,
    loginName,
    signupName,
    forgotPasswordName,
  };

  static const onboardingRouteNames = <String>{
    welcomeName,
    loginName,
    signupName,
    forgotPasswordName,
    emailVerificationName,
    accountTypeName,
    setupClientName,
    setupProviderName,
    setupMarketplaceName,
    pendingVerificationName,
  };

  static const adminBlockedRouteNames = <String>{
    homeName,
    searchName,
    aiChatName,
    messagesName,
    profileName,
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
      case 'admin':
        return 'admin';
      default:
        return null;
    }
  }

  static bool isAdminAccountType(String? value) {
    return normalizeAccountType(value) == 'admin';
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

  static String setupNameForAccountType(String? rawAccountType) {
    switch (normalizeAccountType(rawAccountType)) {
      case 'workProvider':
        return setupProviderName;
      case 'marketplace':
        return setupMarketplaceName;
      case 'client':
      default:
        return setupClientName;
    }
  }

  static String homeForAccountType(String? rawAccountType) {
    switch (normalizeAccountType(rawAccountType)) {
      case 'admin':
        return admin;
      case 'client':
      case 'workProvider':
      case 'marketplace':
      default:
        return home;
    }
  }

  static String homeNameForAccountType(String? rawAccountType) {
    switch (normalizeAccountType(rawAccountType)) {
      case 'admin':
        return adminName;
      case 'client':
      case 'workProvider':
      case 'marketplace':
      default:
        return homeName;
    }
  }
}

String resolveAuthenticatedRoute(Map<String, dynamic>? userData) {
  final normalizedAccountType = AppRoutes.normalizeAccountType(
    userData?['accountType']?.toString(),
  );
  final emailVerified = userData?['emailVerified'] == true;
  final profileComplete = userData?['profileComplete'] == true;

  if (!emailVerified) {
    return AppRoutes.emailVerification;
  }

  if (normalizedAccountType == 'admin') {
    return AppRoutes.admin;
  }

  if (normalizedAccountType == null) {
    return AppRoutes.accountType;
  }

  if (!profileComplete) {
    return AppRoutes.setupForAccountType(normalizedAccountType);
  }

  return AppRoutes.home;
}
