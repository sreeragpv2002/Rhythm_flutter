import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rhythm_flutter/core/network/dio_client.dart';
import 'package:rhythm_flutter/features/auth/data/models/auth_models.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return AuthRepository(dio);
});

class AuthRepository {
  final Dio _dio;

  AuthRepository(this._dio);

  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await _dio.post(
        'auth/login/',
        data: {
          'email': email,
          'password': password,
        },
      );
      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      final errorMessage = _getErrorMessage(e);
      throw Exception(errorMessage);
    }
  }

  Future<RegisterResponse> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      final response = await _dio.post(
        'auth/register/',
        data: {
          'email': email,
          'password': password,
          'password2': password,
          'first_name': firstName,
          'last_name': lastName,
          'role': 'CUSTOMER',
        },
      );
      return RegisterResponse.fromJson(response.data);
    } on DioException catch (e) {
      final errorMessage = _getErrorMessage(e);
      throw Exception(errorMessage);
    }
  }

  String _getErrorMessage(DioException e) {
    if (e.response != null && e.response?.data != null) {
      if (e.response?.data is Map) {
        final data = e.response?.data;
        if (data.containsKey('message')) return data['message'];
        if (data.containsKey('detail')) return data['detail'];
        if (data.containsKey('error')) return data['error'];
        // Handle nested errors if any
        return data.toString();
      }
    }
    return e.message ?? 'An unexpected error occurred';
  }
}
