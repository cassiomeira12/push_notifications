abstract class FirebasePushNotificationInterface {
  Future<void> firebaseCloudMessageListeners();

  void receiveNotificationWhenAppRunning();
  void openNotificationToStartApp();
  void openNotificationWhenAppRunning();

  //Future<void> updateToken(String token);
  //Future<void> onClickNotification(Map<String, dynamic> payload);
  Future<void> subscribeToTopic(String topic, {String? topicName});
  Future<void> unsubscribeFromTopic(String topic, {String? topicName});
}
