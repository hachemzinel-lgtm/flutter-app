import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'app.dart';
import 'firebase_options.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Catch and log any initialization errors globally
    FlutterError.onError = (FlutterErrorDetails details) {
      debugPrint('Flutter error: ${details.exception}');
    };

    // Load environment variables safely
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      debugPrint('Failed to load .env: $e');
    }

    // Initialize Firebase
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    // Initialize AppCheck using PlayIntegrity to prevent the 'No Provider' crash or debug limits
    try {
      await FirebaseAppCheck.instance.activate(
        // ignore: deprecated_member_use
        androidProvider: kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
        // ignore: deprecated_member_use
        appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.deviceCheck,
      );
    } catch (e) {
      debugPrint('AppCheck init error: $e');
    }

    runApp(const ProviderScope(child: NearWorkApp()));
  } catch (e) {
    debugPrint('Critical initialization error: $e');
    // Run a fallback app if Firebase couldn't initialize
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text(
            'App Initialization Failed:\n$e',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ));
  }
}
