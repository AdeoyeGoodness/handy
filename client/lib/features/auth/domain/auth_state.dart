import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import '../../../shared/models/app_user.dart';

@immutable
class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.unauthenticated,
    this.accessToken,
    this.refreshToken,
    this.user,
  });

  final AuthStatus status;
  final String? accessToken;
  final String? refreshToken;
  final AppUser? user;

  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;

  AuthState copyWith({
    AuthStatus? status,
    String? accessToken,
    String? refreshToken,
    AppUser? user,
  }) {
    return AuthState(
      status: status ?? this.status,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      user: user ?? this.user,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status.name,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'user': user?.toJson(),
    };
  }

  factory AuthState.fromJson(Map<String, dynamic> json) {
    return AuthState(
      status: AuthStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => AuthStatus.unauthenticated,
      ),
      accessToken: json['accessToken'] as String?,
      refreshToken: json['refreshToken'] as String?,
      user:
          json['user'] != null ? AppUser.fromJson(json['user'] as Map<String, dynamic>) : null,
    );
  }

  static const unauthenticated = AuthState();

  @override
  List<Object?> get props => [status, accessToken, refreshToken, user];
}

enum AuthStatus {
  unauthenticated,
  authenticating,
  authenticated,
  error,
}

