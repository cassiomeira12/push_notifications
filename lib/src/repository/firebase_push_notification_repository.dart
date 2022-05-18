import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/firebase_push_notification_interface.dart';
import '../domain/local_notification_interface.dart';
import '../domain/notification_model.dart';

class FirebasePushNotificationRepository
    implements FirebasePushNotificationInterface {
  final LocalNotificationInterface localPush;
  final Function? onClickNotification;
  final Function? initialNotificationsTopics;
  final ValueChanged<String>? onUpdateToken;
  final Function(Map<String, dynamic>)? receiveNotification;

  bool notificationAuthorized = false;

  FirebasePushNotificationRepository({
    required this.localPush,
    this.onClickNotification,
    this.initialNotificationsTopics,
    this.onUpdateToken,
    this.receiveNotification,
  }) {
    firebaseCloudMessageListeners();
  }

  @override
  Future<void> firebaseCloudMessageListeners() async {
    NotificationSettings permission = await _requestPermission();

    if (permission.authorizationStatus == AuthorizationStatus.authorized) {
      notificationAuthorized = true;
      initialNotificationsTopics?.call();
    }

    debugPrint(
        'iOS Firebase Notification permissions [${notificationAuthorized ? 'ok' : 'error'}]');

    try {
      var token = await FirebaseMessaging.instance.getToken() ?? '';
      if (kDebugMode) debugPrint("NOTIFICATION TOKEN [$token]");
      onUpdateToken?.call(token);
    } catch (error) {
      debugPrint(error.toString());
    }

    openNotificationToStartApp();
    openNotificationWhenAppRunning();
    receiveNotificationWhenAppRunning();
  }

  Future<NotificationSettings> _requestPermission() async {
    NotificationSettings result;
    if (Platform.isMacOS || Platform.isIOS) {
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      result = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        announcement: true,
        badge: true,
        carPlay: true,
        sound: true,
      );
    } else {
      result = await FirebaseMessaging.instance.requestPermission(
        announcement: true,
        carPlay: true,
        criticalAlert: true,
      );
    }
    return result;
  }

  @override
  void openNotificationToStartApp() {
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? message) async {
      if (Platform.isIOS && message?.messageId != null) {
        var prefs = await SharedPreferences.getInstance();
        var result = prefs.getBool(message!.messageId!);
        prefs.remove(message.messageId!);
        if (result ?? false) {
          return;
        }
      }

      if (message?.notification != null) {
        RemoteNotification notification = message!.notification!;
        String? image;
        if (notification.android != null) {
          image = notification.android!.imageUrl;
        }
        if (notification.apple != null) {
          image = notification.apple!.imageUrl;
        }

        dynamic data = message.data;

        image ??= data['image'];

        final notificationModel = PushNotificationModel(
          id: message.messageId,
          title: notification.title ?? '',
          body: notification.body ?? '',
          image: image,
          data: message.data,
        );

        if (data['click_action'] != null) {
          dynamic action = data['click_action'];
          notificationModel.data = jsonDecode(action);
        }

        onClickNotification?.call(notificationModel.toMap());
      }
    });
  }

  @override
  void openNotificationWhenAppRunning() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      if (Platform.isIOS && message.messageId != null) {
        var prefs = await SharedPreferences.getInstance();
        prefs.setBool(message.messageId!, true);
      }

      RemoteNotification notification = message.notification!;
      String? image;
      if (notification.android != null) {
        image = notification.android!.imageUrl;
      }
      if (notification.apple != null) {
        image = notification.apple!.imageUrl;
      }

      dynamic data = message.data;

      image ??= data['image'];

      final notificationModel = PushNotificationModel(
        id: message.messageId,
        title: notification.title ?? '',
        body: notification.body ?? '',
        image: image,
        data: message.data,
      );

      if (data['click_action'] != null) {
        dynamic action = data['click_action'];
        notificationModel.data = jsonDecode(action);
      }

      onClickNotification?.call(notificationModel.toMap());
    });
  }

  @override
  void receiveNotificationWhenAppRunning() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification notification = message.notification!;
      String? image;
      if (notification.android != null) {
        image = notification.android!.imageUrl;
      }
      if (notification.apple != null) {
        image = notification.apple!.imageUrl;
      }

      dynamic data = message.data;

      image ??= data['image'];

      final notificationModel = PushNotificationModel(
        id: message.messageId,
        title: notification.title ?? '',
        body: notification.body ?? '',
        image: image,
        data: message.data,
      );

      if (Platform.isAndroid) {
        _pushNotification(notificationModel.toMap());
      }

      if (data['click_action'] != null) {
        dynamic action = data['click_action'];
        notificationModel.data = jsonDecode(action);
      }

      receiveNotification?.call(notificationModel.toMap());
    });
  }

  void _pushNotification(Map<String, dynamic> message) {
    String? title, body, payload, image;
    if (message.containsKey('data') && message['data'] != null) {
      var data = message['data'];
      if (data['click_action'] == null) {
        payload = jsonEncode(data);
      } else {
        payload = data['click_action'];
      }
    } else {
      payload = message['click_action'];
    }
    if (message.containsKey('notification')) {
      var notification = message['notification'];
      title = notification['title'];
      body = notification['body'];
      image = message['image'];

      localPush.showNotification(
        title: title,
        body: body,
        payload: payload,
        image: image,
      );
    }
  }

  @override
  Future<void> subscribeToTopic(String topic, {String? topicName}) async {
    debugPrint('subscribeToTopic [$topic]');
    await FirebaseMessaging.instance.subscribeToTopic(topic);
  }

  @override
  Future<void> unsubscribeFromTopic(String topic, {String? topicName}) async {
    debugPrint('unsubscribeFromTopic [$topic]');
    await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
  }
}
