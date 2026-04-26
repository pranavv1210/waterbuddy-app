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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBDH8TLcO_vfDQ2wl_72bj09UT06PDPsbo',
    appId: '1:979686341816:android:97e8ddabcc303846fec84d',
    messagingSenderId: '979686341816',
    projectId: 'waterbuddy-edcf7',
    authDomain: 'waterbuddy-edcf7.firebaseapp.com',
    storageBucket: 'waterbuddy-edcf7.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBDH8TLcO_vfDQ2wl_72bj09UT06PDPsbo',
    appId: '1:979686341816:android:97e8ddabcc303846fec84d',
    messagingSenderId: '979686341816',
    projectId: 'waterbuddy-edcf7',
    storageBucket: 'waterbuddy-edcf7.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBDH8TLcO_vfDQ2wl_72bj09UT06PDPsbo',
    appId: '1:979686341816:android:97e8ddabcc303846fec84d',
    messagingSenderId: '979686341816',
    projectId: 'waterbuddy-edcf7',
    storageBucket: 'waterbuddy-edcf7.firebasestorage.app',
    iosBundleId: 'com.waterbuddy.customer',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBDH8TLcO_vfDQ2wl_72bj09UT06PDPsbo',
    appId: '1:979686341816:android:97e8ddabcc303846fec84d',
    messagingSenderId: '979686341816',
    projectId: 'waterbuddy-edcf7',
    storageBucket: 'waterbuddy-edcf7.firebasestorage.app',
    iosBundleId: 'com.waterbuddy.customer',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBDH8TLcO_vfDQ2wl_72bj09UT06PDPsbo',
    appId: '1:979686341816:android:97e8ddabcc303846fec84d',
    messagingSenderId: '979686341816',
    projectId: 'waterbuddy-edcf7',
    authDomain: 'waterbuddy-edcf7.firebaseapp.com',
    storageBucket: 'waterbuddy-edcf7.firebasestorage.app',
  );
}
