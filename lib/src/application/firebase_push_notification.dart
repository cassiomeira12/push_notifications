import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:push_notifications/src/domain/local_notification_interface.dart';

import '../repository/firebase_push_notification_repository.dart';

class FirebasePushNotification {
  late FirebasePushNotificationRepository _repository;

  final Function? onClickNotification;
  final Function? initialNotificationsTopics;
  final ValueChanged<String>? onUpdateToken;

  final LocalNotificationInterface localPush;

  final Function(Map<String, dynamic>)? receiveNotification;

  FirebasePushNotification({
    this.onClickNotification,
    this.initialNotificationsTopics,
    this.onUpdateToken,
    required this.localPush,
    this.receiveNotification,
  }) {
    _repository = FirebasePushNotificationRepository(
      localPush: localPush,
      onUpdateToken: onUpdateToken,
      onClickNotification: onClickNotification,
      initialNotificationsTopics: initialNotificationsTopics,
      receiveNotification: receiveNotification,
    );
  }

  bool get notificationAuthorized => _repository.notificationAuthorized;

  static Future<void> initialize({
    Future<void> Function(RemoteMessage)? onBackgroundMessage,
  }) async {
    await initializeFirebase();
    FirebaseMessaging.onBackgroundMessage(
      onBackgroundMessage ?? _firebaseOnBackgroundMessage,
    );
  }

  static Future<void> initializeFirebase() async {
    await Firebase.initializeApp();
  }

  Future<void> subscribeToTopic(String topic, {String? topicName}) {
    return _repository.subscribeToTopic(topic, topicName: topicName);
  }

  Future<void> unsubscribeFromTopic(String topic, {String? topicName}) {
    return _repository.unsubscribeFromTopic(topic, topicName: topicName);
  }
}

Future<void> _firebaseOnBackgroundMessage(RemoteMessage message) async {
  await Firebase.initializeApp();
}
