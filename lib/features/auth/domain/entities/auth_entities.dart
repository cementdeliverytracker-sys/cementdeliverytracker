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

class UserProfile extends Equatable {
  final String id;
  final String email;
  final String username;
  final String userType;
  final String? adminId;
  final String? employeeId;
  final String? phone;
  final String? imageUrl;

  const UserProfile({
    required this.id,
    required this.email,
    required this.username,
    required this.userType,
    this.adminId,
    this.employeeId,
    this.phone,
    this.imageUrl,
  });

  UserProfile copyWith({
    String? id,
    String? email,
    String? username,
    String? userType,
    String? adminId,
    String? employeeId,
    String? phone,
    String? imageUrl,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      userType: userType ?? this.userType,
      adminId: adminId ?? this.adminId,
      employeeId: employeeId ?? this.employeeId,
      phone: phone ?? this.phone,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  List<Object?> get props => [
    id,
    email,
    username,
    userType,
    adminId,
    employeeId,
    phone,
    imageUrl,
  ];
}
