import 'package:equatable/equatable.dart';

class AuthUser extends Equatable {
  final String id;
  final String email;
  final String? displayName;

  const AuthUser({required this.id, required this.email, this.displayName});

  @override
  List<Object?> get props => [id, email, displayName];
}

class LoginParams extends Equatable {
  final String email;
  final String password;

  const LoginParams({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}

class SignupParams extends Equatable {
  final String email;
  final String password;
  final String username;
  final String? phone;
  final String? imagePath;

  const SignupParams({
    required this.email,
    required this.password,
    required this.username,
    this.phone,
    this.imagePath,
  });

  @override
  List<Object?> get props => [email, password, username, phone, imagePath];
}
