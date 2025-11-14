import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import 'auth_state.dart';

class AuthController extends StateNotifier<AuthState> {
  AuthController({required AuthRepository repository})
      : _repository = repository,
        super(AuthState.unauthenticated);

  final AuthRepository _repository;

  Future<void> loadPersistedAuth() async {
    final stored = _repository.restore();
    if (stored != null && stored.isAuthenticated) {
      state = stored;
    }
  }

  Future<bool> login({required String phone, required String password}) async {
    state = state.copyWith(status: AuthStatus.authenticating);
    try {
      final result = await _repository.login(phone: phone, password: password);
      state = result.copyWith(status: AuthStatus.authenticated);
      await _repository.persist(state);
      return true;
    } catch (_) {
      state = state.copyWith(status: AuthStatus.error);
      return false;
    }
  }

  Future<bool> register({
    required String phone,
    required String password,
    required String firstName,
    required String lastName,
    required String role,
    Map<String, dynamic>? address,
    List<Map<String, dynamic>>? availability,
  }) async {
    state = state.copyWith(status: AuthStatus.authenticating);
    try {
      final result = await _repository.register(
        phone: phone,
        password: password,
        firstName: firstName,
        lastName: lastName,
        role: role,
        address: address,
        availability: availability,
      );
      state = result.copyWith(status: AuthStatus.authenticated);
      await _repository.persist(state);
      return true;
    } catch (_) {
      state = state.copyWith(status: AuthStatus.error);
      return false;
    }
  }

  Future<void> logout() async {
    state = AuthState.unauthenticated;
    await _repository.clear();
  }
}

