import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class SignInWithEmailUseCase {
  final AuthRepository repository;
  const SignInWithEmailUseCase(this.repository);

  Future<UserEntity> call({
    required String email,
    required String password,
  }) =>
      repository.signInWithEmail(email: email, password: password);
}

