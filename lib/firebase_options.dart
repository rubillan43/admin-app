// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web not configured.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
            'DefaultFirebaseOptions not configured for this platform.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyASwFgyqjV3xd6OCrE9W-GgsG4mzUkxwTs',
    appId: '1:1028460968862:android:f03593b5af07bdfcedf48f',
    messagingSenderId: '1028460968862',
    projectId: 'utm-lost-found',
    databaseURL:
        'https://utm-lost-found-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'utm-lost-found.firebasestorage.app',
  );
}
