class PushNotificationModel {
  String? id;
  final String title;
  final String body;
  String? image;
  Map<String, dynamic>? data;

  PushNotificationModel({
    this.id,
    required this.title,
    required this.body,
    this.image,
    required this.data,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'notification': {
        'title': title,
        'body': body,
      },
      'image': image,
      'data': data,
    };
  }
}
