import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:push_notifications/src/domain/request_permissions_interface.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../domain/local_notification_interface.dart';

class LocalNotificationRepository
    implements LocalNotificationInterface, RequestPermissionsInterface {
  final _notification = FlutterLocalNotificationsPlugin();

  final String channelID;
  final String channelName;
  final String channelDescription;

  final Color? color;
  final ValueChanged<Map<String, dynamic>>? onClickNotification;

  bool notificationAuthorized = false;

  LocalNotificationRepository({
    required this.channelID,
    required this.channelName,
    required this.channelDescription,
    this.color,
    this.onClickNotification,
  }) {
    requestPermissions();
    _init();
  }

  _init() async {
    await _configureLocalTimeZone();
    _notification.initialize(
      InitializationSettings(
        android: _androidSettings(),
        iOS: _iOSSettings(),
        macOS: _macOSSettings(),
        // linux: _linuxSettings(),
      ),
      onSelectNotification: (payload) {
        var map = {'payload': payload};
        return onClickNotification?.call(map);
      },
    );
  }

  AndroidInitializationSettings _androidSettings() {
    return const AndroidInitializationSettings('ic_stat_notification');
  }

  IOSInitializationSettings _iOSSettings() {
    return IOSInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
      onDidReceiveLocalNotification: (id, title, body, payload) {
        var map = {
          'id': id,
          'notification': {
            'title': title,
            'body': body,
          },
          'payload': payload,
        };
        return onClickNotification?.call(map);
      },
    );
  }

  MacOSInitializationSettings _macOSSettings() {
    return const MacOSInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
    );
  }

  @override
  Future<void> requestPermissions() async {
    if (Platform.isIOS) {
      await _notification
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          )
          .then((permission) {
        notificationAuthorized = permission ?? false;
        debugPrint(
            'iOS Local Notification permissions [${notificationAuthorized ? 'ok' : 'error'}]');
      });
    }
    if (Platform.isMacOS) {
      await _notification
          .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          )
          .then((permission) {
        notificationAuthorized = permission ?? false;
        debugPrint(
            'MacOS Local Notification permissions [${notificationAuthorized ? 'ok' : 'error'}]');
      });
    }
  }

  Future<void> _configureLocalTimeZone() async {
    if (kIsWeb || Platform.isLinux) {
      return;
    }
    tz.initializeTimeZones();
    final String? timeZoneName = await FlutterNativeTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName!));
  }

  int _notificationId() {
    var date = DateTime.now();
    return date.millisecond;
  }

  Future<NotificationDetails> _createNotificationDetails(image) async {
    BigPictureStyleInformation? pictureStyleInformation;
    IOSNotificationDetails? iOSPlatformChannelSpecifics;
    MacOSNotificationDetails? macOSPlatformChannelSpecifics;

    if (image != null) {
      final bigPicture = ByteArrayAndroidBitmap(
        await _getByteArrayFromUrl(image),
      );
      pictureStyleInformation = BigPictureStyleInformation(
        bigPicture,
        largeIcon: bigPicture,
      );
      final String bigPicturePath = await _downloadAndSaveFile(
        image,
        'image.jpg',
      );

      iOSPlatformChannelSpecifics = IOSNotificationDetails(
        badgeNumber: 0,
        presentSound: true,
        presentAlert: true,
        presentBadge: true,
        attachments: <IOSNotificationAttachment>[
          IOSNotificationAttachment(bigPicturePath)
        ],
      );
      macOSPlatformChannelSpecifics = MacOSNotificationDetails(
        badgeNumber: 0,
        presentSound: true,
        presentAlert: true,
        presentBadge: true,
        attachments: <MacOSNotificationAttachment>[
          MacOSNotificationAttachment(bigPicturePath)
        ],
      );
    }

    final Int64List vibrationPattern = Int64List(4);
    vibrationPattern[0] = 0;
    vibrationPattern[1] = 1000;
    vibrationPattern[2] = 5000;
    vibrationPattern[3] = 2000;

    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      channelID,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.max,
      enableVibration: true,
      vibrationPattern: vibrationPattern,
      color: color,
      ledColor: color,
      enableLights: color != null,
      ledOnMs: 1000,
      ledOffMs: 500,
      ticker: 'ticker',
      playSound: true,
      visibility: NotificationVisibility.public,
      styleInformation:
          pictureStyleInformation ?? const DefaultStyleInformation(true, true),
    );
    var platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics ??
          const IOSNotificationDetails(
            badgeNumber: 0,
            presentSound: true,
            presentAlert: true,
            presentBadge: true,
          ),
      macOS: macOSPlatformChannelSpecifics ??
          const MacOSNotificationDetails(
            badgeNumber: 0,
            presentSound: true,
            presentAlert: true,
            presentBadge: true,
          ),
    );
    return platformChannelSpecifics;
  }

  @override
  void cancelAllNotifications() {
    _notification.cancelAll().then((value) {
      debugPrint('cancel all notifications');
    }).catchError((error) {
      debugPrint('Error cancel all notifications $error');
    });
  }

  @override
  void cancelNotification(int id) {
    _notification.cancel(id).then((value) {
      debugPrint('cancel notification $id');
    }).catchError((error) {
      debugPrint('Error cancel notification $id $error');
    });
  }

  @override
  Future<int> showNotification({
    String? title,
    String? body,
    payload,
    String? image,
  }) async {
    int id = _notificationId();
    var platformChannelSpecifics = await _createNotificationDetails(image);

    try {
      await _notification.show(
        id,
        title,
        body,
        platformChannelSpecifics,
        payload: payload,
      );
      return id;
    } catch (error) {
      rethrow;
    }
  }

  @override
  Future<int> showNotificationAt({
    required DateTime time,
    String? title,
    String? body,
    payload,
    String? image,
  }) async {
    int id = _notificationId();
    var platformChannelSpecifics = await _createNotificationDetails(image);

    try {
      await _notification.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(time, tz.local),
        platformChannelSpecifics,
        payload: payload,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      debugPrint('Schedule Notification [$id] at $time');
      return id;
    } catch (error) {
      rethrow;
    }
  }

  @override
  Future<int> showNotificationPeriodically({
    String? title,
    String? body,
    payload,
    String? image,
  }) async {
    int id = _notificationId();
    var platformChannelSpecifics = await _createNotificationDetails(image);

    try {
      await _notification.periodicallyShow(
        id,
        title,
        body,
        RepeatInterval.everyMinute,
        platformChannelSpecifics,
        payload: payload,
        androidAllowWhileIdle: true,
      );
      debugPrint(
          'Schedule Notification [$id] ${describeEnum(RepeatInterval.everyMinute).toUpperCase()}');
      return id;
    } catch (error) {
      rethrow;
    }
  }

  Future<Uint8List> _getByteArrayFromUrl(String url) async {
    final http.Response response = await http.get(Uri.parse(url));
    return response.bodyBytes;
  }

  Future<String> _downloadAndSaveFile(String url, String fileName) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final String filePath = '${directory.path}/$fileName';
    final http.Response response = await http.get(Uri.parse(url));
    final File file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    return filePath;
  }
}
