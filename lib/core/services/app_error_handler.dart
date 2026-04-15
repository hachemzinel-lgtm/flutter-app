import 'package:flutter/material.dart';

final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class AppErrorHandler {
  static void handleFlutterError(FlutterErrorDetails details) {
    FlutterError.presentError(details);
    showError(
      details.exception,
      details.stack ?? StackTrace.current,
      userMessage: 'Something went wrong. Please try again.',
    );
  }

  static bool handlePlatformError(Object error, StackTrace stackTrace) {
    showError(
      error,
      stackTrace,
      userMessage: 'Something went wrong. Please try again.',
    );
    return true;
  }

  static void showError(
    Object error,
    StackTrace stackTrace, {
    String userMessage = 'Something went wrong. Please try again.',
  }) {
    FlutterError.reportError(
      FlutterErrorDetails(exception: error, stack: stackTrace),
    );
    showMessage(userMessage);
  }

  static void showMessage(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final messenger = rootScaffoldMessengerKey.currentState;
      if (messenger == null) {
        return;
      }

      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
        );
    });
  }

  static Widget buildErrorWidget(FlutterErrorDetails details) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      handleFlutterError(details);
    });

    return Material(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
              SizedBox(height: 12),
              Text(
                'Something went wrong on this screen.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
