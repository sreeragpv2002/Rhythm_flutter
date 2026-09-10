import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rhythm_flutter/core/config/app_config.dart';
import 'package:rhythm_flutter/core/network/dio_client.dart';
import 'package:rhythm_flutter/core/services/storage_service.dart';
import 'package:rhythm_flutter/features/home/data/models/home_feed.dart';

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch(storageServiceProvider);
  return HomeRepository(dio, storage);
});

class HomeRepository {
  final Dio _dio;
  final StorageService _storage;
  static const String _homeCacheKey = 'home_feed_cache_v2';

  HomeRepository(this._dio, this._storage);

  Future<HomeFeed> getHomeFeed({String? userId, String? language, int? limit}) async {
    final cacheKey = '${_homeCacheKey}_${language ?? "all"}';

    try {
      // Obtain Firebase user ID if available, or fallback to saved ID
      final effectiveUserId = userId ??
          _storage.getString('user_id') ??
          _storage.getString('firebase_user_id') ??
          'dZnjYn0Ku1X9vleSQYmyczZvcLL2';

      final queryParams = <String, dynamic>{
        'user_id': effectiveUserId,
      };

      if (limit != null) {
        queryParams['limit'] = limit;
      }

      if (language != null && language.isNotEmpty) {
        queryParams['language'] = language;
      } else if (_storage.userLanguages.isNotEmpty) {
        queryParams['language'] = _storage.userLanguages.join(',');
      }

      Response response;
      try {
        final directUrl = '${AppConfig.baseUrl}/api/v1/home';
        debugPrint('HomeRepository: Requesting $directUrl with $queryParams');
        response = await _dio.get(directUrl, queryParameters: queryParams);
      } catch (directError) {
        debugPrint('HomeRepository: Direct URL failed ($directError), trying relative "home"');
        response = await _dio.get('home', queryParameters: queryParams);
      }

      if (response.data != null) {
        final dynamic rawData = response.data['data'] ?? response.data;
        if (rawData is Map<String, dynamic>) {
          // Cache the result
          await _storage.setString(cacheKey, jsonEncode(rawData));
          return HomeFeed.fromJson(rawData);
        }
      }
      throw Exception(response.data?['message'] ?? 'Failed to load home feed');
    } catch (e) {
      debugPrint('HomeRepository: Error fetching home feed: $e');
      // Try to load from cache
      final cachedData = await _getCachedHomeFeed(cacheKey);
      if (cachedData != null) {
        debugPrint('HomeRepository: Successfully loaded from cache');
        return cachedData;
      }
      // If network fails and cache is empty (e.g. placeholder URL or offline),
      // use initial sample data so the app can display without crashing
      debugPrint('HomeRepository: Returning initial sample feed');
      return HomeFeed.initialFallback();
    }
  }

  Future<HomeFeed?> _getCachedHomeFeed(String cacheKey) async {
    try {
      final cachedString = _storage.getString(cacheKey);
      if (cachedString != null) {
        return HomeFeed.fromJson(jsonDecode(cachedString) as Map<String, dynamic>);
      }
    } catch (e) {
      // Ignore cache errors
    }
    return null;
  }
}
