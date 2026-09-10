// File generated for FlutterFire.
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
      case TargetPlatform.windows:
        return web;
      case TargetPlatform.macOS:
        return web;
      case TargetPlatform.linux:
        return web;
      case TargetPlatform.iOS:
        return android;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBSvuW7tfAuwCMoe4E9Ks3XOI3YZTjf8Dw',
    appId: '1:319455985483:web:ea45119eb1797a9643b2ce',
    messagingSenderId: '319455985483',
    projectId: 'rhythm-39358',
    authDomain: 'rhythm-39358.firebaseapp.com',
    storageBucket: 'rhythm-39358.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBSvuW7tfAuwCMoe4E9Ks3XOI3YZTjf8Dw',
    appId: '1:319455985483:android:ea45119eb1797a9643b2ce',
    messagingSenderId: '319455985483',
    projectId: 'rhythm-39358',
    storageBucket: 'rhythm-39358.firebasestorage.app',
  );
}
