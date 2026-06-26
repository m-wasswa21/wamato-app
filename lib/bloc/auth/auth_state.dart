import 'package:equatable/equatable.dart';

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

class AuthAuthenticated extends AuthState {
  final String userId;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final String? bio;
  final String? district;
  final String? avatarUrl;

  const AuthAuthenticated({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.bio,
    this.district,
    this.avatarUrl,
  });

  AuthAuthenticated copyWith({
    String? name,
    String? phone,
    String? bio,
    String? district,
    String? avatarUrl,
  }) =>
      AuthAuthenticated(
        userId: userId,
        email: email,
        role: role,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        bio: bio ?? this.bio,
        district: district ?? this.district,
        avatarUrl: avatarUrl ?? this.avatarUrl,
      );

  @override
  List<Object?> get props => [userId, name, email, role, phone, bio, district, avatarUrl];
}

class AuthUnauthenticated extends AuthState {
  final bool onboardingSeen;
  const AuthUnauthenticated({this.onboardingSeen = false});
  @override
  List<Object?> get props => [onboardingSeen];
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override
  List<Object?> get props => [message];
}
