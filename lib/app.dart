import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_application_1/core/router/app_router.dart';
import 'package:flutter_application_1/core/services/app_error_handler.dart';
import 'package:flutter_application_1/core/services/user_migration_service.dart';
import 'package:flutter_application_1/l10n/app_localizations.dart';
import 'package:flutter_application_1/models/user_model.dart';
import 'package:flutter_application_1/providers/auth_providers.dart';
import 'package:flutter_application_1/providers/locale_provider.dart';
import 'package:flutter_application_1/views/app_colors.dart';

final _appRouterProvider = Provider<GoRouter>((ref) {
  ref.watch(userMigrationControllerProvider);
  return buildAppRouter(ref);
});

// ✅ FIX: Create the router ONCE using a Provider, not inside build()
final appRouterProvider = Provider<GoRouter>((ref) {
  return buildAppRouter(ref);
});

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      observers: const [_GlobalProviderErrorObserver()],
      child: const NearWorkApp(),
    );
  }
}

class NearWorkApp extends ConsumerStatefulWidget {
  const NearWorkApp({super.key});

  @override
  ConsumerState<NearWorkApp> createState() => _NearWorkAppState();
}

class _NearWorkAppState extends ConsumerState<NearWorkApp> {
  ProviderSubscription<AsyncValue<User?>>? _authSubscription;
  ProviderSubscription<AsyncValue<Map<String, dynamic>?>>?
  _userDataSubscription;
  ProviderSubscription<AsyncValue<UserModel?>>? _userDocSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = ref.listenManual<AsyncValue<User?>>(authStateProvider, (
      _,
      next,
    ) {
      next.whenOrNull(
        error: (error, stackTrace) {
          AppErrorHandler.showError(
            error,
            stackTrace,
            userMessage: 'We could not refresh your session right now.',
          );
        },
      );
      _handleAuthChange(next.asData?.value);
    });
    _userDataSubscription = ref.listenManual<AsyncValue<Map<String, dynamic>?>>(
      currentUserDataProvider,
      (_, next) {
        next.whenOrNull(
          error: (error, stackTrace) {
            AppErrorHandler.showError(
              error,
              stackTrace,
              userMessage: 'We could not refresh your account data.',
            );
          },
        );
      },
    );
    _userDocSubscription = ref.listenManual<AsyncValue<UserModel?>>(
      currentUserDocProvider,
      (_, next) {
        next.whenOrNull(
          error: (error, stackTrace) {
            AppErrorHandler.showError(
              error,
              stackTrace,
              userMessage: 'We could not refresh your profile data.',
            );
          },
        );
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleAuthChange(ref.read(authStateProvider).asData?.value);
    });
  }

  void _handleAuthChange(User? user) {
    final controller = ref.read(userMigrationControllerProvider.notifier);
    if (user == null) {
      controller.reset();
      return;
    }

    controller.cleanupDuplicateProfileField();
  }

  @override
  void dispose() {
    _authSubscription?.close();
    _userDataSubscription?.close();
    _userDocSubscription?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(appLocaleProvider);
    final router = ref.watch(_appRouterProvider);

    return MaterialApp.router(
      title: 'NearWork',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      locale: locale,
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      theme: ThemeData(
        useMaterial3: true,
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

final class _GlobalProviderErrorObserver extends ProviderObserver {
  const _GlobalProviderErrorObserver();

  @override
  void providerDidFail(
    ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    AppErrorHandler.showError(
      error,
      stackTrace,
      userMessage: 'Something went wrong. Please try again.',
    );
  }
}
