import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:queue/src/core/constants/app_constants.dart';
import 'package:queue/src/core/location/location_service.dart';
import 'package:queue/src/core/services/bootstrap_service.dart';
import 'package:queue/src/core/services/notification_preferences_repository.dart';
import 'package:queue/src/core/services/notification_service.dart';
import 'package:queue/src/core/theme/app_theme.dart';
import 'package:queue/src/core/widgets/loading_view.dart';
import 'package:queue/src/features/app/presentation/root_shell.dart';
import 'package:queue/src/features/app/presentation/setup_required_screen.dart';
import 'package:queue/src/features/auth/data/firebase_auth_repository.dart';
import 'package:queue/src/features/auth/domain/auth_repository.dart';
import 'package:queue/src/features/auth/presentation/controllers/auth_controller.dart';
import 'package:queue/src/features/auth/presentation/screens/auth_screen.dart';
import 'package:queue/src/features/home/presentation/controllers/home_controller.dart';
import 'package:queue/src/shared/repositories/firebase_storage_repository.dart';
import 'package:queue/src/shared/repositories/firestore_feedback_repository.dart';
import 'package:queue/src/shared/repositories/firestore_places_repository.dart';
import 'package:queue/src/shared/repositories/firestore_queue_repository.dart';

class QueueLessApp extends StatelessWidget {
  const QueueLessApp({super.key, required this.bootstrapState});

  final BootstrapState bootstrapState;

  @override
  Widget build(BuildContext context) {
    if (!bootstrapState.firebaseReady) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: AppConstants.appName,
        theme: AppTheme.light,
        home: SetupRequiredScreen(
          message: bootstrapState.errorMessage ?? 'Missing setup values.',
        ),
      );
    }

    return MultiProvider(
      providers: [
        Provider<AuthRepository>(
          create: (_) => FirebaseAuthRepository(
            auth: FirebaseAuth.instance,
            firestore: FirebaseFirestore.instance,
          ),
        ),
        Provider(
          create: (_) => FirestorePlacesRepository(FirebaseFirestore.instance),
        ),
        Provider(
          create: (_) => FirestoreQueueRepository(FirebaseFirestore.instance),
        ),
        Provider(
          create: (_) => FirebaseStorageRepository(FirebaseStorage.instance),
        ),
        Provider(
          create: (_) =>
              FirestoreFeedbackRepository(FirebaseFirestore.instance),
        ),
        Provider(create: (_) => LocationService()),
        ChangeNotifierProvider(
          create: (context) => AuthController(context.read<AuthRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              HomeController(context.read<LocationService>())
                ..loadUserLocation(),
        ),
        Provider(
          create: (context) => NotificationPreferencesRepository(
            firestore: FirebaseFirestore.instance,
            messaging: FirebaseMessaging.instance,
            authRepository: context.read<AuthRepository>(),
          ),
        ),
        Provider(
          create: (context) => NotificationService(
            messaging: FirebaseMessaging.instance,
            authRepository: context.read<AuthRepository>(),
            localNotifications: FlutterLocalNotificationsPlugin(),
          )..initialize(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: AppConstants.appName,
        theme: AppTheme.light,
        home: const _AuthGate(),
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final authRepository = context.read<AuthRepository>();

    return StreamBuilder<User?>(
      stream: authRepository.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: LoadingView());
        }

        if (snapshot.data != null) {
          return const RootShell();
        }

        return const AuthScreen();
      },
    );
  }
}
