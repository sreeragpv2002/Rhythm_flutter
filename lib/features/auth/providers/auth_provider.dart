import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
      await _storage.setString('user_id', response.user.id.toString());

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

  /// Sign in using Google Sign-In and Firebase Auth
  Future<void> loginWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        final userCredential =
            await FirebaseAuth.instance.signInWithPopup(googleProvider);
        final user = userCredential.user;
        final idToken = await user?.getIdToken() ?? 'firebase_google_token';
        final email = user?.email ?? 'google_user@rhythm.app';
        final uid = user?.uid ?? '';

        await _saveUserSession(email: email, token: idToken, uid: uid);
        return;
      }

      // Native Android / iOS Google Sign-In
      GoogleSignInAccount? googleUser;
      try {
        final GoogleSignIn googleSignIn = GoogleSignIn(
          serverClientId:
              '319455985483-b2fjdhl5nnatc1cthc73vo08t51kr90m.apps.googleusercontent.com',
          scopes: ['email', 'profile'],
        );
        googleUser = await googleSignIn.signIn();
      } catch (e) {
        debugPrint('Auth: GoogleSignIn with serverClientId failed: $e');
        try {
          final GoogleSignIn googleSignInFallback = GoogleSignIn(
            scopes: ['email', 'profile'],
          );
          googleUser = await googleSignInFallback.signIn();
        } catch (e2) {
          debugPrint('Auth: GoogleSignIn fallback failed: $e2');
          rethrow;
        }
      }

      if (googleUser == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Google Sign-In was cancelled or rejected. Check SHA-1 configuration in Firebase Console.',
        );
        return;
      }

      String email = googleUser.email;
      String uid = googleUser.id;
      String token = 'google_token_${googleUser.id}';

      try {
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        if (googleAuth.idToken != null) {
          token = googleAuth.idToken!;
        }

        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        final userCredential =
            await FirebaseAuth.instance.signInWithCredential(credential);
        final user = userCredential.user;
        if (user != null) {
          email = user.email ?? email;
          uid = user.uid;
          token = await user.getIdToken() ?? token;
        }
      } catch (firebaseErr) {
        debugPrint('Auth: Firebase credential error, continuing with Google profile: $firebaseErr');
      }

      await _saveUserSession(email: email, token: token, uid: uid);
    } catch (e) {
      debugPrint('Auth: Google login error: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('PlatformException(', '').replaceAll(')', '').replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> _saveUserSession({
    required String email,
    required String token,
    required String uid,
  }) async {
    await _storage.setLoggedIn(true);
    await _storage.setUserEmail(email);
    await _storage.setAccessToken(token);
    await _storage.setRefreshToken(token);
    await _storage.setHasProfile(true);
    if (uid.isNotEmpty) {
      await _storage.setString('user_id', uid);
      await _storage.setString('firebase_user_id', uid);
    }

    state = state.copyWith(
      status: AuthStatus.authenticated,
      isLoading: false,
      email: email,
      accessToken: token,
      hasProfile: true,
    );
  }

  /// Sign in Anonymously / Guest Mode
  Future<void> loginAnonymously() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      String uid = 'guest_${DateTime.now().millisecondsSinceEpoch}';
      String token = 'guest_token';
      const email = 'guest@rhythm.app';

      try {
        final userCredential = await FirebaseAuth.instance.signInAnonymously();
        final user = userCredential.user;
        if (user != null) {
          uid = user.uid;
          token = await user.getIdToken() ?? token;
        }
      } catch (firebaseErr) {
        debugPrint('Auth: Firebase anonymous error (using local guest): $firebaseErr');
      }

      await _storage.setLoggedIn(true);
      await _storage.setUserEmail(email);
      await _storage.setAccessToken(token);
      await _storage.setRefreshToken(token);
      await _storage.setHasProfile(true);
      await _storage.setString('user_id', uid);
      await _storage.setString('firebase_user_id', uid);

      state = state.copyWith(
        status: AuthStatus.authenticated,
        isLoading: false,
        email: email,
        accessToken: token,
        hasProfile: true,
      );
    } catch (e) {
      debugPrint('Auth: Anonymous login total error: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!kIsWeb) {
        await GoogleSignIn().signOut();
      }
    } catch (_) {}
    await _storage.clearAll();
    state = const AuthState();
  }

  Future<void> setHasProfile(bool value) async {
    await _storage.setHasProfile(value);
    state = state.copyWith(hasProfile: value);
  }
}
