import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:queue/src/features/auth/domain/auth_repository.dart';

class NotificationPreferencesRepository {
  NotificationPreferencesRepository({
    required FirebaseFirestore firestore,
    required FirebaseMessaging messaging,
    required AuthRepository authRepository,
  }) : _firestore = firestore,
       _messaging = messaging,
       _authRepository = authRepository;

  final FirebaseFirestore _firestore;
  final FirebaseMessaging _messaging;
  final AuthRepository _authRepository;

  Future<void> setShortQueueAlert({
    required String placeId,
    required bool enabled,
  }) async {
    final user = _authRepository.currentUser;
    if (user == null) return;

    if (!kIsWeb) {
      final topic = 'place_${placeId}_short';
      if (enabled) {
        await _messaging.subscribeToTopic(topic);
      } else {
        await _messaging.unsubscribeFromTopic(topic);
      }
    }

    await _firestore.collection('users').doc(user.uid).set({
      'shortQueueSubscriptions': {placeId: enabled},
    }, SetOptions(merge: true));
  }
}
