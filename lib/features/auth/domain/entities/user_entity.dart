import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String uid;
  final String email;
  final String fullName;
  final String phoneNumber;
  final String? profilePhotoUrl;
  final String? role; // 'customer' | 'owner' | null (if new)
  final bool isVerified;
  final double trustScore;
  final int totalTrips;
  final bool isBlacklisted;

  const UserEntity({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.phoneNumber,
    this.profilePhotoUrl,
    this.role,
    this.isVerified = false,
    this.trustScore = 5.0,
    this.totalTrips = 0,
    this.isBlacklisted = false,
  });

  bool get hasSelectedRole =>
      role != null && (role == 'customer' || role == 'owner');

  UserEntity copyWith({
    String? uid,
    String? email,
    String? fullName,
    String? phoneNumber,
    String? profilePhotoUrl,
    String? role,
    bool? isVerified,
    double? trustScore,
    int? totalTrips,
    bool? isBlacklisted,
  }) {
    return UserEntity(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      role: role ?? this.role,
      isVerified: isVerified ?? this.isVerified,
      trustScore: trustScore ?? this.trustScore,
      totalTrips: totalTrips ?? this.totalTrips,
      isBlacklisted: isBlacklisted ?? this.isBlacklisted,
    );
  }

  @override
  List<Object?> get props => [
        uid,
        email,
        fullName,
        phoneNumber,
        profilePhotoUrl,
        role,
        isVerified,
        trustScore,
        totalTrips,
        isBlacklisted,
      ];
}

