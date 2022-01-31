import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:push_notifications/src/domain/local_notification_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/firebase_push_notification_interface.dart';

class FirebasePushNotificationRepository
    implements FirebasePushNotificationInterface {
  final LocalNotificationInterface localPush;
  final Function? onClickNotification;
  final Function? initialNotificationsTopics;
  final ValueChanged<String>? onUpdateToken;

  bool notificationAuthorized = false;

  FirebasePushNotificationRepository({
    required this.localPush,
    this.onClickNotification,
    this.initialNotificationsTopics,
    this.onUpdateToken,
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

      dynamic data = message?.data;

      if (data != null) {
        if (data['click_action'] != null) {
          dynamic map = data['click_action'];
          Map<String, dynamic> json = jsonDecode(map);
          onClickNotification?.call(json);
        } else {
          onClickNotification?.call(data);
        }
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

      dynamic data = message.data;

      if (data['click_action'] != null) {
        dynamic map = data['click_action'];
        Map<String, dynamic> json = jsonDecode(map);
        onClickNotification?.call(json);
      } else {
        onClickNotification?.call(data);
      }
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

      var map = {
        'notification': {
          'title': notification.title,
          'body': notification.body,
        },
        'image': image,
        'data': message.data,
      };

      if (Platform.isAndroid) {
        _pushNotification(map);
      }
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
