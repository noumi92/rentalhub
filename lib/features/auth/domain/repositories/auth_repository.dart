import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> signInWithGoogle();
  Future<UserEntity> signInWithEmail({
    required String email,
    required String password,
  });
  Future<UserEntity> assignUserRole({
    required String role,
    required String fullName,
    required String phone,
  });
  Future<UserEntity?> getCurrentUser();
  Future<void> signOut();
}

