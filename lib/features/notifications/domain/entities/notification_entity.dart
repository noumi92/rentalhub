import 'package:equatable/equatable.dart';

/// Phase B (G2): one alert for the shop owner — a new booking
/// request, a payment proof to verify, a handover or return due.
/// The owner reads these on the notifications screen; the app
/// writes them when the event happens.
class NotificationEntity extends Equatable {
  final String notificationId;
  final String shopId;
  final String title;
  final String body;
  final String type; // 'booking_request' | 'payment_proof' | 'handover' | 'return' | 'general'
  final String? bookingId;
  final DateTime createdAt;
  final bool read;

  const NotificationEntity({
    required this.notificationId,
    required this.shopId,
    required this.title,
    required this.body,
    required this.type,
    this.bookingId,
    required this.createdAt,
    this.read = false,
  });

  NotificationEntity copyWith({bool? read}) {
    return NotificationEntity(
      notificationId: notificationId,
      shopId: shopId,
      title: title,
      body: body,
      type: type,
      bookingId: bookingId,
      createdAt: createdAt,
      read: read ?? this.read,
    );
  }

  @override
  List<Object?> get props =>
      [notificationId, shopId, title, body, type, bookingId, createdAt, read];
}
