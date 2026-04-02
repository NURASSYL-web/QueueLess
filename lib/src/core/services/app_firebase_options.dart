import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:queue/src/core/errors/app_exception.dart';

class AppFirebaseOptions {
  const AppFirebaseOptions._();

  static const String _projectId = 'queueless-15a3e';
  static const String _messagingSenderId = '75681666771';
  static const String _storageBucket = 'queueless-15a3e.firebasestorage.app';

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return _web;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _android;
      case TargetPlatform.iOS:
        return _ios;
      case TargetPlatform.macOS:
        return _ios;
      case TargetPlatform.linux:
      case TargetPlatform.windows:
      case TargetPlatform.fuchsia:
        throw const AppConfigurationException(
          'QueueLess currently supports Android and iOS Firebase configuration.',
        );
    }
  }

  static FirebaseOptions get _web => const FirebaseOptions(
    apiKey: 'AIzaSyB3-H8RIa7WyRmTj9EBFg6JmtoOHA5kn0U',
    appId: '1:75681666771:web:1df39d781d62c9c7c8e626',
    messagingSenderId: _messagingSenderId,
    projectId: _projectId,
    storageBucket: _storageBucket,
    authDomain: 'queueless-15a3e.firebaseapp.com',
    measurementId: 'G-R7BQJ3MXBY',
  );

  static FirebaseOptions get _android => FirebaseOptions(
    apiKey: 'AIzaSyDjHV8VZBu4HdLm-IwdDWDF6sKxTosQeyU',
    appId: '1:75681666771:android:c64711badd871eeac8e626',
    messagingSenderId: _messagingSenderId,
    projectId: _projectId,
    storageBucket: _storageBucket,
  );

  static FirebaseOptions get _ios => const FirebaseOptions(
    apiKey: 'AIzaSyAqSF7z2gKtRBROaiOYrDWFu5apQaagsx0',
    appId: '1:75681666771:ios:25b8810784d1d142c8e626',
    messagingSenderId: _messagingSenderId,
    projectId: _projectId,
    storageBucket: _storageBucket,
    iosBundleId: 'com.queueless.app',
  );
}
