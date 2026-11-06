import '../../domain/entities/notification_entity.dart';

class NotificationModel extends NotificationEntity {
  const NotificationModel({
    required super.notificationId,
    required super.shopId,
    required super.title,
    required super.body,
    required super.type,
    super.bookingId,
    required super.createdAt,
    super.read,
  });

  factory NotificationModel.fromEntity(NotificationEntity e) {
    return NotificationModel(
      notificationId: e.notificationId,
      shopId: e.shopId,
      title: e.title,
      body: e.body,
      type: e.type,
      bookingId: e.bookingId,
      createdAt: e.createdAt,
      read: e.read,
    );
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      notificationId: map['notificationId'] ?? '',
      shopId: map['shopId'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: map['type'] ?? 'general',
      bookingId: map['bookingId'],
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      read: map['read'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'notificationId': notificationId,
      'shopId': shopId,
      'title': title,
      'body': body,
      'type': type,
      if (bookingId != null) 'bookingId': bookingId,
      'createdAt': createdAt.toIso8601String(),
      'read': read,
    };
  }
}
