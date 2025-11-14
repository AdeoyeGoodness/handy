import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../../../shared/models/app_user.dart';
import '../domain/auth_state.dart';
import 'token_storage.dart';

class AuthRepository {
  AuthRepository({
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
  })  : _apiClient = apiClient,
        _tokenStorage = tokenStorage;

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  AuthState? restore() => _tokenStorage.read();

  Future<void> persist(AuthState state) => _tokenStorage.save(state);

  Future<void> clear() => _tokenStorage.clear();

  Future<AuthState> login({required String phone, required String password}) async {
    final response = await _apiClient.post(
      '/auth/login',
      body: {'username': phone, 'password': password},
      formUrlEncoded: true,
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final user = AppUser.fromJson(data['user'] as Map<String, dynamic>);
    return AuthState(
      status: AuthStatus.authenticated,
      accessToken: data['access_token'] as String?,
      refreshToken: data['refresh_token'] as String?,
      user: user,
    );
  }

  Future<AuthState> register({
    required String phone,
    required String password,
    required String firstName,
    required String lastName,
    required String role,
    Map<String, dynamic>? address,
    List<Map<String, dynamic>>? availability,
  }) async {
    final body = <String, dynamic>{
      'phone': phone,
      'password': password,
      'first_name': firstName,
      'last_name': lastName,
      'role': role,
    };

    if (address != null) {
      body['address'] = address;
    }

    if (availability != null && availability.isNotEmpty) {
      body['availability'] = availability;
    }

    final response = await _apiClient.post('/auth/register', body: body);
    final user = AppUser.fromJson(jsonDecode(response.body) as Map<String, dynamic>);

    final loginState = await login(phone: phone, password: password);
    return loginState.copyWith(user: user);
  }
}

