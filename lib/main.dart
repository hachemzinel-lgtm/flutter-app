import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:flutter_application_1/firebase_options.dart';
import 'package:flutter_application_1/app.dart';
import 'package:flutter_application_1/core/services/app_error_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = AppErrorHandler.handleFlutterError;
  PlatformDispatcher.instance.onError = AppErrorHandler.handlePlatformError;
  ErrorWidget.builder = AppErrorHandler.buildErrorWidget;
  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}
