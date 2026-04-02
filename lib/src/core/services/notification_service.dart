import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:queue/src/features/auth/domain/auth_repository.dart';

class NotificationService {
  NotificationService({
    required FirebaseMessaging messaging,
    required AuthRepository authRepository,
    required FlutterLocalNotificationsPlugin localNotifications,
  }) : _messaging = messaging,
       _authRepository = authRepository,
       _localNotifications = localNotifications;

  final FirebaseMessaging _messaging;
  final AuthRepository _authRepository;
  final FlutterLocalNotificationsPlugin _localNotifications;

  Future<void> initialize() async {
    final currentUser = _authRepository.currentUser;
    if (currentUser == null) {
      return;
    }

    if (!kIsWeb) {
      await _initializeLocalNotifications();
    }

    final token = await _messaging.getToken();
    if (token != null && token.isNotEmpty) {
      await _authRepository.updatePushToken(token);
    }

    _messaging.onTokenRefresh.listen(_authRepository.updatePushToken);
    FirebaseMessaging.onMessage.listen(_showForegroundMessage);
  }

  Future<void> _initializeLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
  }

  Future<void> _showForegroundMessage(RemoteMessage message) async {
    if (kIsWeb || message.notification == null) {
      return;
    }

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'QueueLess update',
      message.notification?.body ?? '',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'queueless_updates',
          'QueueLess Updates',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}
