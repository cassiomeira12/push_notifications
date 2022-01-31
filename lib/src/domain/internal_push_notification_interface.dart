abstract class InternalPushNotificationInterface {
  Future<void> subscribeToTopic(String topic, {String? topicName});
  Future<void> unsubscribeFromTopic(String topic, {String? topicName});

  Future<int> showNotification({
    String? title,
    String? body,
    dynamic payload,
    String? image,
  });

  Future<int> showNotificationAt({
    required DateTime time,
    String? title,
    String? body,
    dynamic payload,
    String? image,
  });

  Future<int> showNotificationPeriodically({
    //RepeatInterval interval,
    String? title,
    String? body,
    dynamic payload,
    String? image,
  });

  void cancelNotification(int id);
  void cancelAllNotifications();
}
