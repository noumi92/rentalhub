import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthenticatedWithoutRole extends AuthState {
  final UserEntity user;
  const AuthenticatedWithoutRole(this.user);

  @override
  List<Object?> get props => [user];
}

class AuthenticatedCustomer extends AuthState {
  final UserEntity user;
  const AuthenticatedCustomer(this.user);

  @override
  List<Object?> get props => [user];
}

class AuthenticatedOwner extends AuthState {
  final UserEntity user;
  const AuthenticatedOwner(this.user);

  @override
  List<Object?> get props => [user];
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

