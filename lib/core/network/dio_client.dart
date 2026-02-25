import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rhythm_flutter/shared/providers/locale_provider.dart';
import 'package:rhythm_flutter/core/constants/app_constants.dart';
import 'package:rhythm_flutter/core/config/app_config.dart';
import 'package:rhythm_flutter/core/network/unauthorized_event_provider.dart';

final dioProvider = Provider<Dio>((ref) {
  final locale = ref.watch(localeProvider);
  final langCode = locale.languageCode;

  final baseUrl = '${AppConfig.baseUrl}/$langCode/${AppConfig.apiVersion}/';

  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString(AppConstants.accessTokenKey);

        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        handler.next(options);
      },
      onError: (DioException error, handler) async {
        if (error.response?.statusCode == 401 &&
            error.requestOptions.extra['retry'] != true) {
          try {
            final prefs = await SharedPreferences.getInstance();
            final refreshToken =
            prefs.getString(AppConstants.refreshTokenKey);

            if (refreshToken == null || refreshToken.isEmpty) {
              ref.read(unauthorizedEventProvider.notifier).state = true;
              return handler.next(error);
            }

            final refreshDio = Dio(
              BaseOptions(
                baseUrl: baseUrl,
                headers: const {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            );

            final response = await refreshDio.post(
              'auth/token/refresh/',
              data: {'refresh': refreshToken},
            );

            if (response.statusCode == 200 &&
                response.data['access'] != null) {
              final newAccessToken = response.data['access'];

              await prefs.setString(
                  AppConstants.accessTokenKey, newAccessToken);

              final requestOptions = error.requestOptions;
              requestOptions.headers['Authorization'] =
              'Bearer $newAccessToken';
              requestOptions.extra['retry'] = true;

              final retryResponse =
              await dio.fetch(requestOptions);

              return handler.resolve(retryResponse);
            }
          } catch (_) {
            ref.read(unauthorizedEventProvider.notifier).state = true;
          }
        }

        handler.next(error);
      },
    ),
  );

  dio.interceptors.add(
    LogInterceptor(
      requestBody: true,
      responseBody: true,
    ),
  );

  return dio;
});