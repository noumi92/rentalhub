import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/assign_user_role_usecase.dart';
import '../../domain/usecases/sign_in_with_email_usecase.dart';
import '../../domain/usecases/sign_in_with_google_usecase.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AssignUserRoleUseCase assignRoleUseCase;
  final SignInWithGoogleUseCase? signInWithGoogleUseCase;
  final SignInWithEmailUseCase? signInWithEmailUseCase;

  AuthCubit({
    required this.assignRoleUseCase,
    this.signInWithGoogleUseCase,
    this.signInWithEmailUseCase,
  }) : super(const AuthInitial());

  Future<void> signInWithGoogle() async {
    if (signInWithGoogleUseCase == null) return;
    emit(const AuthLoading());
    try {
      final user = await signInWithGoogleUseCase!();
      if (!user.hasSelectedRole) {
        emit(AuthenticatedWithoutRole(user));
      } else if (user.role == 'customer') {
        emit(AuthenticatedCustomer(user));
      } else {
        emit(AuthenticatedOwner(user));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (signInWithEmailUseCase == null) return;
    emit(const AuthLoading());
    try {
      final user = await signInWithEmailUseCase!(
        email: email,
        password: password,
      );
      if (!user.hasSelectedRole) {
        emit(AuthenticatedWithoutRole(user));
      } else if (user.role == 'customer') {
        emit(AuthenticatedCustomer(user));
      } else {
        emit(AuthenticatedOwner(user));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> selectPermanentRole({
    required String role,
    required String fullName,
    required String phone,
  }) async {
    try {
      if (role != 'customer' && role != 'owner') {
        emit(const AuthError('Invalid role specified.'));
        return;
      }
      final updatedUser = await assignRoleUseCase(
        role: role,
        fullName: fullName,
        phone: phone,
      );
      if (updatedUser.role == 'customer') {
        emit(AuthenticatedCustomer(updatedUser));
      } else {
        emit(AuthenticatedOwner(updatedUser));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
}

