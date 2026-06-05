import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAqXPy9seNoVmXpfcmhNEyGE1K0sq0WaIY',
    appId: '1:1036991138403:web:ec78fa9d667641b42e0656',
    messagingSenderId: '1036991138403',
    projectId: 'intern-task-7038a',
    authDomain: 'intern-task-7038a.firebaseapp.com',
    storageBucket: 'intern-task-7038a.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAqXPy9seNoVmXpfcmhNEyGE1K0sq0WaIY',
    appId: '1:1036991138403:android:76ed139631172a972e0656',
    messagingSenderId: '1036991138403',
    projectId: 'intern-task-7038a',
    storageBucket: 'intern-task-7038a.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAqXPy9seNoVmXpfcmhNEyGE1K0sq0WaIY',
    appId: '1:1036991138403:ios:3e311a52cec4b95f2e0656',
    messagingSenderId: '1036991138403',
    projectId: 'intern-task-7038a',
    storageBucket: 'intern-task-7038a.firebasestorage.app',
    iosBundleId: 'com.example.internFinal',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAqXPy9seNoVmXpfcmhNEyGE1K0sq0WaIY',
    appId: '1:1036991138403:ios:3e311a52cec4b95f2e0656',
    messagingSenderId: '1036991138403',
    projectId: 'intern-task-7038a',
    storageBucket: 'intern-task-7038a.firebasestorage.app',
    iosBundleId: 'com.example.internFinal',
  );
}
