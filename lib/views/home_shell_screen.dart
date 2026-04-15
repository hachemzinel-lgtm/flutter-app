import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_application_1/providers/auth_providers.dart';
import 'package:flutter_application_1/routes/route_paths.dart';
import 'package:flutter_application_1/views/admin_dashboard_screen.dart';
import 'package:flutter_application_1/views/client_home_screen.dart';
import 'package:flutter_application_1/views/marketplace_home_screen.dart';
import 'package:flutter_application_1/views/work_provider_home_screen.dart';

class HomeShellScreen extends ConsumerWidget {
  const HomeShellScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userDataAsync = ref.watch(currentUserDataProvider);
    final userDocAsync = ref.watch(currentUserDocProvider);

    if (userDataAsync.isLoading ||
        (userDataAsync.value?['accountType'] != 'admin' &&
            userDocAsync.isLoading)) {
      return const LoadingScreen();
    }

    if (userDataAsync.hasError) {
      return ErrorScreen(message: 'Unable to load account data.');
    }

    final normalizedAccountType = AppRoutes.normalizeAccountType(
      userDataAsync.value?['accountType']?.toString(),
    );

    switch (normalizedAccountType) {
      case 'client':
        return const ClientHomeScreen();
      case 'workProvider':
        return const WorkProviderHomeScreen();
      case 'marketplace':
        return const MarketplaceHomeScreen();
      case 'admin':
        return const AdminDashboardScreen();
      case null:
        return const LoadingScreen();
      default:
        return const ErrorScreen(message: 'Unknown account type');
    }
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class ErrorScreen extends StatelessWidget {
  const ErrorScreen({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text(message)));
  }
}
