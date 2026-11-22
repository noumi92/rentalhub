import 'package:equatable/equatable.dart';

/// Phase B (G2): one alert for the shop owner — a new booking
/// request, a payment proof to verify, a handover or return due.
/// The owner reads these on the notifications screen; the app
/// writes them when the event happens.
class NotificationEntity extends Equatable {
  final String notificationId;
  final String shopId;
  final String? customerId;
  final String recipientRole; // 'owner' | 'customer'
  final String title;
  final String body;
  final String type;
  final String? bookingId;
  final String? targetRoute;
  final DateTime createdAt;
  final bool read;

  const NotificationEntity({
    required this.notificationId,
    required this.shopId,
    this.customerId,
    this.recipientRole = 'owner',
    required this.title,
    required this.body,
    required this.type,
    this.bookingId,
    this.targetRoute,
    required this.createdAt,
    this.read = false,
  });

  NotificationEntity copyWith({bool? read}) {
    return NotificationEntity(
      notificationId: notificationId,
      shopId: shopId,
      customerId: customerId,
      recipientRole: recipientRole,
      title: title,
      body: body,
      type: type,
      bookingId: bookingId,
      targetRoute: targetRoute,
      createdAt: createdAt,
      read: read ?? this.read,
    );
  }

  @override
  List<Object?> get props => [
        notificationId,
        shopId,
        customerId,
        recipientRole,
        title,
        body,
        type,
        bookingId,
        targetRoute,
        createdAt,
        read,
      ];
}
