import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/constants/app_colors.dart';
import 'core/router/app_router.dart';
import 'features/settings/providers/locale_provider.dart';
import 'l10n/app_localizations.dart';

// ✅ FIX: Create the router ONCE using a Provider, not inside build()
final appRouterProvider = Provider<GoRouter>((ref) {
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
    // ✅ FIX: Watch the provider — same GoRouter instance is reused

    final router = ref.watch(appRouterProvider);

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
