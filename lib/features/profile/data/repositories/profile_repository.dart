import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rhythm_flutter/core/network/dio_client.dart';

import '../models/artist.dart';
import '../models/language.dart';
import '../models/profile_request.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return ProfileRepository(dio);
});

class ProfileRepository {
  final Dio _dio;

  ProfileRepository(this._dio);

  Future<List<Artist>> getArtists() async {
    try {
      final response = await _dio.get('artists/');
      if (response.data['success'] == true) {
        final List results = response.data['data']['results'];
        return results.map((e) => Artist.fromJson(e)).toList();
      }
      throw Exception(response.data['message'] ?? 'Failed to load artists');
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Language>> getLanguages() async {
    try {
      final response = await _dio.get('music/languages/');
      if (response.data['success'] == true) {
        final List results = response.data['data'];
        return results.map((e) => Language.fromJson(e)).toList();
      }
      throw Exception(response.data['message'] ?? 'Failed to load languages');
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> updateProfile(ProfileRequest request) async {
    try {
      final response = await _dio.post(
        'auth/profiles/',
        data: request.toJson(),
      );
      // The API returns the profile data on success, let's assume success if status is 200 or 201
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      rethrow;
    }
  }
}
