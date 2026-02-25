import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rhythm_flutter/core/network/unauthorized_event_provider.dart';
import 'package:rhythm_flutter/core/services/storage_service.dart';
import 'package:rhythm_flutter/features/auth/data/repositories/auth_repository.dart';

part 'auth_provider.freezed.dart';
part 'auth_provider.g.dart';

@freezed
class AuthState with _$AuthState {
  const factory AuthState({
    @Default(AuthStatus.unauthenticated) AuthStatus status,
    @Default(false) bool isLoading,
    String? error,
    String? email,
    String? accessToken,
    @Default(false) bool hasProfile,
  }) = _AuthState;
}

enum AuthStatus { unauthenticated, authenticated }

@riverpod
class Auth extends _$Auth {
  late AuthRepository _repository;
  late StorageService _storage;

  @override
  AuthState build() {
    _repository = ref.watch(authRepositoryProvider);
    _storage = ref.watch(storageServiceProvider);

    // Listen for unauthorized events to trigger logout
    ref.listen(unauthorizedEventProvider, (previous, next) {
      if (next) {
        logout();
        ref.read(unauthorizedEventProvider.notifier).state = false;
      }
    });

    return _checkAuth();
  }

  AuthState _checkAuth() {
    if (_storage.isLoggedIn && _storage.accessToken != null) {
      return AuthState(
        status: AuthStatus.authenticated,
        email: _storage.userEmail,
        accessToken: _storage.accessToken,
        hasProfile: _storage.hasProfile,
      );
    }
    return const AuthState();
  }

  Future<void> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      state = state.copyWith(error: 'Please enter email and password');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _repository.login(email, password);
      
      await _storage.setLoggedIn(true);
      await _storage.setUserEmail(response.user.email);
      await _storage.setAccessToken(response.access);
      await _storage.setRefreshToken(response.refresh);
      await _storage.setHasProfile(response.user.hasProfile);
      
      state = state.copyWith(
        status: AuthStatus.authenticated,
        isLoading: false,
        email: response.user.email,
        accessToken: response.access,
        hasProfile: response.user.hasProfile,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      state = state.copyWith(error: 'Please fill in all fields');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final nameParts = name.trim().split(' ');
      final firstName = nameParts.first;
      final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      final response = await _repository.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );

      if (response.success) {
        await login(email, password);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.message,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> logout() async {
    await _storage.clearAll();
    state = const AuthState();
  }

  Future<void> setHasProfile(bool value) async {
    await _storage.setHasProfile(value);
    state = state.copyWith(hasProfile: value);
  }
}
