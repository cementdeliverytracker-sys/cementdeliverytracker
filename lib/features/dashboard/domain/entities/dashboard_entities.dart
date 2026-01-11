import 'package:equatable/equatable.dart';

class DashboardData extends Equatable {
  final String userId;
  final String username;
  final String email;
  final String userType;
  final String? imageUrl;
  final String? phone;

  const DashboardData({
    required this.userId,
    required this.username,
    required this.email,
    required this.userType,
    this.imageUrl,
    this.phone,
  });

  @override
  List<Object?> get props => [
    userId,
    username,
    email,
    userType,
    imageUrl,
    phone,
  ];
}
