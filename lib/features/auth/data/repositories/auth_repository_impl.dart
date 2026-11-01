import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  const AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<UserEntity> signInWithGoogle() => remoteDataSource.signInWithGoogle();

  @override
  Future<UserEntity> signInWithEmail({
    required String email,
    required String password,
  }) =>
      remoteDataSource.signInWithEmail(email: email, password: password);

  @override
  Future<UserEntity> assignUserRole({
    required String role,
    required String fullName,
    required String phone,
  }) =>
      remoteDataSource.assignPermanentRole(
        role: role,
        fullName: fullName,
        phone: phone,
      );

  @override
  Future<UserEntity?> getCurrentUser() => remoteDataSource.getCurrentUser();

  @override
  Future<void> signOut() => remoteDataSource.signOut();
}

