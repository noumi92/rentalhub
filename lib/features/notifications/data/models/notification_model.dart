import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/notification_entity.dart';

class NotificationModel extends NotificationEntity {
  const NotificationModel({
    required super.notificationId,
    required super.shopId,
    super.customerId,
    super.recipientRole = 'owner',
    required super.title,
    required super.body,
    required super.type,
    super.bookingId,
    super.targetRoute,
    required super.createdAt,
    super.read,
  });

  factory NotificationModel.fromEntity(NotificationEntity e) {
    return NotificationModel(
      notificationId: e.notificationId,
      shopId: e.shopId,
      customerId: e.customerId,
      recipientRole: e.recipientRole,
      title: e.title,
      body: e.body,
      type: e.type,
      bookingId: e.bookingId,
      targetRoute: e.targetRoute,
      createdAt: e.createdAt,
      read: e.read,
    );
  }

  static DateTime _parseDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v != null) {
      final parsed = DateTime.tryParse(v.toString());
      if (parsed != null) return parsed;
    }
    return DateTime.now();
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    final customerId = (map['customerId'] ??
            map['recipientUid'] ??
            map['recipient_uid'] ??
            map['userId']) as String?;
    final role = (map['recipientRole'] as String?) ??
        (customerId != null && customerId.isNotEmpty ? 'customer' : 'owner');
    return NotificationModel(
      notificationId: (map['notificationId'] as String?) ?? docId ?? '',
      shopId: (map['shopId'] as String?) ?? '',
      customerId: customerId,
      recipientRole: role,
      title: (map['title'] as String?) ?? '',
      body: (map['body'] as String?) ?? '',
      type: (map['type'] as String?) ?? 'general',
      bookingId: map['bookingId'] as String?,
      targetRoute: map['targetRoute'] as String?,
      createdAt: _parseDate(map['createdAt']),
      read: map['read'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'notificationId': notificationId,
      'shopId': shopId,
      if (customerId != null && customerId!.isNotEmpty) ...{
        'customerId': customerId,
        'recipientUid': customerId,
      },
      'recipientRole': recipientRole,
      'title': title,
      'body': body,
      'type': type,
      if (bookingId != null) 'bookingId': bookingId,
      if (targetRoute != null) 'targetRoute': targetRoute,
      'createdAt': createdAt.toIso8601String(),
      'read': read,
    };
  }
}
