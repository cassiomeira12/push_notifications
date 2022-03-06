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

  FirebasePushNotification({
    this.onClickNotification,
    this.initialNotificationsTopics,
    this.onUpdateToken,
    required this.localPush,
  }) {
    _repository = FirebasePushNotificationRepository(
      localPush: localPush,
      onUpdateToken: onUpdateToken,
      onClickNotification: onClickNotification,
      initialNotificationsTopics: initialNotificationsTopics,
    );
  }

  bool get notificationAuthorized => _repository.notificationAuthorized;

  static Future<void> initialize() async {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  Future<void> subscribeToTopic(String topic, {String? topicName}) {
    return _repository.subscribeToTopic(topic, topicName: topicName);
  }

  Future<void> unsubscribeFromTopic(String topic, {String? topicName}) {
    return _repository.unsubscribeFromTopic(topic, topicName: topicName);
  }
}

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}
