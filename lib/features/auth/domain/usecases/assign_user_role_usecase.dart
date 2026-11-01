import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class AssignUserRoleUseCase {
  final AuthRepository repository;
  const AssignUserRoleUseCase(this.repository);

  Future<UserEntity> call({
    required String role,
    required String fullName,
    required String phone,
  }) =>
      repository.assignUserRole(
        role: role,
        fullName: fullName,
        phone: phone,
      );
}

