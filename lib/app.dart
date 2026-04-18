import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/constants/app_colors.dart';

class NearWorkApp extends ConsumerWidget {
  const NearWorkApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'NearWork',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.accentBlue,
          surface: AppColors.primaryBackground,
        ),
        scaffoldBackgroundColor: AppColors.primaryBackground,
      ),
      routerConfig: appRouter,
    );
  }
}
