import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rhythm_flutter/core/network/dio_client.dart';
import 'package:rhythm_flutter/features/home/data/models/music.dart';

final musicRepositoryProvider = Provider<MusicRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return MusicRepository(dio);
});

class MusicRepository {
  final Dio _dio;

  MusicRepository(this._dio);

  /// Fetch detailed song info, including related songs and direct audio URL
  Future<Music> getMusicDetails(int id) async {
    try {
      debugPrint('MusicRepository: Fetching playback details for $id');
      final response = await _dio.get('music/$id/playback/');

      debugPrint('MusicRepository: Response received: ${response.statusCode}');

      if (response.data['success'] == true) {
        final data = response.data['data'];
        return Music.fromJson(data);
      }
      throw Exception(response.data['message'] ?? 'Failed to load music details');
    } catch (e) {
      debugPrint('MusicRepository: Error fetching details: $e');
      rethrow;
    }
  }

  /// Get related songs (combining album, artist, and tags related songs)
  Future<List<Music>> getRelatedSongs(int id) async {
    try {
      final response = await _dio.post('music/$id/stream/');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        final List albumRelated = data['related_by_album'] ?? [];
        final List artistRelated = data['related_by_artist'] ?? [];
        final List tagsRelated = data['related_by_tags'] ?? [];

        // Combine all and de-duplicate by ID
        final allRelatedRaw = [...albumRelated, ...artistRelated, ...tagsRelated];
        final uniqueMap = <int, Music>{};

        for (final item in allRelatedRaw) {
          final music = Music.fromJson(item);
          uniqueMap[music.id] = music;
        }

        return uniqueMap.values.toList();
      }
      return [];
    } catch (e) {
      debugPrint('MusicRepository: Error fetching related songs: $e');
      return [];
    }
  }


  /// Search for music by query
  Future<List<Music>> searchMusic(String query) async {
    try {
      if (query.isEmpty) return [];
      
      debugPrint('MusicRepository: Searching for "$query"');
      final response = await _dio.get('music/search/', queryParameters: {'q': query});
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List data = response.data['data'] ?? [];
        return data.map((e) => Music.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('MusicRepository: Error searching music: $e');
      return [];
    }
  }

  /// Toggle music as favorite. Returns the new favorite status.
  Future<bool> toggleFavorite(int id) async {
    try {
      final response = await _dio.post('music/$id/favorite/');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        debugPrint('MusicRepository: Toggle favorite response: $data');
        return data['is_favorite'] ?? false;
      }
      throw Exception(response.data['message'] ?? 'Failed to toggle favorite');
    } catch (e) {
      debugPrint('MusicRepository: Error toggling favorite: $e');
      rethrow;
    }
  }

}
