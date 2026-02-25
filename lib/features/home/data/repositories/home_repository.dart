import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  static const String _homeCacheKey = 'home_feed_cache';

  HomeRepository(this._dio, this._storage);

  Future<HomeFeed> getHomeFeed() async {
    final baseUrl = _dio.options.baseUrl;
    final langMatch = RegExp(r'/([a-z]{2})/').firstMatch(baseUrl);
    final lang = langMatch?.group(1) ?? 'en';
    final cacheKey = '${_homeCacheKey}_$lang';

    try {
      final response = await _dio.get('home/');
      
      if (response.data['success'] == true) {
        final data = response.data['data'];
        
        // Cache the result
        await _storage.setString(cacheKey, jsonEncode(data));
        
        return HomeFeed.fromJson(data);
      }
      throw Exception(response.data['message'] ?? 'Failed to load home feed');
    } catch (e) {
      // Try to load from cache
      final cachedData = await _getCachedHomeFeed(cacheKey);
      if (cachedData != null) {
        return cachedData;
      }
      rethrow;
    }
  }

  Future<HomeFeed?> _getCachedHomeFeed(String cacheKey) async {
    try {
      final cachedString = _storage.getString(cacheKey);
      if (cachedString != null) {
        return HomeFeed.fromJson(jsonDecode(cachedString));
      }
    } catch (e) {
      // Ignore cache errors
    }
    return null;
  }
}
