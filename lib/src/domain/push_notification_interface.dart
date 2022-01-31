abstract class PushNotificationInterface {
  Future<void> updateToken(String token);
  Future<void> initialNotificationsTopics();
  Future<void> onClickNotification(Map<String, dynamic> map);
}
