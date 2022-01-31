import 'dart:ui';

import 'package:flutter/widgets.dart';

import '../push_notifications.dart';
import 'application/local_push_notification.dart';
import 'domain/internal_push_notification_interface.dart';

class PushNotification implements InternalPushNotificationInterface {
  late LocalPushNotification _pushNotification;
  late FirebasePushNotification? _firebaseNotification;

  final String channelID = 'push_notification';

  final String channelName = 'Notificação';
  final String channelDescription = 'Notificação do aplicativo';

  final Color? color;
  final ValueChanged<String>? updateToken;
  final Function? initialNotificationsTopics;
  final ValueChanged<Map<String, dynamic>>? onClickNotification;

  PushNotification({
    this.color,
    this.updateToken,
    this.initialNotificationsTopics,
    this.onClickNotification,
  }) {
    _pushNotification = LocalPushNotification(
      color: color,
      channelID: channelID,
      channelName: channelName,
      channelDescription: channelDescription,
      onClickNotification: onClickNotification,
    );
    _firebaseNotification = FirebasePushNotification(
      localPush: _pushNotification,
      onUpdateToken: updateToken,
      onClickNotification: onClickNotification,
      initialNotificationsTopics: initialNotificationsTopics,
    );
  }

  bool get notificationAuthorized {
    return _firebaseNotification?.notificationAuthorized ??
        _pushNotification.notificationAuthorized;
  }

  @override
  Future<int> showNotification({
    String? title,
    String? body,
    payload,
    String? image,
  }) {
    return _pushNotification.showNotification(
      title: title,
      body: body,
      payload: payload,
      image: image,
    );
  }

  @override
  Future<int> showNotificationAt({
    required DateTime time,
    String? title,
    String? body,
    payload,
    String? image,
  }) {
    return _pushNotification.showNotificationAt(
      time: time,
      title: title,
      body: body,
      payload: payload,
      image: image,
    );
  }

  @override
  Future<int> showNotificationPeriodically({
    String? title,
    String? body,
    payload,
    String? image,
  }) {
    return _pushNotification.showNotificationPeriodically(
      title: title,
      body: body,
      payload: payload,
      image: image,
    );
  }

  @override
  Future<void> subscribeToTopic(String topic, {String? topicName}) async {
    return _firebaseNotification?.subscribeToTopic(
      topic,
      topicName: topicName,
    );
  }

  @override
  Future<void> unsubscribeFromTopic(String topic, {String? topicName}) async {
    return _firebaseNotification?.unsubscribeFromTopic(
      topic,
      topicName: topicName,
    );
  }

  @override
  void cancelAllNotifications() {
    return _pushNotification.cancelAllNotifications();
  }

  @override
  void cancelNotification(int id) {
    return _pushNotification.cancelNotification(id);
  }
}
