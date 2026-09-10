import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rhythm_flutter/core/config/app_config.dart';
import 'package:rhythm_flutter/core/network/dio_client.dart';
import 'package:rhythm_flutter/core/services/storage_service.dart';
import 'package:rhythm_flutter/features/album/data/models/album_detail.dart';
import 'package:rhythm_flutter/features/artist/data/models/artist_detail.dart';
import 'package:rhythm_flutter/features/home/data/models/home_feed.dart';
import 'package:rhythm_flutter/features/home/data/models/music.dart';
import 'package:rhythm_flutter/features/playlist/data/models/playlist_detail.dart';
import 'package:rhythm_flutter/features/playlist/data/models/user_playlist.dart';
import 'package:rhythm_flutter/features/search/data/models/search_result.dart';

final musicRepositoryProvider = Provider<MusicRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch(storageServiceProvider);
  return MusicRepository(dio, storage);
});

class MusicRepository {
  final Dio _dio;
  final StorageService _storage;

  static const String defaultFallbackUserId = 'dZnjYn0Ku1X9vleSQYmyczZvcLL2';

  MusicRepository(this._dio, this._storage);

  String _getEffectiveUserId(String? userId) {
    if (userId != null && userId.isNotEmpty) return userId;
    final stored = _storage.getString('user_id') ??
        _storage.getString('firebase_user_id');
    if (stored != null && stored.isNotEmpty) return stored;
    return defaultFallbackUserId;
  }

  // ── Unified Details API (/api/v1/details) ──

  /// Single unified API endpoint to fetch detailed metadata by type:
  /// type: 'song', 'playlist', 'artist', 'album'
  Future<Map<String, dynamic>?> getUnifiedDetails({
    required String type,
    required String id,
    String? userId,
    int limit = 10,
    int songCount = 10,
    int albumCount = 10,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'type': type,
        'id': id,
        'user_id': _getEffectiveUserId(userId),
        'limit': limit,
        'song_count': songCount,
        'album_count': albumCount,
      };

      Response response;
      try {
        final directUrl = '${AppConfig.baseUrl}/api/v1/details';
        response = await _dio.get(directUrl, queryParameters: queryParams);
      } catch (e) {
        response = await _dio.get('details', queryParameters: queryParams);
      }

      if (response.data != null && response.data['success'] == true) {
        return response.data['data'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      debugPrint('MusicRepository: Error fetching unified details: $e');
      return null;
    }
  }

  /// Get Song details with suggested songs list from GET /api/v1/songs/{id}
  Future<Map<String, dynamic>?> getSongDetails(String songId, {int limit = 10}) async {
    try {
      Response response;
      final queryParams = {'limit': limit};
      try {
        final directUrl = '${AppConfig.baseUrl}/api/v1/songs/$songId';
        response = await _dio.get(directUrl, queryParameters: queryParams);
      } catch (e) {
        response = await _dio.get('songs/$songId', queryParameters: queryParams);
      }

      if (response.data != null) {
        return response.data['data'] ?? response.data;
      }
      return null;
    } catch (e) {
      debugPrint('MusicRepository: Error fetching song details for $songId: $e');
      return null;
    }
  }

  /// Get Album details from GET /api/v1/albums/{album_id}
  Future<AlbumDetail?> getAlbumDetails(String albumId) async {
    try {
      Response response;
      try {
        final directUrl = '${AppConfig.baseUrl}/api/v1/albums/$albumId';
        response = await _dio.get(directUrl);
      } catch (e) {
        response = await _dio.get('albums/$albumId');
      }

      if (response.data != null) {
        final dynamic raw = response.data['data'] ?? response.data;
        if (raw is Map<String, dynamic>) {
          return AlbumDetail.fromJson(raw);
        }
      }
      return null;
    } catch (e) {
      debugPrint('MusicRepository: Error fetching album details for $albumId: $e');
      return null;
    }
  }

  /// Get Playlist details from GET /api/v1/playlists/{playlist_id}
  Future<PlaylistDetail?> getPlaylistDetails(String playlistId) async {
    try {
      Response response;
      try {
        final directUrl = '${AppConfig.baseUrl}/api/v1/playlists/$playlistId';
        response = await _dio.get(directUrl);
      } catch (e) {
        response = await _dio.get('playlists/$playlistId');
      }

      if (response.data != null) {
        final dynamic raw = response.data['data'] ?? response.data;
        if (raw is Map<String, dynamic>) {
          return PlaylistDetail.fromJson(raw);
        }
      }
      return null;
    } catch (e) {
      debugPrint('MusicRepository: Error fetching playlist details for $playlistId: $e');
      return null;
    }
  }

  /// Get Artist details from GET /api/v1/artists/{artist_id}?song_count=50&album_count=50
  Future<ArtistDetail?> getArtistDetails(
    String artistId, {
    int songCount = 50,
    int albumCount = 50,
  }) async {
    try {
      final queryParams = {
        'song_count': songCount,
        'album_count': albumCount,
      };
      Response response;
      try {
        final directUrl = '${AppConfig.baseUrl}/api/v1/artists/$artistId';
        response = await _dio.get(directUrl, queryParameters: queryParams);
      } catch (e) {
        response = await _dio.get('artists/$artistId', queryParameters: queryParams);
      }

      if (response.data != null) {
        final dynamic raw = response.data['data'] ?? response.data;
        if (raw is Map<String, dynamic>) {
          return ArtistDetail.fromJson(raw);
        }
      }
      return null;
    } catch (e) {
      debugPrint('MusicRepository: Error fetching artist details for $artistId: $e');
      return null;
    }
  }

  // ── Favorites API (/api/v1/favorites) ──

  /// Add song to user's favorites in Firestore via POST /api/v1/favorites
  /// Body: {"user_id": "...", "song_id": "..."}
  Future<bool> addFavorite({required String songId, String? userId}) async {
    final uid = _getEffectiveUserId(userId);
    final payload = {
      'user_id': uid,
      'song_id': songId,
    };

    try {
      final directUrl = '${AppConfig.baseUrl}/api/v1/favorites';
      debugPrint('MusicRepository: Adding favorite POST $directUrl with payload $payload');
      final response = await _dio.post(
        directUrl,
        data: payload,
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      final isSuccess = response.statusCode == 200 || response.statusCode == 201;
      debugPrint('MusicRepository: Add favorite result: $isSuccess (${response.statusCode})');
      return isSuccess;
    } catch (e) {
      debugPrint('MusicRepository: Error adding favorite: $e');
      return false;
    }
  }

  /// Remove song from favorites via DELETE /api/v1/favorites
  /// Body / query: {"user_id": "...", "song_id": "..."} with path fallback
  Future<bool> removeFavorite({required String songId, String? userId}) async {
    final uid = _getEffectiveUserId(userId);
    final payload = {
      'user_id': uid,
      'song_id': songId,
    };

    try {
      final directUrl = '${AppConfig.baseUrl}/api/v1/favorites';
      debugPrint('MusicRepository: Removing favorite DELETE $directUrl with payload $payload');
      final response = await _dio.delete(
        directUrl,
        data: payload,
        queryParameters: payload,
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      final isSuccess = response.statusCode == 200 || response.statusCode == 204;
      debugPrint('MusicRepository: Remove favorite result: $isSuccess (${response.statusCode})');
      return isSuccess;
    } catch (e) {
      // Fallback to path parameter /api/v1/favorites/{song_id}?user_id=...
      try {
        final pathUrl = '${AppConfig.baseUrl}/api/v1/favorites/$songId';
        debugPrint('MusicRepository: Fallback DELETE to $pathUrl for user $uid');
        final fallbackResponse = await _dio.delete(
          pathUrl,
          queryParameters: {'user_id': uid},
        );
        return fallbackResponse.statusCode == 200 || fallbackResponse.statusCode == 204;
      } catch (e2) {
        debugPrint('MusicRepository: Error removing favorite: $e / $e2');
        return false;
      }
    }
  }

  /// Check if a song is favorited from GET /api/v1/favorites/check
  Future<bool> checkIsFavorite({required String songId, String? userId}) async {
    final uid = _getEffectiveUserId(userId);
    final queryParams = {
      'user_id': uid,
      'song_id': songId,
    };

    try {
      final directUrl = '${AppConfig.baseUrl}/api/v1/favorites/check';
      final response = await _dio.get(
        directUrl,
        queryParameters: queryParams,
      );

      if (response.data != null && response.data['is_favorite'] != null) {
        return response.data['is_favorite'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('MusicRepository: Error checking favorite: $e');
      return false;
    }
  }

  /// Get user's favorites playlist and songs from GET /api/v1/favorites
  Future<List<HomeItem>> getFavoritesList({String? userId, int limit = 50}) async {
    final uid = _getEffectiveUserId(userId);
    final queryParams = {
      'user_id': uid,
      'limit': limit,
    };

    try {
      final directUrl = '${AppConfig.baseUrl}/api/v1/favorites';
      final response = await _dio.get(
        directUrl,
        queryParameters: queryParams,
      );

      if (response.data != null) {
        final dynamic raw = response.data['data'] ?? response.data;
        if (raw is Map<String, dynamic> && raw['songs'] is List) {
          return (raw['songs'] as List)
              .map((e) => HomeItem.fromJson(e as Map<String, dynamic>))
              .toList();
        } else if (raw is List) {
          return raw
              .map((e) => HomeItem.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('MusicRepository: Error fetching favorites list: $e');
      return [];
    }
  }

  // ── Recent Plays API (/api/v1/recent-plays) ──

  /// Record a recently played song to Firebase Firestore via POST /api/v1/recent-plays
  Future<bool> recordRecentPlay({required String songId, String? userId}) async {
    final uid = _getEffectiveUserId(userId);
    final payload = {
      'user_id': uid,
      'song_id': songId,
    };

    try {
      Response response;
      try {
        final directUrl = '${AppConfig.baseUrl}/api/v1/recent-plays';
        response = await _dio.post(directUrl, data: payload);
      } catch (e) {
        response = await _dio.post('recent-plays', data: payload);
      }

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('MusicRepository: Error recording recent play: $e');
      return false;
    }
  }

  /// Get user's recently played songs from GET /api/v1/recent-plays
  Future<List<HomeItem>> getRecentPlays({String? userId, int limit = 20}) async {
    final uid = _getEffectiveUserId(userId);
    final queryParams = {
      'user_id': uid,
      'limit': limit,
    };

    try {
      Response response;
      try {
        final directUrl = '${AppConfig.baseUrl}/api/v1/recent-plays';
        response = await _dio.get(directUrl, queryParameters: queryParams);
      } catch (e) {
        response = await _dio.get('recent-plays', queryParameters: queryParams);
      }

      if (response.data != null) {
        final dynamic raw = response.data['data'] ?? response.data;
        if (raw is List) {
          return raw
              .map((e) => HomeItem.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('MusicRepository: Error getting recent plays: $e');
      return [];
    }
  }

  // ── User Playlists API (/api/v1/user-playlists & /api/v1/playlists/user) ──

  /// 1. Create a new custom user playlist via POST /api/v1/user-playlists
  /// Payload: {"user_id": "...", "name": "...", "description": "...", "song_ids": [...]}
  Future<UserPlaylist?> createUserPlaylist({
    required String name,
    String? description,
    List<String>? songIds,
    String? userId,
  }) async {
    final uid = _getEffectiveUserId(userId);
    final payload = {
      'user_id': uid,
      'name': name,
      if (description != null && description.isNotEmpty) 'description': description,
      if (songIds != null && songIds.isNotEmpty) 'song_ids': songIds,
    };

    try {
      final directUrl = '${AppConfig.baseUrl}/api/v1/user-playlists';
      debugPrint('MusicRepository: Creating playlist POST $directUrl with $payload');
      final response = await _dio.post(
        directUrl,
        data: payload,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.data != null) {
        final dynamic raw = response.data['data'] ?? response.data;
        if (raw is Map<String, dynamic>) {
          return UserPlaylist.fromJson(raw);
        }
      }
      return null;
    } catch (e) {
      // Try fallback alias /api/v1/playlists/user
      try {
        final fallbackUrl = '${AppConfig.baseUrl}/api/v1/playlists/user';
        final response = await _dio.post(
          fallbackUrl,
          data: payload,
          options: Options(headers: {'Content-Type': 'application/json'}),
        );
        if (response.data != null) {
          final dynamic raw = response.data['data'] ?? response.data;
          if (raw is Map<String, dynamic>) {
            return UserPlaylist.fromJson(raw);
          }
        }
      } catch (e2) {
        debugPrint('MusicRepository: Error creating playlist: $e / $e2');
      }
      return null;
    }
  }

  /// 2. Get all playlists for user from GET /api/v1/user-playlists?user_id=...
  Future<List<UserPlaylist>> getUserPlaylists({String? userId}) async {
    final uid = _getEffectiveUserId(userId);
    final queryParams = {'user_id': uid};

    try {
      final directUrl = '${AppConfig.baseUrl}/api/v1/user-playlists';
      debugPrint('MusicRepository: Getting user playlists GET $directUrl with $queryParams');
      final response = await _dio.get(directUrl, queryParameters: queryParams);

      if (response.data != null) {
        final dynamic raw = response.data['data'] ?? response.data;
        if (raw is List) {
          return raw
              .whereType<Map<String, dynamic>>()
              .map((item) => UserPlaylist.fromJson(item))
              .toList();
        }
      }
      return [];
    } catch (e) {
      // Try fallback alias /api/v1/playlists/user
      try {
        final fallbackUrl = '${AppConfig.baseUrl}/api/v1/playlists/user';
        final response = await _dio.get(fallbackUrl, queryParameters: queryParams);
        if (response.data != null) {
          final dynamic raw = response.data['data'] ?? response.data;
          if (raw is List) {
            return raw
                .whereType<Map<String, dynamic>>()
                .map((item) => UserPlaylist.fromJson(item))
                .toList();
          }
        }
      } catch (e2) {
        debugPrint('MusicRepository: Error getting user playlists: $e / $e2');
      }
      return [];
    }
  }

  /// 3. Get specific playlist details and tracklist from GET /api/v1/user-playlists/{playlist_id}?user_id=...&limit=...
  Future<UserPlaylist?> getUserPlaylistDetails({
    required String playlistId,
    String? userId,
    int limit = 50,
  }) async {
    final uid = _getEffectiveUserId(userId);
    final queryParams = {
      'user_id': uid,
      'limit': limit,
    };

    try {
      final directUrl = '${AppConfig.baseUrl}/api/v1/user-playlists/$playlistId';
      debugPrint('MusicRepository: Getting user playlist details GET $directUrl with $queryParams');
      final response = await _dio.get(directUrl, queryParameters: queryParams);

      if (response.data != null) {
        final dynamic raw = response.data['data'] ?? response.data;
        if (raw is Map<String, dynamic>) {
          return UserPlaylist.fromJson(raw);
        }
      }
      return null;
    } catch (e) {
      // Try fallback alias /api/v1/playlists/user/{playlist_id}
      try {
        final fallbackUrl = '${AppConfig.baseUrl}/api/v1/playlists/user/$playlistId';
        final response = await _dio.get(fallbackUrl, queryParameters: queryParams);
        if (response.data != null) {
          final dynamic raw = response.data['data'] ?? response.data;
          if (raw is Map<String, dynamic>) {
            return UserPlaylist.fromJson(raw);
          }
        }
      } catch (e2) {
        debugPrint('MusicRepository: Error getting user playlist details for $playlistId: $e / $e2');
      }
      return null;
    }
  }

  /// 4. Delete a custom user playlist via DELETE /api/v1/user-playlists/{playlist_id}?user_id=...
  Future<bool> deleteUserPlaylist({
    required String playlistId,
    String? userId,
  }) async {
    final uid = _getEffectiveUserId(userId);
    final queryParams = {'user_id': uid};

    try {
      final directUrl = '${AppConfig.baseUrl}/api/v1/user-playlists/$playlistId';
      debugPrint('MusicRepository: Deleting playlist DELETE $directUrl for user $uid');
      final response = await _dio.delete(directUrl, queryParameters: queryParams);
      final isSuccess = response.statusCode == 200 || response.statusCode == 204;
      return isSuccess;
    } catch (e) {
      // Try fallback alias /api/v1/playlists/user/{playlist_id}
      try {
        final fallbackUrl = '${AppConfig.baseUrl}/api/v1/playlists/user/$playlistId';
        final response = await _dio.delete(fallbackUrl, queryParameters: queryParams);
        return response.statusCode == 200 || response.statusCode == 204;
      } catch (e2) {
        debugPrint('MusicRepository: Error deleting playlist $playlistId: $e / $e2');
        return false;
      }
    }
  }

  /// 5. Add a song to a user playlist via POST /api/v1/user-playlists/{playlist_id}/songs
  /// Body: {"user_id": "...", "song_id": "..."}
  Future<bool> addSongToUserPlaylist({
    required String playlistId,
    required String songId,
    String? userId,
  }) async {
    final uid = _getEffectiveUserId(userId);
    final payload = {
      'user_id': uid,
      'song_id': songId,
    };

    try {
      final directUrl = '${AppConfig.baseUrl}/api/v1/user-playlists/$playlistId/songs';
      debugPrint('MusicRepository: Adding song to playlist POST $directUrl with $payload');
      final response = await _dio.post(
        directUrl,
        data: payload,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      // Try fallback alias /api/v1/playlists/user/{playlist_id}/songs
      try {
        final fallbackUrl = '${AppConfig.baseUrl}/api/v1/playlists/user/$playlistId/songs';
        final response = await _dio.post(
          fallbackUrl,
          data: payload,
          options: Options(headers: {'Content-Type': 'application/json'}),
        );
        return response.statusCode == 200 || response.statusCode == 201;
      } catch (e2) {
        debugPrint('MusicRepository: Error adding song $songId to playlist $playlistId: $e / $e2');
        return false;
      }
    }
  }

  /// 6. Remove a song from a user playlist via DELETE /api/v1/user-playlists/{playlist_id}/songs/{song_id}?user_id=...
  Future<bool> removeSongFromUserPlaylist({
    required String playlistId,
    required String songId,
    String? userId,
  }) async {
    final uid = _getEffectiveUserId(userId);
    final queryParams = {'user_id': uid};

    try {
      final directUrl = '${AppConfig.baseUrl}/api/v1/user-playlists/$playlistId/songs/$songId';
      debugPrint('MusicRepository: Removing song from playlist DELETE $directUrl with $queryParams');
      final response = await _dio.delete(directUrl, queryParameters: queryParams);
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      // Try fallback alias /api/v1/playlists/user/{playlist_id}/songs/{song_id}
      try {
        final fallbackUrl = '${AppConfig.baseUrl}/api/v1/playlists/user/$playlistId/songs/$songId';
        final response = await _dio.delete(fallbackUrl, queryParameters: queryParams);
        return response.statusCode == 200 || response.statusCode == 204;
      } catch (e2) {
        debugPrint('MusicRepository: Error removing song $songId from playlist $playlistId: $e / $e2');
        return false;
      }
    }
  }

  // ── Legacy Compatibility Helpers ──

  /// Compatibility wrapper for toggling favorite by ID (int or String)
  Future<bool> toggleFavorite(dynamic id, {String? userId, bool? shouldFavorite}) async {
    final songId = id is int ? (musicRawIdMap[id] ?? id.toString()) : id.toString();
    
    // If target state is explicitly passed, execute directly
    final bool targetIsFav;
    if (shouldFavorite != null) {
      targetIsFav = shouldFavorite;
    } else {
      final isCurrentlyFav = await checkIsFavorite(songId: songId, userId: userId);
      targetIsFav = !isCurrentlyFav;
    }

    if (targetIsFav) {
      final success = await addFavorite(songId: songId, userId: userId);
      return success ? true : !targetIsFav;
    } else {
      final success = await removeFavorite(songId: songId, userId: userId);
      return success ? false : !targetIsFav;
    }
  }

  /// Helper for getMusicDetails (accepts String or int id)
  Future<Music> getMusicDetails(dynamic id) async {
    try {
      final details = await getSongDetails(id.toString());
      if (details != null) {
        return Music.fromJson(details);
      }
      throw Exception('Failed to load music details');
    } catch (e) {
      debugPrint('MusicRepository: Error fetching details: $e');
      rethrow;
    }
  }

  /// Helper for getRelatedSongs (accepts String or int id)
  Future<List<Music>> getRelatedSongs(dynamic id) async {
    try {
      final details = await getSongDetails(id.toString());
      if (details != null && details['suggested_songs'] is List) {
        return (details['suggested_songs'] as List)
            .map((e) => Music.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('MusicRepository: Error fetching related songs: $e');
      return [];
    }
  }

  /// Search all media types (songs, albums, artists, playlists, top_query) via GET /api/v1/search?query=...&limit=50
  Future<SearchResult> search({required String query, int limit = 50}) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return const SearchResult();

    final queryParams = <String, dynamic>{
      'query': cleanQuery,
      'limit': limit,
    };

    try {
      Response response;
      try {
        final directUrl = '${AppConfig.baseUrl}/api/v1/search';
        debugPrint('MusicRepository: Requesting $directUrl with $queryParams');
        response = await _dio.get(directUrl, queryParameters: queryParams);
      } catch (e) {
        debugPrint('MusicRepository: Direct search failed ($e), trying relative endpoint');
        response = await _dio.get('search', queryParameters: queryParams);
      }

      if (response.data != null && response.data is Map<String, dynamic>) {
        return SearchResult.fromJson(response.data as Map<String, dynamic>);
      }
      return const SearchResult();
    } catch (e) {
      debugPrint('MusicRepository: Error searching music: $e');
      return const SearchResult();
    }
  }

  /// Helper for searching songs and returning Music domain models
  Future<List<Music>> searchMusic(String query) async {
    try {
      final searchResult = await search(query: query);
      return searchResult.songs.map((item) => Music.fromJson(item.toJson())).toList();
    } catch (e) {
      debugPrint('MusicRepository: Error searching music: $e');
      return [];
    }
  }

  /// Search/fetch songs specifically via GET /api/v1/search/songs?query=...&limit=50
  Future<List<HomeItem>> getSongsByQuery({required String query, int limit = 50}) async {
    final cleanQuery = query.trim().isEmpty ? 'top trending' : query.trim();
    final queryParams = <String, dynamic>{
      'query': cleanQuery,
      'limit': limit,
    };

    try {
      Response response;
      try {
        final directUrl = '${AppConfig.baseUrl}/api/v1/search/songs';
        debugPrint('MusicRepository: Requesting $directUrl with $queryParams');
        response = await _dio.get(directUrl, queryParameters: queryParams);
      } catch (e) {
        debugPrint('MusicRepository: Direct search/songs failed ($e), trying relative endpoint');
        response = await _dio.get('search/songs', queryParameters: queryParams);
      }

      if (response.data != null && response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        final dynamic rawSongs = data['songs'] ?? (data['data'] != null ? data['data']['songs'] : null);
        if (rawSongs is List) {
          return rawSongs
              .whereType<Map<String, dynamic>>()
              .map((item) => HomeItem.fromJson(item))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('MusicRepository: Error fetching songs for query "$query": $e');
      return [];
    }
  }

  /// Search/fetch playlists specifically via GET /api/v1/search/playlists?query=...&limit=50
  Future<List<HomeItem>> getPlaylistsByQuery({required String query, int limit = 50}) async {
    final cleanQuery = query.trim().isEmpty ? 'trending' : query.trim();
    final queryParams = <String, dynamic>{
      'query': cleanQuery,
      'limit': limit,
    };

    try {
      Response response;
      try {
        final directUrl = '${AppConfig.baseUrl}/api/v1/search/playlists';
        debugPrint('MusicRepository: Requesting $directUrl with $queryParams');
        response = await _dio.get(directUrl, queryParameters: queryParams);
      } catch (e) {
        debugPrint('MusicRepository: Direct search/playlists failed ($e), trying relative endpoint');
        response = await _dio.get('search/playlists', queryParameters: queryParams);
      }

      if (response.data != null && response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        final dynamic rawPlaylists = data['playlists'] ?? (data['data'] != null ? data['data']['playlists'] : null);
        if (rawPlaylists is List) {
          return rawPlaylists
              .whereType<Map<String, dynamic>>()
              .map((item) => HomeItem.fromJson(item))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('MusicRepository: Error fetching playlists for query "$query": $e');
      return [];
    }
  }
}
