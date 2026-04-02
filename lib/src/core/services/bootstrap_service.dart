import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:queue/src/core/errors/app_exception.dart';
import 'package:queue/src/core/services/app_firebase_options.dart';

class BootstrapState {
  const BootstrapState({
    required this.firebaseReady,
    this.errorMessage,
    this.googleMapsApiKey = '',
  });

  final bool firebaseReady;
  final String? errorMessage;
  final String googleMapsApiKey;

  bool get mapsReady => googleMapsApiKey.isNotEmpty;
}

class BootstrapService {
  static const String _googleMapsApiKey =
      'AIzaSyBvQMSl3e5HXtrJ-eqpLce_FjYEiagPgPY';

  static Future<BootstrapState> initialize() async {
    const mapsApiKey = _googleMapsApiKey;

    try {
      await Firebase.initializeApp(options: AppFirebaseOptions.currentPlatform);
      if (!kIsWeb) {
        await FirebaseMessaging.instance.requestPermission();
      }
      return BootstrapState(firebaseReady: true, googleMapsApiKey: mapsApiKey);
    } on AppConfigurationException catch (error) {
      return BootstrapState(
        firebaseReady: false,
        googleMapsApiKey: mapsApiKey,
        errorMessage:
            '${error.message}\n\nFirebase is configured in code now, but Google Maps still needs native/web platform setup.',
      );
    } on FirebaseException catch (error) {
      return BootstrapState(
        firebaseReady: false,
        googleMapsApiKey: mapsApiKey,
        errorMessage:
            'Firebase initialization failed: ${error.message ?? 'Unknown Firebase error.'}',
      );
    } catch (error) {
      return BootstrapState(
        firebaseReady: false,
        googleMapsApiKey: mapsApiKey,
        errorMessage: 'Bootstrap failed: $error',
      );
    }
  }

  static String buildRunCommand() {
    return [
      'flutter run',
      '--dart-define=FIREBASE_PROJECT_ID=your-project-id',
      '--dart-define=FIREBASE_MESSAGING_SENDER_ID=your-sender-id',
      '--dart-define=FIREBASE_STORAGE_BUCKET=your-project.appspot.com',
      '--dart-define=FIREBASE_ANDROID_API_KEY=your-android-api-key',
      '--dart-define=FIREBASE_ANDROID_APP_ID=your-android-app-id',
      '--dart-define=FIREBASE_IOS_API_KEY=your-ios-api-key',
      '--dart-define=FIREBASE_IOS_APP_ID=your-ios-app-id',
      '--dart-define=FIREBASE_IOS_BUNDLE_ID=com.queueless.app',
    ].join(' ');
  }
}
