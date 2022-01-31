import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:push_notifications/src/repository/local_notification_repository.dart';

import '../domain/local_notification_interface.dart';

class LocalPushNotification implements LocalNotificationInterface {
  late LocalNotificationRepository _repository;

  final String channelID;
  final String channelName;
  final String channelDescription;

  final Color? color;
  final ValueChanged<Map<String, dynamic>>? onClickNotification;

  LocalPushNotification({
    required this.channelID,
    required this.channelName,
    required this.channelDescription,
    this.color,
    this.onClickNotification,
  }) {
    _repository = LocalNotificationRepository(
      channelID: channelID,
      channelName: channelName,
      channelDescription: channelDescription,
      color: color,
      onClickNotification: onClickNotification,
    );
  }

  bool get notificationAuthorized => _repository.notificationAuthorized;

  @override
  void cancelAllNotifications() {
    return _repository.cancelAllNotifications();
  }

  @override
  void cancelNotification(int id) {
    return _repository.cancelNotification(id);
  }

  @override
  Future<int> showNotification({
    String? title,
    String? body,
    payload,
    String? image,
  }) {
    return _repository.showNotification(
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
    return _repository.showNotificationAt(
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
    return _repository.showNotificationPeriodically(
      title: title,
      body: body,
      payload: payload,
      image: image,
    );
  }
}
