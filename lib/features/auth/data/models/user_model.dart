import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.uid,
    required super.email,
    required super.fullName,
    required super.phoneNumber,
    super.profilePhotoUrl,
    super.role,
    super.isVerified,
    super.trustScore,
    super.totalTrips,
    super.isBlacklisted,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, {String? id}) {
    return UserModel(
      uid: id ?? data['uid'] ?? '',
      email: data['email'] ?? '',
      fullName: data['full_name'] ?? '',
      phoneNumber: data['phone_number'] ?? '',
      profilePhotoUrl: data['profile_photo_url'],
      role: data['role'],
      isVerified: data['is_verified'] ?? false,
      trustScore: (data['trust_score'] ?? 5.0).toDouble(),
      totalTrips: data['total_trips'] ?? 0,
      isBlacklisted: data['is_blacklisted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'profile_photo_url': profilePhotoUrl,
      'role': role,
      'is_verified': isVerified,
      'trust_score': trustScore,
      'total_trips': totalTrips,
      'is_blacklisted': isBlacklisted,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}

