// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBo7X2H6ZzKy--p1YO6VVBiUdjR_yvC2ec',
    appId: '1:1087212337546:android:ab5f7cd100cea1c434f073',
    messagingSenderId: '1087212337546',
    projectId: 'shinqy818',
    storageBucket: 'shinqy818.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDh7rGRieDopOdzr2rYJADd-FfFghDCJ88',
    appId: '1:1087212337546:ios:acaf5412d6ead73c34f073',
    messagingSenderId: '1087212337546',
    projectId: 'shinqy818',
    storageBucket: 'shinqy818.firebasestorage.app',
    iosBundleId: 'com.example.flutterApplication1',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBKStgzbxc5NC4VODtEK2CEcNzSMo1JX-w',
    appId: '1:1087212337546:web:2be067014197389c34f073',
    messagingSenderId: '1087212337546',
    projectId: 'shinqy818',
    authDomain: 'shinqy818.firebaseapp.com',
    storageBucket: 'shinqy818.firebasestorage.app',
    measurementId: 'G-HQ15CXFL2V',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDh7rGRieDopOdzr2rYJADd-FfFghDCJ88',
    appId: '1:1087212337546:ios:acaf5412d6ead73c34f073',
    messagingSenderId: '1087212337546',
    projectId: 'shinqy818',
    storageBucket: 'shinqy818.firebasestorage.app',
    iosBundleId: 'com.example.flutterApplication1',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBKStgzbxc5NC4VODtEK2CEcNzSMo1JX-w',
    appId: '1:1087212337546:web:2198616e7d3dde2a34f073',
    messagingSenderId: '1087212337546',
    projectId: 'shinqy818',
    authDomain: 'shinqy818.firebaseapp.com',
    storageBucket: 'shinqy818.firebasestorage.app',
    measurementId: 'G-MS077SWV4T',
  );

}