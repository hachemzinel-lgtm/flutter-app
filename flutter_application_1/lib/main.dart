import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'app.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  // Note: Replace with your actual configurations or use flutterfire configure
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Initialize App Check to prevent warnings during Firebase Auth
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug, // Change to playIntegrity for production
    appleProvider: AppleProvider.debug, // Change to appAttest for production
  );

  runApp(const ProviderScope(child: NearWorkApp()));
}
