import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rhythm_flutter/core/config/app_config.dart';
import 'package:rhythm_flutter/core/network/dio_client.dart';
import 'package:rhythm_flutter/core/services/storage_service.dart';
import 'package:rhythm_flutter/features/language/data/models/language_model.dart';

final languageRepositoryProvider = Provider<LanguageRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch(storageServiceProvider);
  return LanguageRepository(dio, storage);
});

class LanguageRepository {
  final Dio _dio;
  final StorageService _storage;

  LanguageRepository(this._dio, this._storage);

  /// Fetch list of available supported languages from GET /api/v1/languages
  Future<List<LanguageModel>> getAvailableLanguages() async {
    try {
      Response response;
      try {
        final directUrl = '${AppConfig.baseUrl}/api/v1/languages';
        debugPrint('LanguageRepository: Fetching available languages from $directUrl');
        response = await _dio.get(directUrl);
      } catch (e) {
        debugPrint('LanguageRepository: Direct URL failed ($e), trying relative "languages"');
        response = await _dio.get('languages');
      }

      if (response.data != null) {
        final dynamic raw = response.data['data'] ?? response.data;
        if (raw is List) {
          final list = <LanguageModel>[];
          for (final item in raw) {
            if (item is Map<String, dynamic>) {
              list.add(LanguageModel.fromJson(item));
            } else if (item is String) {
              list.add(LanguageModel.fromCode(item));
            }
          }
          if (list.isNotEmpty) return list;
        }
      }
    } catch (e) {
      debugPrint('LanguageRepository: Error fetching available languages: $e');
    }

    // Return rich default supported languages as fallback
    return LanguageModel.defaultSupportedLanguages();
  }

  /// Get user's saved languages from GET /api/v1/languages/user
  Future<List<String>> getUserLanguages(String userId) async {
    try {
      Response response;
      final queryParams = {'user_id': userId};
      try {
        final directUrl = '${AppConfig.baseUrl}/api/v1/languages/user';
        response = await _dio.get(directUrl, queryParameters: queryParams);
      } catch (e) {
        response = await _dio.get('languages/user', queryParameters: queryParams);
      }

      if (response.data != null) {
        final dynamic raw = response.data['data'] ?? response.data;
        if (raw is Map<String, dynamic> && raw['languages'] != null && raw['languages'] is List) {
          final rawList = raw['languages'] as List;
          if (rawList.isNotEmpty) {
            final langs = rawList
                .map((e) => e.toString().toLowerCase().trim())
                .where((e) => e.isNotEmpty)
                .toList();
            if (langs.isNotEmpty) {
              await _storage.setUserLanguages(langs);
              await _storage.setHasSetLanguages(true);
              return langs;
            }
          }
        } else if (raw is List && raw.isNotEmpty) {
          final langs = raw
              .map((e) => e.toString().toLowerCase().trim())
              .where((e) => e.isNotEmpty)
              .toList();
          if (langs.isNotEmpty) {
            await _storage.setUserLanguages(langs);
            await _storage.setHasSetLanguages(true);
            return langs;
          }
        }
      }
    } catch (e) {
      debugPrint('LanguageRepository: Error getting user languages: $e');
    }

    // Return locally stored languages if available
    return _storage.userLanguages;
  }

  /// Save user's selected languages to POST /api/v1/languages/user
  /// (with automatic PUT fallback if already existing)
  Future<bool> saveUserLanguages({
    required String userId,
    required List<String> languages,
  }) async {
    final payload = {
      'user_id': userId,
      'languages': languages.map((e) => e.toLowerCase().trim()).toList(),
    };

    debugPrint('LanguageRepository: Saving user languages payload: $payload');

    try {
      Response response;
      try {
        final directUrl = '${AppConfig.baseUrl}/api/v1/languages/user';
        response = await _dio.post(directUrl, data: payload);
      } catch (postError) {
        debugPrint('LanguageRepository: POST failed ($postError), attempting PUT...');
        try {
          final directUrl = '${AppConfig.baseUrl}/api/v1/languages/user';
          response = await _dio.put(directUrl, data: payload);
        } catch (putError) {
          debugPrint('LanguageRepository: Direct PUT failed ($putError), trying relative "languages/user"');
          response = await _dio.post('languages/user', data: payload);
        }
      }

      debugPrint('LanguageRepository: Saved languages response: ${response.statusCode} - ${response.data}');

      // Cache locally
      await _storage.setUserLanguages(languages);
      await _storage.setHasSetLanguages(true);
      return true;
    } catch (e) {
      debugPrint('LanguageRepository: Error saving user languages to API: $e');
      // Still persist locally so app user experience isn't blocked offline
      await _storage.setUserLanguages(languages);
      await _storage.setHasSetLanguages(true);
      return true;
    }
  }
}
