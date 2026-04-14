import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_application_1/views/app_colors.dart';
import 'package:flutter_application_1/routes/app_router.dart';
import 'package:flutter_application_1/providers/locale_provider.dart';
import 'package:flutter_application_1/l10n/app_localizations.dart';

/// A Riverpod provider that creates the [GoRouter] exactly **once** and keeps
/// it alive for the entire app session. The router's own [refreshListenable]
/// already handles auth/user-data changes, so there is no need to rebuild it
/// when providers change.
final _appRouterProvider = Provider<GoRouter>((ref) {
  return buildAppRouter(ref);
});

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProviderScope(child: NearWorkApp());
  }
}

class NearWorkApp extends ConsumerWidget {
  const NearWorkApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(appLocaleProvider);
    // Read the router from the provider — it is created once and reused.
    final router = ref.watch(_appRouterProvider);

    return MaterialApp.router(
      title: 'NearWork',
      debugShowCheckedModeBanner: false,
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
